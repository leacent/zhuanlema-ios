const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("../shared/utils");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();
const auth = app.auth();

/** 频率限制：同一用户 N 秒内不能重复发帖 */
const RATE_LIMIT_SECONDS = 30;
const MAX_CONTENT_LENGTH = 500;
const MAX_IMAGES = 9;
const MAX_TAGS = 10;

exports.main = async (event, context) => {
  const { content, images = [], tags = [] } = event;

  // === 参数校验 ===
  if (!content || content.trim() === "") {
    return { success: false, message: "内容不能为空" };
  }
  if (content.trim().length > MAX_CONTENT_LENGTH) {
    return { success: false, message: `内容不能超过 ${MAX_CONTENT_LENGTH} 字` };
  }
  if (!Array.isArray(images) || images.length > MAX_IMAGES) {
    return { success: false, message: `最多上传 ${MAX_IMAGES} 张图片` };
  }
  if (!Array.isArray(tags) || tags.length > MAX_TAGS) {
    return { success: false, message: `最多添加 ${MAX_TAGS} 个标签` };
  }

  try {
    // 获取当前用户 ID（优先 auth，fallback JWT 解析）
    const userId = resolveUserId(auth, event);

    if (!userId) {
      return { success: false, message: "用户未登录" };
    }

    // === 频率限制：检查用户最近是否刚发过帖子 ===
    const cutoff = Date.now() - RATE_LIMIT_SECONDS * 1000;
    const recentRes = await db.collection("user_posts")
      .where({ userId, createdAt: db.command.gt(cutoff) })
      .limit(1)
      .get();
    if (recentRes.data && recentRes.data.length > 0) {
      return { success: false, message: `发帖太频繁，请 ${RATE_LIMIT_SECONDS} 秒后再试` };
    }

    // 获取用户昵称（从 users 集合查询）
    let nickname = "用户";
    try {
      const userRes = await db.collection("users")
        .where({ _id: userId })
        .get();
      
      if (userRes.data && userRes.data.length > 0) {
        nickname = userRes.data[0].nickname || nickname;
      }
    } catch (e) {
      // 如果查询失败，使用默认昵称
      console.log("获取用户信息失败:", e.message);
    }

    // 插入帖子
    const now = Date.now();
    const res = await db.collection("user_posts").add({
      userId: userId,
      nickname: nickname,
      content: content.trim(),
      images: images,
      tags: tags,
      likeCount: 0,
      commentCount: 0,
      hotScore: 0,
      createdAt: now
    });

    return {
      success: true,
      data: {
        postId: res.id
      }
    };
  } catch (e) {
    return {
      success: false,
      message: "发布失败: " + e.message
    };
  }
};

const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();
const auth = app.auth();

exports.main = async (event, context) => {
  const { content, images = [], tags = [] } = event;

  if (!content || content.trim() === "") {
    return {
      success: false,
      message: "内容不能为空"
    };
  }

  try {
    // 获取当前用户信息
    const { uid, customUserId } = auth.getUserInfo();
    const userId = customUserId || uid;

    if (!userId) {
      return {
        success: false,
        message: "用户未登录"
      };
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
    const res = await db.collection("user_posts").add({
      userId: userId,
      nickname: nickname,
      content: content.trim(),
      images: images,
      tags: tags,
      likeCount: 0,
      createdAt: Date.now()
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

/**
 * 撤回/删除评论（需登录，仅本人可操作）
 * - 软删除：isDeleted=true, deletedAt=now, content=""
 * - 清理 comment_likes 记录
 * - 回写 user_posts.commentCount -1（不低于 0），更新 hotScore
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId, calcHotScore } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const commentId = event?.commentId ?? event?.body?.commentId;
  if (!commentId || typeof commentId !== "string") {
    return { success: false, message: "缺少 commentId" };
  }

  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  try {
    const commentRef = db.collection("post_comments").doc(commentId);
    const commentRes = await commentRef.get();
    const raw = Array.isArray(commentRes.data) && commentRes.data.length > 0 ? commentRes.data[0] : commentRes.data;
    if (!raw || typeof raw !== "object") {
      return { success: false, message: "评论不存在" };
    }

    if (raw.userId !== userId) {
      return { success: false, message: "无权限撤回该评论" };
    }

    if (raw.isDeleted === true) {
      return { success: true, data: { commentId, commentCount: null } };
    }

    const postId = raw.postId;

    // 软删除评论
    const now = Date.now();
    await commentRef.update({ isDeleted: true, deletedAt: now, content: "" });

    // 清理评论点赞记录
    try {
      await db.collection("comment_likes").where({ commentId }).remove();
    } catch (_) {}

    // 回写帖子评论数（原子递减）
    let newCount = null;
    if (postId) {
      try {
        const _ = db.command;
        const postRef = db.collection("user_posts").doc(postId);
        await postRef.update({ commentCount: _.max(_.inc(-1), 0) });

        // 读取更新后的真实值并更新 hotScore
        const postRes = await postRef.get();
        const pRaw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
        newCount = (pRaw && typeof pRaw.commentCount === "number") ? pRaw.commentCount : 0;
        if (newCount < 0) {
          newCount = 0;
          await postRef.update({ commentCount: 0 });
        }
        const likeCount = (pRaw && typeof pRaw.likeCount === "number") ? pRaw.likeCount : 0;
        const createdAt = (pRaw && typeof pRaw.createdAt === "number") ? pRaw.createdAt : Date.now();
        await postRef.update({ hotScore: calcHotScore(likeCount, newCount, createdAt) });
      } catch (_) {}
    }

    return { success: true, data: { commentId, commentCount: newCount } };
  } catch (e) {
    return { success: false, message: "撤回失败: " + e.message };
  }
};

/**
 * 点赞评论（需登录）
 * 写入 comment_likes，并增加 post_comments.likeCount
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("./shared-utils");

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
    const postId = raw?.postId;
    if (!postId) return { success: false, message: "评论不存在" };

    const likesCol = db.collection("comment_likes");
    const existing = await likesCol.where({ commentId, userId }).get();
    if (existing.data && existing.data.length > 0) {
      const currentCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
      return { success: true, data: { commentId, likeCount: currentCount, isLiked: true } };
    }

    await likesCol.add({ commentId, postId, userId, createdAt: Date.now() });

    const _ = db.command;
    await commentRef.update({ likeCount: _.inc(1) });

    // 读取更新后的真实值
    const updated = await commentRef.get();
    const updatedRaw = Array.isArray(updated.data) && updated.data.length > 0 ? updated.data[0] : updated.data;
    const newCount = (updatedRaw && typeof updatedRaw.likeCount === "number") ? updatedRaw.likeCount : 1;

    return { success: true, data: { commentId, likeCount: newCount, isLiked: true } };
  } catch (e) {
    return { success: false, message: "点赞评论失败: " + e.message };
  }
};

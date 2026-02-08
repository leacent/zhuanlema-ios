/**
 * 点赞帖子（需登录）
 * 写入 post_likes，并增加 user_posts.likeCount，更新 hotScore
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId, calcHotScore } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const postId = event?.postId ?? event?.body?.postId;
  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
  }

  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  try {
    const likesCol = db.collection("post_likes");
    const existing = await likesCol.where({ postId, userId }).get();
    if (existing.data && existing.data.length > 0) {
      const postRes = await db.collection("user_posts").doc(postId).get();
      const currentCount = (postRes.data && (Array.isArray(postRes.data) ? postRes.data[0] : postRes.data))?.likeCount ?? 0;
      return { success: true, data: { likeCount: currentCount, isLiked: true } };
    }

    await likesCol.add({ postId, userId, createdAt: Date.now() });

    const _ = db.command;
    const postRef = db.collection("user_posts").doc(postId);
    await postRef.update({ likeCount: _.inc(1) });

    // 读取更新后的真实值并更新 hotScore
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    const newCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 1;
    const commentCount = (raw && typeof raw.commentCount === "number") ? raw.commentCount : 0;
    const createdAt = (raw && typeof raw.createdAt === "number") ? raw.createdAt : Date.now();
    await postRef.update({ hotScore: calcHotScore(newCount, commentCount, createdAt) });

    return { success: true, data: { likeCount: newCount, isLiked: true } };
  } catch (e) {
    return { success: false, message: "点赞失败: " + e.message };
  }
};

/**
 * 取消点赞（需登录）
 * 删除 post_likes 记录并减少 user_posts.likeCount，更新 hotScore
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
    const list = Array.isArray(existing.data) ? existing.data : (existing.data ? [existing.data] : []);

    const _ = db.command;
    const postRef = db.collection("user_posts").doc(postId);

    if (list.length > 0) {
      // 批量删除点赞记录
      for (const doc of list) {
        if (doc._id) await likesCol.doc(doc._id).remove();
      }
      // 原子递减，使用 max(0) 防止负数
      await postRef.update({ likeCount: _.max(_.inc(-1), 0) });
    }

    // 读取更新后的真实值
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    let newCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
    // 兜底：万一 max 不支持，手动纠正负数
    if (newCount < 0) {
      newCount = 0;
      await postRef.update({ likeCount: 0 });
    }

    // 更新 hotScore
    const commentCount = (raw && typeof raw.commentCount === "number") ? raw.commentCount : 0;
    const createdAt = (raw && typeof raw.createdAt === "number") ? raw.createdAt : Date.now();
    await postRef.update({ hotScore: calcHotScore(newCount, commentCount, createdAt) });

    return { success: true, data: { likeCount: newCount, isLiked: false } };
  } catch (e) {
    return { success: false, message: "取消点赞失败: " + e.message };
  }
};

/**
 * 点赞评论（需登录）
 * 写入 comment_likes，并增加 post_comments.likeCount
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

function getUserIdFromEvent(event) {
  const token =
    event?.access_token ??
    event?.body?.access_token ??
    (typeof event?.body === "string" ? (() => { try { return JSON.parse(event.body).access_token; } catch (_) { return null; } })() : null);
  if (!token || typeof token !== "string") return null;
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    if (b64.length % 4) b64 += "=".repeat(4 - (b64.length % 4));
    const payload = JSON.parse(Buffer.from(b64, "base64").toString());
    return payload.sub || null;
  } catch (_) {
    return null;
  }
}

exports.main = async (event) => {
  const commentId = event?.commentId ?? event?.body?.commentId;
  if (!commentId || typeof commentId !== "string") {
    return { success: false, message: "缺少 commentId" };
  }

  let userId;
  try {
    const { uid, customUserId } = auth.getUserInfo();
    userId = customUserId || uid;
  } catch (_) {}
  if (!userId) userId = getUserIdFromEvent(event);
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

    const currentCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
    const newCount = currentCount + 1;
    await commentRef.update({ likeCount: newCount });

    return { success: true, data: { commentId, likeCount: newCount, isLiked: true } };
  } catch (e) {
    return { success: false, message: "点赞评论失败: " + e.message };
  }
};

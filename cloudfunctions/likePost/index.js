/**
 * 点赞帖子（需登录）
 * 写入 post_likes，并增加 user_posts.likeCount
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
  const postId = event?.postId ?? event?.body?.postId;
  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
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
    const likesCol = db.collection("post_likes");
    const existing = await likesCol.where({ postId, userId }).get();
    if (existing.data && existing.data.length > 0) {
      const postRes = await db.collection("user_posts").doc(postId).get();
      const currentCount = (postRes.data && (Array.isArray(postRes.data) ? postRes.data[0] : postRes.data))?.likeCount ?? 0;
      return { success: true, data: { likeCount: currentCount, isLiked: true } };
    }

    await likesCol.add({ postId, userId, createdAt: Date.now() });

    const postRef = db.collection("user_posts").doc(postId);
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    const currentCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
    await postRef.update({ likeCount: currentCount + 1 });

    return { success: true, data: { likeCount: currentCount + 1, isLiked: true } };
  } catch (e) {
    return { success: false, message: "点赞失败: " + e.message };
  }
};

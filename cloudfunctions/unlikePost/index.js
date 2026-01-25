/**
 * 取消点赞（需登录）
 * 删除 post_likes 记录并减少 user_posts.likeCount
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
    const list = Array.isArray(existing.data) ? existing.data : (existing.data ? [existing.data] : []);

    const postRef = db.collection("user_posts").doc(postId);
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    let newCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;

    if (list.length > 0) {
      for (const doc of list) {
        if (doc._id) await likesCol.doc(doc._id).remove();
      }
      newCount = Math.max(0, newCount - 1);
      await postRef.update({ likeCount: newCount });
    }

    return { success: true, data: { likeCount: newCount, isLiked: false } };
  } catch (e) {
    return { success: false, message: "取消点赞失败: " + e.message };
  }
};

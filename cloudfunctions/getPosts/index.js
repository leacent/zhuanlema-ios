/**
 * 获取帖子列表（按时间倒序）
 * 若传入 access_token，则同时返回当前用户已点赞的 postId 列表，用于客户端展示 isLiked
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
  const limit = event?.limit ?? event?.body?.limit ?? 20;
  const offset = event?.offset ?? event?.body?.offset ?? 0;

  let userId = null;
  try {
    const { uid, customUserId } = auth.getUserInfo();
    userId = customUserId || uid;
  } catch (_) {}
  if (!userId) userId = getUserIdFromEvent(event);

  try {
    const res = await db.collection("user_posts")
      .orderBy("createdAt", "desc")
      .skip(offset)
      .limit(limit)
      .get();

    let likedPostIds = [];
    if (userId) {
      const likeRes = await db.collection("post_likes").where({ userId }).get();
      const list = Array.isArray(likeRes.data) ? likeRes.data : (likeRes.data ? [likeRes.data] : []);
      likedPostIds = list.map((d) => d.postId).filter(Boolean);
    }

    const data = { posts: res.data || [] };
    if (likedPostIds.length > 0) data.likedPostIds = likedPostIds;

    return { success: true, data };
  } catch (e) {
    return { success: false, message: "获取帖子失败: " + e.message };
  }
};

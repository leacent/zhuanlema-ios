/**
 * 取消点赞评论（需登录）
 * 删除 comment_likes，并减少 post_comments.likeCount
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
    const likesCol = db.collection("comment_likes");
    const existing = await likesCol.where({ commentId, userId }).get();
    const list = Array.isArray(existing.data) ? existing.data : (existing.data ? [existing.data] : []);

    const commentRef = db.collection("post_comments").doc(commentId);
    const commentRes = await commentRef.get();
    const raw = Array.isArray(commentRes.data) && commentRes.data.length > 0 ? commentRes.data[0] : commentRes.data;
    const currentCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;

    let newCount = currentCount;
    if (list.length > 0) {
      for (const doc of list) {
        if (doc._id) await likesCol.doc(doc._id).remove();
      }
      newCount = Math.max(0, currentCount - 1);
      await commentRef.update({ likeCount: newCount });
    }

    return { success: true, data: { commentId, likeCount: newCount, isLiked: false } };
  } catch (e) {
    return { success: false, message: "取消点赞评论失败: " + e.message };
  }
};

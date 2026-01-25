/**
 * 获取帖子下的评论列表（按时间正序）
 * - 支持回复：评论带 parentId / replyToNickname / replyToCommentId
 * - 若传入 access_token：返回 likedCommentIds，用于客户端展示评论点赞状态
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
  const limit = Math.min(Math.max(+(event?.limit ?? event?.body?.limit ?? 20), 1), 100);
  const offset = Math.max(+(event?.offset ?? event?.body?.offset ?? 0), 0);

  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
  }

  let userId = null;
  try {
    const { uid, customUserId } = auth.getUserInfo();
    userId = customUserId || uid;
  } catch (_) {}
  if (!userId) userId = getUserIdFromEvent(event);

  try {
    const res = await db.collection("post_comments")
      .where({ postId })
      .orderBy("createdAt", "asc")
      .skip(offset)
      .limit(limit)
      .get();

    let likedCommentIds = [];
    if (userId) {
      // comment_likes 记录包含 postId，便于按帖拉取用户已点赞的评论
      const likeRes = await db.collection("comment_likes").where({ userId, postId }).get();
      const list = Array.isArray(likeRes.data) ? likeRes.data : (likeRes.data ? [likeRes.data] : []);
      likedCommentIds = list.map((d) => d.commentId).filter(Boolean);
    }

    const data = { comments: res.data || [] };
    if (likedCommentIds.length > 0) data.likedCommentIds = likedCommentIds;
    return { success: true, data };
  } catch (e) {
    const msg = e.message || String(e);
    // 集合尚未创建时（如首次部署）返回空列表，避免详情页报错
    if (msg.includes("not exist") || msg.includes("ResourceNotFound") || msg.includes("post_comments")) {
      return { success: true, data: { comments: [] } };
    }
    return { success: false, message: "获取评论失败: " + msg };
  }
};

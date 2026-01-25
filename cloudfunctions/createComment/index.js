/**
 * 发表评论（需登录）
 * 写入 post_comments 并增加 user_posts.commentCount
 * 支持回复：传 parentId（父评论ID），云函数会写入 replyToNickname / replyToCommentId
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
  const content = (event?.content ?? event?.body?.content ?? "").trim();
  const parentId = event?.parentId ?? event?.body?.parentId;

  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
  }
  if (!content) {
    return { success: false, message: "评论内容不能为空" };
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

  let nickname = "用户";
  try {
    const userRes = await db.collection("users").doc(userId).get();
    const raw = Array.isArray(userRes.data) && userRes.data.length > 0 ? userRes.data[0] : userRes.data;
    if (raw && raw.nickname) nickname = raw.nickname;
  } catch (_) {}

  try {
    const commentDoc = {
      postId,
      userId,
      content,
      nickname,
      createdAt: Date.now(),
      likeCount: 0,
    };

    // 回复：写入 parentId + replyTo 信息（从父评论读取）
    if (typeof parentId === "string" && parentId.trim() !== "") {
      try {
        const parentRes = await db.collection("post_comments").doc(parentId).get();
        const parentRaw = Array.isArray(parentRes.data) && parentRes.data.length > 0 ? parentRes.data[0] : parentRes.data;
        if (parentRaw && typeof parentRaw === "object") {
          commentDoc.parentId = parentId;
          commentDoc.replyToCommentId = parentId;
          if (typeof parentRaw.nickname === "string" && parentRaw.nickname.trim() !== "") {
            commentDoc.replyToNickname = parentRaw.nickname.trim();
          }
        }
      } catch (_) {}
    }

    await db.collection("post_comments").add(commentDoc);

    const postRef = db.collection("user_posts").doc(postId);
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    const current = (raw && typeof raw.commentCount === "number") ? raw.commentCount : 0;
    await postRef.update({ commentCount: current + 1 });

    return { success: true, data: { commentCount: current + 1 } };
  } catch (e) {
    return { success: false, message: "发表评论失败: " + e.message };
  }
};

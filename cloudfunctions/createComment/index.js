/**
 * 发表评论（需登录）
 * 写入 post_comments 并增加 user_posts.commentCount，更新 hotScore
 * 支持回复：传 parentId（父评论ID），云函数会写入 replyToNickname / replyToCommentId
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId, calcHotScore } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

/** 频率限制：同一用户 N 秒内不能重复评论 */
const RATE_LIMIT_SECONDS = 5;
const MAX_COMMENT_LENGTH = 500;

exports.main = async (event) => {
  const postId = event?.postId ?? event?.body?.postId;
  const content = (event?.content ?? event?.body?.content ?? "").trim();
  const parentId = event?.parentId ?? event?.body?.parentId;

  // === 参数校验 ===
  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
  }
  if (!content) {
    return { success: false, message: "评论内容不能为空" };
  }
  if (content.length > MAX_COMMENT_LENGTH) {
    return { success: false, message: `评论不能超过 ${MAX_COMMENT_LENGTH} 字` };
  }

  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  // === 频率限制 ===
  const cutoff = Date.now() - RATE_LIMIT_SECONDS * 1000;
  try {
    const recentRes = await db.collection("post_comments")
      .where({ userId, createdAt: db.command.gt(cutoff) })
      .limit(1)
      .get();
    if (recentRes.data && recentRes.data.length > 0) {
      return { success: false, message: `评论太频繁，请 ${RATE_LIMIT_SECONDS} 秒后再试` };
    }
  } catch (_) {}

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

    // 回复：两层扁平化 —— parentId 始终指向一级（根）评论
    // 如果被回复的评论本身也是回复（有 parentId），向上归根
    if (typeof parentId === "string" && parentId.trim() !== "") {
      try {
        const parentRes = await db.collection("post_comments").doc(parentId).get();
        const parentRaw = Array.isArray(parentRes.data) && parentRes.data.length > 0 ? parentRes.data[0] : parentRes.data;
        if (parentRaw && typeof parentRaw === "object") {
          // 归根：若 parent 本身有 parentId，说明它是回复，取其 parentId 作为根
          const rootId = (typeof parentRaw.parentId === "string" && parentRaw.parentId.trim() !== "")
            ? parentRaw.parentId
            : parentId;
          commentDoc.parentId = rootId;
          commentDoc.replyToCommentId = parentId;
          if (typeof parentRaw.nickname === "string" && parentRaw.nickname.trim() !== "") {
            commentDoc.replyToNickname = parentRaw.nickname.trim();
          }
        }
      } catch (_) {}
    }

    await db.collection("post_comments").add(commentDoc);

    const _ = db.command;
    const postRef = db.collection("user_posts").doc(postId);
    await postRef.update({ commentCount: _.inc(1) });

    // 读取更新后的真实值并更新 hotScore
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    const newCount = (raw && typeof raw.commentCount === "number") ? raw.commentCount : 1;
    const likeCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
    const createdAt = (raw && typeof raw.createdAt === "number") ? raw.createdAt : Date.now();
    await postRef.update({ hotScore: calcHotScore(likeCount, newCount, createdAt) });

    return { success: true, data: { commentCount: newCount } };
  } catch (e) {
    return { success: false, message: "发表评论失败: " + e.message };
  }
};

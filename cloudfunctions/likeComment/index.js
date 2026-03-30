/**
 * 点赞评论（需登录）
 * 写入 comment_likes，并增加 post_comments.likeCount
 */
const { db, _, resolveUserId, parseEvent, ok, fail, calcHotScore } = require('./cloudbase-common');

exports.main = async (event) => {
  const params = parseEvent(event);
  const commentId = params.commentId;
  if (!commentId || typeof commentId !== "string") {
    return fail("缺少 commentId");
  }

  const userId = resolveUserId(event);
  if (!userId) {
    return fail("未登录");
  }

  try {
    const commentRef = db.collection("post_comments").doc(commentId);
    const commentRes = await commentRef.get();
    const raw = Array.isArray(commentRes.data) && commentRes.data.length > 0 ? commentRes.data[0] : commentRes.data;
    const postId = raw?.postId;
    if (!postId) return fail("评论不存在");

    const likesCol = db.collection("comment_likes");
    const existing = await likesCol.where({ commentId, userId }).get();
    if (existing.data && existing.data.length > 0) {
      const currentCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
      return ok({ commentId, likeCount: currentCount, isLiked: true });
    }

    await likesCol.add({ commentId, postId, userId, createdAt: Date.now() });

    await commentRef.update({ likeCount: _.inc(1) });

    // 读取更新后的真实值
    const updated = await commentRef.get();
    const updatedRaw = Array.isArray(updated.data) && updated.data.length > 0 ? updated.data[0] : updated.data;
    const newCount = (updatedRaw && typeof updatedRaw.likeCount === "number") ? updatedRaw.likeCount : 1;

    return ok({ commentId, likeCount: newCount, isLiked: true });
  } catch (e) {
    return fail("点赞评论失败: " + e.message);
  }
};

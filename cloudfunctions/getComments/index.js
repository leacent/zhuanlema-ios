/**
 * 获取帖子下的评论列表
 * - sortBy: "latest"（默认，按时间正序）或 "hot"（按点赞数倒序）
 * - 支持回复：评论带 parentId / replyToNickname / replyToCommentId
 * - 若传入 access_token：返回 likedCommentIds，用于客户端展示评论点赞状态
 */
const { db, _, resolveUserId, parseEvent, ok, fail } = require('./cloudbase-common');

exports.main = async (event) => {
  const params = parseEvent(event);
  const postId = params.postId;
  const limit = Math.min(Math.max(+(params.limit ?? 20), 1), 100);
  const offset = Math.max(+(params.offset ?? 0), 0);
  const sortBy = params.sortBy ?? "latest";

  if (!postId || typeof postId !== "string") {
    return fail("缺少 postId");
  }

  const userId = resolveUserId(event);

  try {
    let query = db.collection("post_comments")
      .where({ postId, isDeleted: _.neq(true) });

    if (sortBy === "hot") {
      // 热度排序：按点赞数倒序，再按时间倒序
      query = query.orderBy("likeCount", "desc").orderBy("createdAt", "desc");
    } else {
      // 默认按时间正序
      query = query.orderBy("createdAt", "asc");
    }

    const res = await query.skip(offset).limit(limit).get();

    let likedCommentIds = [];
    if (userId) {
      // comment_likes 记录包含 postId，便于按帖拉取用户已点赞的评论
      const likeRes = await db.collection("comment_likes").where({ userId, postId }).get();
      const list = Array.isArray(likeRes.data) ? likeRes.data : (likeRes.data ? [likeRes.data] : []);
      likedCommentIds = list.map((d) => d.commentId).filter(Boolean);
    }

    const data = { comments: res.data || [] };
    if (likedCommentIds.length > 0) data.likedCommentIds = likedCommentIds;
    return ok(data);
  } catch (e) {
    const msg = e.message || String(e);
    // 集合尚未创建时（如首次部署）返回空列表，避免详情页报错
    if (msg.includes("not exist") || msg.includes("ResourceNotFound") || msg.includes("post_comments")) {
      return ok({ comments: [] });
    }
    return fail("获取评论失败: " + msg);
  }
};

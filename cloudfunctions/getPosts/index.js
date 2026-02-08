/**
 * 获取帖子列表
 * - sortBy: "latest"（默认，按时间倒序）或 "hot"（按热度倒序：likeCount + commentCount）
 * - 若传入 access_token，则同时返回当前用户已点赞的 postId 列表，用于客户端展示 isLiked
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const limit = Math.min(Math.max(+(event?.limit ?? event?.body?.limit ?? 20), 1), 100);
  const sortBy = event?.sortBy ?? event?.body?.sortBy ?? "latest";
  // 游标分页：传入上一页最后一条记录的排序字段值
  const cursor = event?.cursor ?? event?.body?.cursor ?? null;
  // 兼容旧版 offset 分页
  const offset = Math.max(+(event?.offset ?? event?.body?.offset ?? 0), 0);

  const userId = resolveUserId(auth, event);

  try {
    const _ = db.command;
    let query = db.collection("user_posts");

    if (sortBy === "hot") {
      if (cursor && typeof cursor === "number") {
        // 游标：hotScore < cursor 的记录
        query = query.where({ hotScore: _.lt(cursor) });
      }
      query = query
        .orderBy("hotScore", "desc")
        .orderBy("createdAt", "desc");
    } else {
      if (cursor && typeof cursor === "number") {
        // 游标：createdAt < cursor 的记录
        query = query.where({ createdAt: _.lt(cursor) });
      }
      query = query.orderBy("createdAt", "desc");
    }

    // 如果没有 cursor 但有 offset，退化为 offset 分页（兼容旧客户端）
    const res = (!cursor && offset > 0)
      ? await query.skip(offset).limit(limit).get()
      : await query.limit(limit).get();

    let likedPostIds = [];
    if (userId) {
      const likeRes = await db.collection("post_likes").where({ userId }).get();
      const list = Array.isArray(likeRes.data) ? likeRes.data : (likeRes.data ? [likeRes.data] : []);
      likedPostIds = list.map((d) => d.postId).filter(Boolean);
    }

    const posts = res.data || [];
    const data = { posts };
    if (likedPostIds.length > 0) data.likedPostIds = likedPostIds;

    // 返回 nextCursor 供客户端做游标分页
    if (posts.length > 0) {
      const last = posts[posts.length - 1];
      data.nextCursor = sortBy === "hot"
        ? (typeof last.hotScore === "number" ? last.hotScore : null)
        : (typeof last.createdAt === "number" ? last.createdAt : null);
    }

    return { success: true, data };
  } catch (e) {
    return { success: false, message: "获取帖子失败: " + e.message };
  }
};

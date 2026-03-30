/**
 * 删除帖子（软删除，需登录，仅本人可操作）
 * - 软删除帖子：isDeleted=true, deletedAt=now, content=""
 * - 级联清理：post_comments、post_likes、comment_likes
 */
const { db, resolveUserId, parseEvent, ok, fail } = require("./cloudbase-common");

exports.main = async (event) => {
  const params = parseEvent(event);
  const { postId } = params;
  if (!postId || typeof postId !== "string") {
    return fail("缺少 postId");
  }

  const userId = resolveUserId(event);
  if (!userId) {
    return fail("未登录");
  }

  try {
    const postRef = db.collection("user_posts").doc(postId);
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    if (!raw || typeof raw !== "object") {
      return fail("帖子不存在");
    }

    if (raw.userId !== userId) {
      return fail("无权限删除该帖子");
    }

    if (raw.isDeleted === true) {
      return ok({ postId });
    }

    // 软删除帖子
    await postRef.update({
      isDeleted: true,
      deletedAt: Date.now(),
      content: "",
      images: [],
      tags: [],
    });

    // 级联清理点赞记录
    try {
      await db.collection("post_likes").where({ postId }).remove();
    } catch (_) {}

    // 级联清理评论点赞记录
    try {
      await db.collection("comment_likes").where({ postId }).remove();
    } catch (_) {}

    // 级联软删除评论
    try {
      await db.collection("post_comments").where({ postId }).update({
        isDeleted: true,
        deletedAt: Date.now(),
        content: "",
      });
    } catch (_) {}

    return ok({ postId });
  } catch (e) {
    return fail("删除帖子失败: " + e.message);
  }
};

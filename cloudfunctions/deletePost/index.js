/**
 * 删除帖子（软删除，需登录，仅本人可操作）
 * - 软删除帖子：isDeleted=true, deletedAt=now, content=""
 * - 级联清理：post_comments、post_likes、comment_likes
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const postId = event?.postId ?? event?.body?.postId;
  if (!postId || typeof postId !== "string") {
    return { success: false, message: "缺少 postId" };
  }

  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  try {
    const postRef = db.collection("user_posts").doc(postId);
    const postRes = await postRef.get();
    const raw = Array.isArray(postRes.data) && postRes.data.length > 0 ? postRes.data[0] : postRes.data;
    if (!raw || typeof raw !== "object") {
      return { success: false, message: "帖子不存在" };
    }

    if (raw.userId !== userId) {
      return { success: false, message: "无权限删除该帖子" };
    }

    if (raw.isDeleted === true) {
      return { success: true, data: { postId } };
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

    return { success: true, data: { postId } };
  } catch (e) {
    return { success: false, message: "删除帖子失败: " + e.message };
  }
};

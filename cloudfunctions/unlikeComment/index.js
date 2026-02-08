/**
 * 取消点赞评论（需登录）
 * 删除 comment_likes，并减少 post_comments.likeCount
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();
const auth = app.auth();

exports.main = async (event) => {
  const commentId = event?.commentId ?? event?.body?.commentId;
  if (!commentId || typeof commentId !== "string") {
    return { success: false, message: "缺少 commentId" };
  }

  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  try {
    const likesCol = db.collection("comment_likes");
    const existing = await likesCol.where({ commentId, userId }).get();
    const list = Array.isArray(existing.data) ? existing.data : (existing.data ? [existing.data] : []);

    const _ = db.command;
    const commentRef = db.collection("post_comments").doc(commentId);

    if (list.length > 0) {
      for (const doc of list) {
        if (doc._id) await likesCol.doc(doc._id).remove();
      }
      await commentRef.update({ likeCount: _.max(_.inc(-1), 0) });
    }

    // 读取更新后的真实值
    const commentRes = await commentRef.get();
    const raw = Array.isArray(commentRes.data) && commentRes.data.length > 0 ? commentRes.data[0] : commentRes.data;
    let newCount = (raw && typeof raw.likeCount === "number") ? raw.likeCount : 0;
    if (newCount < 0) {
      newCount = 0;
      await commentRef.update({ likeCount: 0 });
    }

    return { success: true, data: { commentId, likeCount: newCount, isLiked: false } };
  } catch (e) {
    return { success: false, message: "取消点赞评论失败: " + e.message };
  }
};

/**
 * 标记通知为已读
 * 输入: notificationId, userId
 */
const { db, parseEvent, ok, fail } = require("./cloudbase-common");

exports.main = async (event, context) => {
  const { notificationId, userId } = parseEvent(event);

  if (!notificationId || !userId) {
    return fail("缺少 notificationId 或 userId");
  }

  try {
    const col = db.collection("notifications");
    const doc = await col.doc(notificationId).get();
    if (!doc.data || doc.data.userId !== userId) {
      return fail("通知不存在或无权操作");
    }
    await col.doc(notificationId).update({ read: true, updatedAt: Date.now() });
    return ok({ message: "已标记为已读" });
  } catch (e) {
    console.error("markNotificationRead error:", e);
    return fail("操作失败: " + e.message);
  }
};

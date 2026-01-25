/**
 * 标记通知为已读
 * 输入: notificationId, userId
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();

exports.main = async (event, context) => {
  const { notificationId, userId } = event;

  if (!notificationId || !userId) {
    return { success: false, message: "缺少 notificationId 或 userId" };
  }

  try {
    const col = db.collection("notifications");
    const doc = await col.doc(notificationId).get();
    if (!doc.data || doc.data.userId !== userId) {
      return { success: false, message: "通知不存在或无权操作" };
    }
    await col.doc(notificationId).update({ read: true, updatedAt: Date.now() });
    return { success: true, message: "已标记为已读" };
  } catch (e) {
    console.error("markNotificationRead error:", e);
    return { success: false, message: "操作失败: " + e.message };
  }
};

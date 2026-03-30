/**
 * 获取用户消息通知列表
 * 输入: userId, limit?, offset?
 */
const { db, parseEvent, ok, fail } = require("./cloudbase-common");

exports.main = async (event, context) => {
  const { userId, limit = 20, offset = 0 } = parseEvent(event);

  if (!userId) {
    return fail("缺少 userId");
  }

  try {
    const res = await db
      .collection("notifications")
      .where({ userId })
      .orderBy("createdAt", "desc")
      .skip(offset)
      .limit(limit)
      .get();

    const list = (res.data || []).map((doc) => ({
      _id: doc._id,
      userId: doc.userId,
      title: doc.title || "",
      body: doc.body || "",
      read: !!doc.read,
      createdAt: doc.createdAt,
    }));

    return ok({ notifications: list });
  } catch (e) {
    console.error("getNotifications error:", e);
    return fail("获取通知失败: " + e.message);
  }
};

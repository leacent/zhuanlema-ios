/**
 * 获取当前用户某月的打卡记录（用于日历展示）
 * 约定：users 表的 _id = check_ins 表的 _openid，传参 userId 即 users._id，用于按 _openid 查询。
 * 入参: userId, year, month（1-12），可从 body 或 event 顶层读取
 * 返回: { success, data: [ { _id, userId, date, result, createdAt } ] }
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();

function lastDayOfMonth(year, month) {
  return new Date(year, month, 0).getDate();
}

function parseBody(event) {
  if (!event || !event.body) return {};
  if (typeof event.body === "object") return event.body;
  if (typeof event.body === "string") {
    try { return JSON.parse(event.body); } catch (_) { return {}; }
  }
  return {};
}

exports.main = async (event, context) => {
  const body = parseBody(event);
  const userId = body.userId || event.userId;
  let year = body.year ?? event.year;
  let month = body.month ?? event.month;

  if (!userId || year == null || month == null) {
    return { success: false, message: "缺少 userId、year 或 month" };
  }

  year = parseInt(year, 10);
  month = parseInt(month, 10);
  if (month < 1 || month > 12) {
    return { success: false, message: "month 需为 1-12" };
  }

  const startStr = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = lastDayOfMonth(year, month);
  const endStr = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

  try {
    const col = db.collection("check_ins");
    const res = await col.where({ _openid: userId }).get();
    const list = (res.data || []).filter(
      (doc) => doc.date >= startStr && doc.date <= endStr
    );
    list.sort((a, b) => (a.date < b.date ? -1 : 1));

    const data = list.map((doc) => ({
      _id: doc._id,
      userId: doc._openid || userId,
      date: doc.date,
      result: doc.result || "",
      createdAt: doc.createTime ? Math.floor(doc.createTime / 1000) : null,
    }));

    return { success: true, data };
  } catch (e) {
    console.error("getCheckInHistory error:", e);
    return { success: false, message: "获取打卡记录失败: " + e.message };
  }
};

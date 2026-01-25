/**
 * 创建打卡记录并持久化到 check_ins，与 user 绑定（_openid + userId）
 * Body: userId, result ("yes"|"no"), date (yyyy-MM-dd)
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();

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
  const userId = body.userId;
  const result = body.result;
  const date = body.date;

  if (!userId || !result || !date) {
    return { success: false, message: "参数缺失：需要 userId、result、date" };
  }

  try {
    await db.collection("check_ins").add({
      _openid: userId,
      userId: userId,
      result: result,
      date: date,
      createTime: Date.now(),
    });
    return { success: true, message: "打卡成功" };
  } catch (e) {
    return { success: false, message: "数据库写入失败: " + e.message };
  }
};

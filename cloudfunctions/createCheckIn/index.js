/**
 * 创建打卡记录并持久化到 check_ins，与 user 绑定（_openid + userId）
 * Body: userId, result ("yes"|"no"|"neutral"), date (yyyy-MM-dd), magnitude? ("big_win"|"small_win"|"neutral"|"small_loss"|"big_loss")
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const db = app.database();

const VALID_RESULTS = new Set(["yes", "no", "neutral"]);
const VALID_MAGNITUDES = new Set(["big_win", "small_win", "neutral", "small_loss", "big_loss"]);

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
  const magnitude = body.magnitude || null;

  if (!userId || !result || !date) {
    return { success: false, message: "参数缺失：需要 userId、result、date" };
  }

  if (!VALID_RESULTS.has(result)) {
    return { success: false, message: "result 必须是 yes/no/neutral" };
  }

  if (magnitude && !VALID_MAGNITUDES.has(magnitude)) {
    return { success: false, message: "magnitude 必须是 big_win/small_win/neutral/small_loss/big_loss" };
  }

  try {
    const record = {
      _openid: userId,
      userId: userId,
      result: result,
      date: date,
      createTime: Date.now(),
    };
    if (magnitude) {
      record.magnitude = magnitude;
    }
    await db.collection("check_ins").add(record);
    return { success: true, message: "打卡成功" };
  } catch (e) {
    return { success: false, message: "数据库写入失败: " + e.message };
  }
};

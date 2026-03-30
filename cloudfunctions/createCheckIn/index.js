/**
 * 创建打卡记录并持久化到 check_ins，与 user 绑定（_openid + userId）
 * Body: userId, result ("yes"|"no"|"neutral"), date (yyyy-MM-dd), magnitude? ("big_win"|"small_win"|"neutral"|"small_loss"|"big_loss")
 */
const { db, parseEvent, fail } = require('./cloudbase-common');

const VALID_RESULTS = new Set(["yes", "no", "neutral"]);
const VALID_MAGNITUDES = new Set(["big_win", "small_win", "neutral", "small_loss", "big_loss"]);

exports.main = async (event, context) => {
  const params = parseEvent(event);
  const userId = params.userId;
  const result = params.result;
  const date = params.date;
  const magnitude = params.magnitude || null;

  if (!userId || !result || !date) {
    return fail("参数缺失：需要 userId、result、date");
  }

  if (!VALID_RESULTS.has(result)) {
    return fail("result 必须是 yes/no/neutral");
  }

  if (magnitude && !VALID_MAGNITUDES.has(magnitude)) {
    return fail("magnitude 必须是 big_win/small_win/neutral/small_loss/big_loss");
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
    return fail("数据库写入失败: " + e.message);
  }
};

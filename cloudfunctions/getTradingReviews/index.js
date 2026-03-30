/**
 * getTradingReviews — 获取个人复盘日记列表
 *
 * 参数：
 *   { date?: "YYYY-MM-DD" }          → 返回指定日期的单条
 *   { year: number, month: number }   → 返回某月所有记录
 *   {}                                → 返回最近 20 条
 * 需要 access_token 鉴权
 */
const { db, _, parseEvent, resolveUserId, ok, fail } = require('./cloudbase-common');

exports.main = async (event) => {
  try {
    const params = parseEvent(event);
    const userId = resolveUserId(event);
    if (!userId) {
      return fail('未登录');
    }

    const { date, year, month, limit = 20 } = params;

    if (date) {
      const { data } = await db
        .collection('trading_reviews')
        .where({ userId, date })
        .limit(1)
        .get();
      return ok(data[0] || null);
    }

    if (year && month) {
      const prefix = `${year}-${String(month).padStart(2, '0')}`;
      const { data } = await db
        .collection('trading_reviews')
        .where({
          userId,
          date: _.gte(`${prefix}-01`).and(_.lte(`${prefix}-31`)),
        })
        .orderBy('date', 'desc')
        .limit(31)
        .get();
      return ok(data);
    }

    const { data } = await db
      .collection('trading_reviews')
      .where({ userId })
      .orderBy('date', 'desc')
      .limit(Math.min(limit, 50))
      .get();

    return ok(data);
  } catch (error) {
    console.error('[getTradingReviews] 错误:', error);
    return fail(error.message);
  }
};

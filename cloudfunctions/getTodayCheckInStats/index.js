/**
 * getTodayCheckInStats — 获取今日打卡统计
 *
 * 返回: { success, data: { date, totalCount, yesCount, noCount, yesPercentage, noPercentage, message } }
 */
const { db, parseEvent, ok, fail, getBeijingNow } = require('./cloudbase-common');

exports.main = async (event, context) => {
  try {
    const bj = getBeijingNow();
    const todayStr = bj.dateStr;

    const { data } = await db
      .collection('check_ins')
      .where({ date: todayStr })
      .limit(1000)
      .get();

    const totalCount = data.length;
    const yesCount = data.filter((d) => d.result === 'yes').length;
    const noCount = data.filter((d) => d.result === 'no').length;
    const yesPercentage = totalCount > 0 ? Math.round((yesCount / totalCount) * 100) : 0;
    const noPercentage = totalCount > 0 ? Math.round((noCount / totalCount) * 100) : 0;

    return ok({
      date: todayStr,
      totalCount,
      yesCount,
      noCount,
      yesPercentage,
      noPercentage,
      message: totalCount > 0 ? `今日 ${yesPercentage}% 的人赚了` : '今日还没有人打卡',
    });
  } catch (error) {
    console.error('[getTodayCheckInStats] 错误:', error);
    return fail('获取统计数据失败');
  }
};

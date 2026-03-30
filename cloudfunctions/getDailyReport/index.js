/**
 * getDailyReport — 获取每日 AI 复盘报告
 *
 * 参数：{ date?: "YYYY-MM-DD" }
 * - 指定日期 → 返回该日报告
 * - 不指定 → 自动回溯到最近交易日的报告
 * 响应额外包含 isLatestTradingDay 字段，客户端据此判断是否需要展示"非当日"提示
 */
const { db, parseEvent, getBeijingNow } = require('./cloudbase-common');

// ─── A 股交易日历（与 generateDailyReport 保持一致） ───

const HOLIDAY_CALENDAR_MAX_YEAR = 2026;

const MARKET_HOLIDAYS = new Set([
  '2026-01-01', '2026-01-02',
  '2026-02-16', '2026-02-17', '2026-02-18', '2026-02-19', '2026-02-20',
  '2026-04-06',
  '2026-05-01', '2026-05-04', '2026-05-05',
  '2026-06-19',
  '2026-09-25',
  '2026-10-01', '2026-10-02', '2026-10-05', '2026-10-06', '2026-10-07',
]);

function warnIfCalendarOutdated(dateStr) {
  const year = parseInt(dateStr.split('-')[0], 10);
  if (year > HOLIDAY_CALENDAR_MAX_YEAR) {
    console.error(
      `🚨 [CALENDAR_OUTDATED] 交易日历仅覆盖到 ${HOLIDAY_CALENDAR_MAX_YEAR} 年，当前日期 ${dateStr} 已超出范围！` +
      `节假日判断可能不准确，请尽快更新 MARKET_HOLIDAYS。`
    );
  }
}

function isTradingDay(dateStr) {
  const d = new Date(dateStr + 'T12:00:00+08:00');
  const dow = d.getDay();
  if (dow === 0 || dow === 6) return false;
  return !MARKET_HOLIDAYS.has(dateStr);
}

function getLastTradingDay(dateStr) {
  const d = new Date(dateStr + 'T12:00:00+08:00');
  for (let i = 0; i < 20; i++) {
    const ds = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    if (isTradingDay(ds)) return ds;
    d.setDate(d.getDate() - 1);
  }
  return null;
}

function isAfterMarketClose(hour, minute) {
  return hour > 15 || (hour === 15 && minute >= 10);
}

// ─── 主函数 ───

exports.main = async (event) => {
  try {
    const params = parseEvent(event);
    const bj = getBeijingNow();
    warnIfCalendarOutdated(bj.dateStr);

    // 1. 确定目标日期
    let targetDate = params.date || null;
    if (!targetDate) {
      if (isTradingDay(bj.dateStr) && isAfterMarketClose(bj.hour, bj.minute)) {
        targetDate = bj.dateStr;
      } else {
        targetDate = getLastTradingDay(bj.dateStr);
      }
    }

    // 2. 按目标日期查询
    if (targetDate) {
      const reportId = `report_${targetDate.replace(/-/g, '')}`;
      const result = await db.collection('ai_reports').doc(reportId).get().catch(() => ({ data: null }));
      const reportDoc = Array.isArray(result.data) ? result.data[0] : result.data;
      if (reportDoc && typeof reportDoc === 'object' && reportDoc._id) {
        return {
          success: true,
          data: reportDoc,
          isLatestTradingDay: targetDate === bj.dateStr,
          todayDate: bj.dateStr,
        };
      }
    }

    // 3. 目标日期无报告 → 降级到最新一篇（兼容历史数据）
    const { data: latest } = await db
      .collection('ai_reports')
      .where({ type: 'daily' })
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    const latestList = Array.isArray(latest) ? latest : [];
    if (latestList.length > 0) {
      return {
        success: true,
        data: latestList[0],
        isLatestTradingDay: latestList[0].date === bj.dateStr,
        todayDate: bj.dateStr,
      };
    }

    return { success: false, message: '暂无复盘报告' };
  } catch (error) {
    console.error('[getDailyReport] 错误:', error);
    return { success: false, message: error.message };
  }
};

/**
 * getDailyReport — 获取每日 AI 复盘报告
 *
 * 参数：{ date?: "YYYY-MM-DD" }
 * 返回指定日期的报告；若无则返回最近一篇
 */
const tcb = require('@cloudbase/node-sdk');

const app = tcb.init({ env: 'prod-1-3g3ukjzod3d5e3a1' });
const db = app.database();
const _ = db.command;

exports.main = async (event) => {
  try {
    const dateStr = event.date;

    if (dateStr) {
      const reportId = `report_${dateStr.replace(/-/g, '')}`;
      const { data } = await db.collection('ai_reports').doc(reportId).get().catch(() => ({ data: null }));
      if (data) {
        return { success: true, data };
      }
    }

    // 无指定日期或指定日期无报告 → 返回最新一篇
    const { data: latest } = await db
      .collection('ai_reports')
      .where({ type: 'daily' })
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (latest && latest.length > 0) {
      return { success: true, data: latest[0] };
    }

    return { success: false, message: '暂无复盘报告' };
  } catch (error) {
    console.error('[getDailyReport] 错误:', error);
    return { success: false, message: error.message };
  }
};

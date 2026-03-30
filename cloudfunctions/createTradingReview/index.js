/**
 * createTradingReview — 创建或更新个人复盘日记
 *
 * 参数：{ date, actions, drivers, emotions, content, satisfaction, checkInResult?, checkInMagnitude? }
 * 同一用户同一日期只保留一条，重复提交即更新
 * 需要 access_token 鉴权
 */
const { db, parseEvent, resolveUserId, ok, fail } = require('./cloudbase-common');

exports.main = async (event) => {
  try {
    const params = parseEvent(event);
    const userId = resolveUserId(event);
    if (!userId) {
      return fail('未登录');
    }

    const {
      date,
      actions = [],
      drivers = [],
      emotions = [],
      content = '',
      satisfaction = 3,
      checkInResult,
      checkInMagnitude,
    } = params;

    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return fail('日期格式无效，需 YYYY-MM-DD');
    }

    if (!content && actions.length === 0) {
      return fail('请至少选择一个操作或写点内容');
    }

    const now = Date.now();

    const { data: existingList } = await db
      .collection('trading_reviews')
      .where({ userId, date })
      .limit(1)
      .get();

    const existing = existingList && existingList[0];

    const fields = {
      userId,
      date,
      actions,
      drivers,
      emotions,
      content: content.slice(0, 2000),
      satisfaction: Math.min(5, Math.max(1, satisfaction)),
      checkInResult: checkInResult || null,
      checkInMagnitude: checkInMagnitude || null,
      updatedAt: now,
    };

    if (existing) {
      await db.collection('trading_reviews').doc(existing._id).update(fields);
      return ok({ _id: existing._id, ...fields, createdAt: existing.createdAt || now });
    }

    fields._openid = userId;
    fields.createdAt = now;
    const addResult = await db.collection('trading_reviews').add(fields);
    const newId = addResult.id || addResult._id;

    return ok({ _id: newId, ...fields });
  } catch (error) {
    console.error('[createTradingReview] 错误:', error);
    return fail(error.message);
  }
};

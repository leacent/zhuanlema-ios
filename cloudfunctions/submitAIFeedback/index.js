/**
 * submitAIFeedback — AI 对话反馈
 *
 * 参数：{ conversationId, messageTimestamp, feedback }
 * feedback: "positive" | "negative"
 * 写入 ai_feedback 集合，用于后续分析 AI 回复质量
 */
const { db, parseEvent } = require('./cloudbase-common');

exports.main = async (event) => {
  const { conversationId, messageTimestamp, feedback } = parseEvent(event);

  if (!conversationId || !messageTimestamp || !feedback) {
    return { success: false, message: '缺少必要参数' };
  }

  if (!['positive', 'negative'].includes(feedback)) {
    return { success: false, message: 'feedback 必须为 positive 或 negative' };
  }

  try {
    await db.collection('ai_feedback').add({
      conversationId,
      messageTimestamp,
      feedback,
      createdAt: Date.now(),
    });

    return { success: true, message: '反馈已记录' };
  } catch (error) {
    console.error('[submitAIFeedback] 错误:', error);
    return { success: false, message: error.message };
  }
};

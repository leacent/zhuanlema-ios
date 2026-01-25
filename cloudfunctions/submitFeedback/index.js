/**
 * 提交用户反馈
 * 输入: content, contact?（选填）
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();

exports.main = async (event, context) => {
  const { content, contact } = event || {};

  if (!content || typeof content !== "string" || content.trim() === "") {
    return { success: false, message: "反馈内容不能为空" };
  }

  try {
    await db.collection("feedback").add({
      content: content.trim(),
      contact: contact && typeof contact === "string" ? contact.trim() : "",
      createdAt: Date.now(),
    });
    return { success: true, message: "提交成功，感谢您的反馈" };
  } catch (e) {
    console.error("submitFeedback error:", e);
    return { success: false, message: "提交失败: " + e.message };
  }
};

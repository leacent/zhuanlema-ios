/**
 * 提交用户反馈
 * 输入: content, contact?（选填）
 */
const { db, parseEvent, ok, fail } = require("./cloudbase-common");

exports.main = async (event, context) => {
  const { content, contact } = parseEvent(event);

  if (!content || typeof content !== "string" || content.trim() === "") {
    return fail("反馈内容不能为空");
  }

  try {
    await db.collection("feedback").add({
      content: content.trim(),
      contact: contact && typeof contact === "string" ? contact.trim() : "",
      createdAt: Date.now(),
    });
    return ok({ message: "提交成功，感谢您的反馈" });
  } catch (e) {
    console.error("submitFeedback error:", e);
    return fail("提交失败: " + e.message);
  }
};

/**
 * 更新用户资料（需登录）
 * 用户唯一标识：userId（不可变）、phone_number（注册/登录时确定，仅允许补写，不可随意改）。
 * 可编辑字段：nickname、avatar。
 * Body 约定：nickname?, avatar?, phone_number?（可选，仅老用户补写手机号时传），access_token 由网关/客户端放入。
 * 用户身份：resolveUserId(event)（网关用户态或 JWT）。
 */
const { db, parseEvent, resolveUserId, fail } = require("./cloudbase-common");

exports.main = async (event, context) => {
  try {
    const userId = resolveUserId(event);
    if (!userId) {
      return fail("未登录");
    }
    console.log("[updateProfile] 当前访问 UserId:", userId);

    const raw = parseEvent(event);
    const nickname = raw.nickname;
    const avatar = raw.avatar;
    const phone_number = raw.phone_number;

    const updateData = {};
    if (typeof nickname === "string" && nickname.trim() !== "") {
      updateData.nickname = nickname.trim();
    }
    if (typeof avatar === "string") {
      updateData.avatar = avatar;
    }
    if (typeof phone_number === "string" && phone_number.trim() !== "") {
      updateData.phone_number = phone_number.trim();
    }

    if (Object.keys(updateData).length === 0) {
      return { success: true, message: "无需更新" };
    }

    const usersCol = db.collection("users");
    const docRef = usersCol.doc(userId);
    const existing = await docRef.get();
    const now = Date.now();

    // Only allow nickname, avatar, timestamps — never _id (CloudBase forbids updating _id)
    if (existing.data && Object.keys(existing.data).length > 0) {
      await docRef.update({
        ...updateData,
        updatedAt: now,
      });
    } else {
      // Document id is already set by docRef; do not include _id in body to avoid "不能更新_id的值"
      await docRef.set({
        nickname: updateData.nickname || "用户",
        avatar: updateData.avatar || "",
        phone_number: updateData.phone_number || null,
        createdAt: now,
        updatedAt: now,
      });
    }
    return { success: true, message: "更新成功" };
  } catch (e) {
    console.error("updateProfile error:", e);
    return fail("更新失败: " + e.message);
  }
};

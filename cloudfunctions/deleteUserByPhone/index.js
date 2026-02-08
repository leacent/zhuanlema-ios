/**
 * 删除指定手机号用户及其关联数据（管理用途，一次性调用）
 * @param {string} event.phone_number - 用户手机号
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: "prod-1-3g3ukjzod3d5e3a1",
});

const db = app.database();

exports.main = async (event, context) => {
  try {
    const phone = (event && event.phone_number) || (event && event.body && typeof event.body === "string" ? JSON.parse(event.body).phone_number : null) || (event && event.body && event.body.phone_number);
    if (!phone) {
      return { success: false, message: "缺少 phone_number 参数" };
    }
    console.log("[deleteUserByPhone] 查询手机号:", phone);

    // 1. 查找用户
    const usersCol = db.collection("users");
    const userRes = await usersCol.where({ phone_number: phone }).limit(10).get();
    const users = Array.isArray(userRes.data) ? userRes.data : [];
    if (users.length === 0) {
      return { success: false, message: "未找到手机号为 " + phone + " 的用户" };
    }

    const deletedUsers = [];
    for (const user of users) {
      const userId = user._id;
      console.log("[deleteUserByPhone] 开始删除用户:", userId);

      // 2. 删除关联数据
      const collections = ["check_ins", "post_likes", "comment_likes"];
      for (const col of collections) {
        try {
          const res = await db.collection(col).where({ _openid: userId }).remove();
          console.log(`[deleteUserByPhone] 已删除 ${col}: ${JSON.stringify(res)}`);
        } catch (e) {
          console.warn(`[deleteUserByPhone] 删除 ${col} 失败:`, e.message);
        }
      }

      // 3. 删除用户文档
      await usersCol.doc(userId).remove();
      deletedUsers.push(userId);
      console.log("[deleteUserByPhone] 用户已删除:", userId);
    }

    return {
      success: true,
      message: `已删除 ${deletedUsers.length} 个用户`,
      deletedUsers,
    };
  } catch (e) {
    console.error("deleteUserByPhone error:", e);
    return { success: false, message: "删除失败: " + e.message };
  }
};

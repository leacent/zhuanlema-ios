/**
 * 更新用户资料（需登录）
 * 用户唯一标识：userId（不可变）、phone_number（注册/登录时确定，仅允许补写，不可随意改）。
 * 可编辑字段：nickname、avatar。
 * Body 约定：nickname?, avatar?, phone_number?（可选，仅老用户补写手机号时传），access_token 由网关/客户端放入。
 * 用户身份：优先 auth.getUserInfo()；否则从 event.access_token 解析 JWT sub。
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: "prod-1-3g3ukjzod3d5e3a1",
});

const db = app.database();
const auth = app.auth();

function getUserIdFromEvent(event) {
  let token =
    (event && event.access_token) ||
    (event && event.body && typeof event.body === "object" && event.body.access_token) ||
    (event && event.body && typeof event.body === "string" ? (() => { try { return JSON.parse(event.body).access_token; } catch (_) { return null; } })() : null);
  if (!token || typeof token !== "string") return null;
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = b64.length % 4;
    if (pad) b64 += "=".repeat(4 - pad);
    const payload = JSON.parse(Buffer.from(b64, "base64").toString());
    return payload.sub || null;
  } catch (e) {
    return null;
  }
}

exports.main = async (event, context) => {
  try {
    let userId;
    try {
      const { uid, customUserId } = auth.getUserInfo();
      userId = customUserId || uid;
    } catch (_) {}
    if (!userId) {
      userId = getUserIdFromEvent(event);
    }
    if (!userId) {
      return { success: false, message: "未登录" };
    }
    console.log("[updateProfile] 当前访问 UserId:", userId);

    // 解析 body：网关可能传 event.body 为字符串或对象；无 body 时用 event 顶层兼容
    let raw = event && event.body && typeof event.body === "object" ? event.body : {};
    if (event && event.body && typeof event.body === "string") {
      try {
        raw = JSON.parse(event.body);
      } catch (_) {
        raw = {};
      }
    }
    if (!raw || typeof raw !== "object") raw = {};
    if (Object.keys(raw).length === 0 && event && typeof event === "object") {
      raw = event;
    }

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
    return { success: false, message: "更新失败: " + e.message };
  }
};

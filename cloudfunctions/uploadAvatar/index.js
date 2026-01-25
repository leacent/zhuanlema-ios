/**
 * 上传头像（需登录）
 * Body: imageBase64, access_token?
 * 用户身份：优先 auth.getUserInfo()；否则从 event.access_token 解析 JWT sub
 * 返回: { success, url } 或 { success: false, message }
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const auth = app.auth();

// 从 base64 中剥离 data URL 前缀
function stripDataUrlPrefix(dataUrl) {
  if (typeof dataUrl !== "string") return null;
  const i = dataUrl.indexOf(",");
  return i >= 0 ? dataUrl.slice(i + 1) : dataUrl;
}

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

    // 约定：仅从 body 读 event.body，单一数据源，不写 event.imageBase64 等兜底
    let raw = (event && event.body && typeof event.body === "object") ? event.body : {};
    if (event && event.body && typeof event.body === "string") {
      try { raw = JSON.parse(event.body); } catch (_) { raw = {}; }
    }
    let base64 = raw.imageBase64;
    base64 = stripDataUrlPrefix(base64);
    if (!base64) {
      return { success: false, message: "缺少 imageBase64" };
    }

    const buf = Buffer.from(base64, "base64");
    if (buf.length === 0) {
      return { success: false, message: "图片内容无效" };
    }
    // 单张头像建议不超过 2MB
    if (buf.length > 2 * 1024 * 1024) {
      return { success: false, message: "图片大小不能超过 2MB" };
    }

    const ext = "jpg";
    const cloudPath = `avatars/${userId}/${Date.now()}.${ext}`;
    const res = await app.uploadFile({
      cloudPath,
      fileContent: buf,
    });

    const fileID = res.fileID;
    if (!fileID) {
      return { success: false, message: "上传失败" };
    }

    const urlRes = await app.getTempFileURL({
      fileList: [fileID],
    });
    const fileList = urlRes.fileList || [];
    const first = fileList[0];
    const url = first && first.tempFileURL ? first.tempFileURL : (first && first.status === 0 && first.tempFileURL ? first.tempFileURL : null);
    if (!url) {
      return { success: false, message: "获取访问链接失败" };
    }

    // 同时返回 url（当前展示）和 fileID（存入数据库，getProfile 时再生成新临时链接，避免过期）
    return { success: true, url, fileID };
  } catch (e) {
    console.error("uploadAvatar error:", e);
    return { success: false, message: "上传失败: " + (e.message || String(e)) };
  }
};

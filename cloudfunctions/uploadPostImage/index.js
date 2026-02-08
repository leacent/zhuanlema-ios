/**
 * 上传帖子图片（需登录）
 * Body: imageBase64, access_token?
 * 返回: { success, data: { url, fileID } }
 */
const cloud = require("@cloudbase/node-sdk");
const { resolveUserId } = require("./shared-utils");

const app = cloud.init({ env: cloud.SYMBOL_CURRENT_ENV });
const auth = app.auth();

/** 剥离 data URL 前缀 */
function stripDataUrlPrefix(dataUrl) {
  if (typeof dataUrl !== "string") return null;
  const i = dataUrl.indexOf(",");
  return i >= 0 ? dataUrl.slice(i + 1) : dataUrl;
}

/** 单张图片最大 5MB */
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

exports.main = async (event) => {
  const userId = resolveUserId(auth, event);
  if (!userId) {
    return { success: false, message: "未登录" };
  }

  // 从 body 读取 imageBase64
  let raw = (event?.body && typeof event.body === "object") ? event.body : {};
  if (typeof event?.body === "string") {
    try { raw = JSON.parse(event.body); } catch (_) { raw = {}; }
  }
  let base64 = raw.imageBase64 ?? event?.imageBase64;
  base64 = stripDataUrlPrefix(base64);
  if (!base64) {
    return { success: false, message: "缺少 imageBase64" };
  }

  const buf = Buffer.from(base64, "base64");
  if (buf.length === 0) {
    return { success: false, message: "图片内容无效" };
  }
  if (buf.length > MAX_IMAGE_BYTES) {
    return { success: false, message: "图片大小不能超过 5MB" };
  }

  try {
    const cloudPath = `post-images/${userId}/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.jpg`;
    const res = await app.uploadFile({ cloudPath, fileContent: buf });

    const fileID = res.fileID;
    if (!fileID) {
      return { success: false, message: "上传失败" };
    }

    const urlRes = await app.getTempFileURL({ fileList: [fileID] });
    const first = (urlRes.fileList || [])[0];
    const url = first?.tempFileURL || null;
    if (!url) {
      return { success: false, message: "获取访问链接失败" };
    }

    return { success: true, data: { url, fileID } };
  } catch (e) {
    return { success: false, message: "上传失败: " + (e.message || String(e)) };
  }
};

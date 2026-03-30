/**
 * 上传帖子图片（需登录）
 * Body: imageBase64, access_token?
 * 返回: { success, data: { url, fileID } }
 */
const { app, resolveUserId, parseEvent, ok, fail } = require("./cloudbase-common");

/** 剥离 data URL 前缀 */
function stripDataUrlPrefix(dataUrl) {
  if (typeof dataUrl !== "string") return null;
  const i = dataUrl.indexOf(",");
  return i >= 0 ? dataUrl.slice(i + 1) : dataUrl;
}

/** 单张图片最大 5MB */
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

exports.main = async (event) => {
  const params = parseEvent(event);
  const userId = resolveUserId(event);
  if (!userId) {
    return fail("未登录");
  }

  let base64 = params.imageBase64;
  base64 = stripDataUrlPrefix(base64);
  if (!base64) {
    return fail("缺少 imageBase64");
  }

  const buf = Buffer.from(base64, "base64");
  if (buf.length === 0) {
    return fail("图片内容无效");
  }
  if (buf.length > MAX_IMAGE_BYTES) {
    return fail("图片大小不能超过 5MB");
  }

  try {
    const cloudPath = `post-images/${userId}/${Date.now()}_${Math.random().toString(36).slice(2, 8)}.jpg`;
    const res = await app.uploadFile({ cloudPath, fileContent: buf });

    const fileID = res.fileID;
    if (!fileID) {
      return fail("上传失败");
    }

    const urlRes = await app.getTempFileURL({ fileList: [fileID] });
    const first = (urlRes.fileList || [])[0];
    const url = first?.tempFileURL || null;
    if (!url) {
      return fail("获取访问链接失败");
    }

    return ok({ url, fileID });
  } catch (e) {
    return fail("上传失败: " + (e.message || String(e)));
  }
};

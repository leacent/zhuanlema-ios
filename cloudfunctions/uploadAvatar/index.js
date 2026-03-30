/**
 * 上传头像（需登录）
 * Body: imageBase64, access_token?
 * 用户身份：resolveUserId(event)
 * 返回: { success, url } 或 { success: false, message }
 */
const { app, parseEvent, resolveUserId, fail } = require("./cloudbase-common");

// 从 base64 中剥离 data URL 前缀
function stripDataUrlPrefix(dataUrl) {
  if (typeof dataUrl !== "string") return null;
  const i = dataUrl.indexOf(",");
  return i >= 0 ? dataUrl.slice(i + 1) : dataUrl;
}

exports.main = async (event, context) => {
  try {
    const userId = resolveUserId(event);
    if (!userId) {
      return fail("未登录");
    }

    const raw = parseEvent(event);
    let base64 = raw.imageBase64;
    base64 = stripDataUrlPrefix(base64);
    if (!base64) {
      return fail("缺少 imageBase64");
    }

    const buf = Buffer.from(base64, "base64");
    if (buf.length === 0) {
      return fail("图片内容无效");
    }
    // 单张头像建议不超过 2MB
    if (buf.length > 2 * 1024 * 1024) {
      return fail("图片大小不能超过 2MB");
    }

    const ext = "jpg";
    const cloudPath = `avatars/${userId}/${Date.now()}.${ext}`;
    const res = await app.uploadFile({
      cloudPath,
      fileContent: buf,
    });

    const fileID = res.fileID;
    if (!fileID) {
      return fail("上传失败");
    }

    const urlRes = await app.getTempFileURL({
      fileList: [fileID],
    });
    const fileList = urlRes.fileList || [];
    const first = fileList[0];
    const url = first && first.tempFileURL ? first.tempFileURL : (first && first.status === 0 && first.tempFileURL ? first.tempFileURL : null);
    if (!url) {
      return fail("获取访问链接失败");
    }

    // 同时返回 url（当前展示）和 fileID（存入数据库，getProfile 时再生成新临时链接，避免过期）
    return { success: true, url, fileID };
  } catch (e) {
    console.error("uploadAvatar error:", e);
    return fail("上传失败: " + (e.message || String(e)));
  }
};

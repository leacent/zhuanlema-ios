/**
 * 云函数共享工具模块
 * 提供 JWT 解析、热度计算等通用功能
 */

/**
 * 从 event 中提取用户 ID（解析 access_token JWT）
 * @param {object} event 云函数事件对象
 * @returns {string|null} 用户 ID
 */
function getUserIdFromEvent(event) {
  const token =
    event?.access_token ??
    event?.body?.access_token ??
    (typeof event?.body === "string"
      ? (() => {
          try {
            return JSON.parse(event.body).access_token;
          } catch (_) {
            return null;
          }
        })()
      : null);
  if (!token || typeof token !== "string") return null;
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;
    let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    if (b64.length % 4) b64 += "=".repeat(4 - (b64.length % 4));
    const payload = JSON.parse(Buffer.from(b64, "base64").toString());
    return payload.sub || null;
  } catch (_) {
    return null;
  }
}

/**
 * 从 auth + event 中获取用户 ID
 * 优先使用 auth.getUserInfo()，失败后从 event JWT 解析
 * @param {object} auth CloudBase auth 实例
 * @param {object} event 云函数事件对象
 * @returns {string|null} 用户 ID
 */
function resolveUserId(auth, event) {
  let userId = null;
  try {
    const { uid, customUserId } = auth.getUserInfo();
    userId = customUserId || uid;
  } catch (_) {}
  if (!userId) userId = getUserIdFromEvent(event);
  return userId;
}

/**
 * 计算帖子热度分（含时间衰减）
 * 公式：(likeCount + commentCount * 2) / (ageInHours + 2) ^ 1.5
 * @param {number} likeCount 点赞数
 * @param {number} commentCount 评论数
 * @param {number} createdAt 创建时间戳（ms）
 * @returns {number} hotScore
 */
function calcHotScore(likeCount, commentCount, createdAt) {
  const ageHours = Math.max(0, (Date.now() - createdAt) / 3600000);
  return (likeCount + commentCount * 2) / Math.pow(ageHours + 2, 1.5);
}

/**
 * 从 CloudBase 查询结果中安全提取文档
 * @param {object} res db.doc().get() 返回值
 * @returns {object|null} 文档对象
 */
function extractDoc(res) {
  if (!res || !res.data) return null;
  return Array.isArray(res.data) && res.data.length > 0
    ? res.data[0]
    : typeof res.data === "object"
    ? res.data
    : null;
}

module.exports = {
  getUserIdFromEvent,
  resolveUserId,
  calcHotScore,
  extractDoc,
};

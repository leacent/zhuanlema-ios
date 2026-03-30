/**
 * CloudBase 云函数公共模块（单一数据源）
 *
 * 所有云函数统一从此模块导入基础设施，禁止各函数自行 init 或重写工具函数。
 * 部署前运行 scripts/sync-cloud-shared.sh 将本文件同步到每个函数目录。
 *
 * @example
 * const { db, _, resolveUserId, parseEvent, ok, fail } = require('./cloudbase-common');
 */
const tcb = require('@cloudbase/node-sdk');

// ─── 环境 & 实例（全局唯一） ───

const ENV_ID = 'prod-1-3g3ukjzod3d5e3a1';
const app = tcb.init({ env: ENV_ID });
const db = app.database();
const _ = db.command;
const auth = app.auth();

// ─── 请求参数统一解析 ───

/**
 * 统一解析 event，兼容网关直传和 body 嵌套两种模式。
 * 返回合并后的扁平对象：event 顶层 + event.body（body 字段优先）。
 */
function parseEvent(event) {
  if (!event) return {};
  let body = {};
  if (typeof event.body === 'string') {
    try { body = JSON.parse(event.body); } catch (_e) { /* ignore */ }
  } else if (event.body && typeof event.body === 'object') {
    body = event.body;
  }
  const { body: _discarded, ...rest } = event;
  return { ...rest, ...body };
}

// ─── 用户身份解析 ───

/**
 * 从 JWT access_token 中提取 userId（不校验签名，仅解码 payload.sub）。
 */
function getUserIdFromToken(event) {
  const params = parseEvent(event);
  const token = params.access_token;
  if (!token || typeof token !== 'string') return null;
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    let b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    if (b64.length % 4) b64 += '='.repeat(4 - (b64.length % 4));
    const payload = JSON.parse(Buffer.from(b64, 'base64').toString());
    return payload.sub || null;
  } catch (_e) {
    return null;
  }
}

/**
 * 解析用户 ID：优先 auth.getUserInfo()，失败回退到 JWT 解码。
 * @param {object} event 云函数 event 对象
 * @returns {string|null} userId
 */
function resolveUserId(event) {
  let userId = null;
  try {
    const info = auth.getUserInfo();
    userId = info.customUserId || info.uid;
  } catch (_e) { /* 网关未转发用户态时 auth 不可用 */ }
  if (!userId) userId = getUserIdFromToken(event);
  return userId;
}

// ─── 响应构造器 ───

function ok(data) {
  return { success: true, data: data !== undefined ? data : null };
}

function fail(message) {
  return { success: false, message: message || '操作失败' };
}

// ─── 时间工具 ───

/**
 * 获取北京时间（强制 UTC+8，不依赖服务器时区）。
 */
function getBeijingNow() {
  const now = new Date();
  const utcMs = now.getTime() + now.getTimezoneOffset() * 60000;
  const bjMs = utcMs + 8 * 3600000;
  const bj = new Date(bjMs);
  return {
    dateStr: `${bj.getFullYear()}-${String(bj.getMonth() + 1).padStart(2, '0')}-${String(bj.getDate()).padStart(2, '0')}`,
    hour: bj.getHours(),
    minute: bj.getMinutes(),
  };
}

// ─── 内容安全 ───

/**
 * 对用户生成内容做消毒，防止 prompt 注入。
 */
function sanitizeUserContent(text, maxLen = 200) {
  if (!text || typeof text !== 'string') return '';
  let cleaned = text
    .replace(/ignore\s+(all\s+)?(previous|above|prior)\s+(instructions?|prompts?|rules?)/gi, '[已过滤]')
    .replace(/forget\s+(all\s+)?(previous|above|prior)\s+(instructions?|prompts?|rules?)/gi, '[已过滤]')
    .replace(/you\s+are\s+now\s+a/gi, '[已过滤]')
    .replace(/disregard\s+(all\s+)?(previous|above|prior)/gi, '[已过滤]')
    .replace(/system\s*prompt/gi, '[已过滤]')
    .replace(/忽略.{0,6}(之前|以上|先前|所有).{0,6}(指令|提示|规则|要求)/g, '[已过滤]')
    .replace(/你现在是/g, '[已过滤]')
    .replace(/假装你是/g, '[已过滤]')
    .replace(/扮演/g, '[已过滤]');
  if (cleaned.length > maxLen) cleaned = cleaned.slice(0, maxLen) + '…';
  return cleaned;
}

// ─── 业务工具 ───

/**
 * 计算帖子/评论热度分（含时间衰减）。
 */
function calcHotScore(likeCount, commentCount, createdAt) {
  const ageHours = Math.max(0, (Date.now() - createdAt) / 3600000);
  return (likeCount + commentCount * 2) / Math.pow(ageHours + 2, 1.5);
}

// ─── 导出 ───

module.exports = {
  app,
  db,
  _,
  auth,
  ENV_ID,
  parseEvent,
  resolveUserId,
  getUserIdFromToken,
  ok,
  fail,
  getBeijingNow,
  sanitizeUserContent,
  calcHotScore,
};

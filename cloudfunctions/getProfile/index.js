/**
 * 获取当前用户资料（需登录）
 * 新用户（无 users 文档）时自动分配随机动漫头像和随机昵称
 * 支持两种方式获取用户身份：
 * 1. 网关转发用户态：auth.getUserInfo() 得到 uid
 * 2. 网关仅 Publishable Key：从 event.access_token 解析 JWT 的 sub 作为 userId
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: "prod-1-3g3ukjzod3d5e3a1",
});

const db = app.database();
const auth = app.auth();

/** 从 event 或 event.body 中取 access_token，并解析 JWT payload.sub 作为 userId（不校验签名，仅用于网关不转发用户态时的回退） */
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

// 随机动漫风格头像 URL（可替换为自有 CDN）
const ANIME_AVATARS = [
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a1",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a2",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a3",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a4",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a5",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a6",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a7",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a8",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a9",
  "https://api.dicebear.com/7.x/adventurer-neutral/svg?seed=a10",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b1",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b2",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b3",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b4",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b5",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c1",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c2",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c3",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c4",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c5",
];

// 随机昵称（动漫/趣味风格）
const RANDOM_NICKNAMES = [
  "小萌新", "咸鱼选手", "吃瓜群众", "躺平达人", "发财小能手",
  "锦鲤本鲤", "暴富预备役", "今日份开心", "攒钱小透明", "搞钱人",
  "佛系韭菜", "明日暴富", "好运连连", "稳稳的幸福", "小确幸",
  "今日宜发财", "赚点小钱钱", "人间清醒", "打工人之光", "富贵花开",
  "财源广进", "日日涨", "小财迷", "稳健型选手", "长期主义",
  "定投小王子", "复利信徒", "价值投资者", "趋势追随者", "抄底达人",
];

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/** Normalize stored timestamp to seconds (handles ms number or { $date: ms }) */
function createdAtToSeconds(val) {
  if (val == null) return null;
  if (typeof val === "number") return val > 1e12 ? val / 1000 : val;
  if (typeof val === "object" && typeof val.$date === "number") return val.$date / 1000;
  return null;
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
    console.log("[getProfile] 当前访问 UserId:", userId);

    // 解析 body（网关可能传 event.body 或平铺到 event），用于可选 phone_number（验证码注册后首次拉资料时写入）
    let rawBody = event && event.body && typeof event.body === "object" ? event.body : {};
    if (event && event.body && typeof event.body === "string") {
      try { rawBody = JSON.parse(event.body); } catch (_) {}
    }
    if (!rawBody || typeof rawBody !== "object") rawBody = {};
    if (Object.keys(rawBody).length === 0 && event && typeof event === "object") rawBody = event;
    const phoneForNewUser = typeof rawBody.phone_number === "string" && rawBody.phone_number.trim() !== ""
      ? rawBody.phone_number.trim()
      : null;
    if (phoneForNewUser) {
      console.log("[getProfile] 收到 phone_number（新用户将写入）:", phoneForNewUser);
    }

    const usersCol = db.collection("users");
    const res = await usersCol.doc(userId).get();
    // CloudBase doc().get() 返回的 data 是数组 [ document ]，单条也如此
    const raw = Array.isArray(res.data) && res.data.length > 0 ? res.data[0] : res.data;
    const data = raw && typeof raw === "object" ? raw : null;

    if (!data || Object.keys(data).length === 0) {
      console.log("[getProfile] 未找到用户文档，准备创建新用户:", userId);
      // 新用户：分配随机动漫头像和随机昵称并落库；若有传入 phone_number 则写入（验证码注册后首次拉资料）
      const nickname = pickRandom(RANDOM_NICKNAMES);
      const avatar = pickRandom(ANIME_AVATARS);
      const now = Date.now();
      const created_at = now / 1000;
      const phone_number = phoneForNewUser || null;
      await usersCol.doc(userId).set({
        _id: userId,
        nickname,
        avatar,
        phone_number,
        createdAt: now,
        updatedAt: now,
      });
      return {
        success: true,
        data: {
          _id: userId,
          nickname,
          avatar,
          phone_number,
          created_at,
        },
      };
    }

    console.log("[getProfile] 文档字段:", Object.keys(data));

    // 约定：仅从 data.avatar 读，不写 data.avatarUrl / data.avatar_url 等兜底，错误及时暴露
    let avatarVal = typeof data.avatar === "string" ? data.avatar.trim() : "";

    // 约定：只向客户端返回可用的 https 链接或空，不返回 fileID。若存的是 fileID 则换成临时链接
    if (avatarVal && avatarVal.startsWith("cloud://")) {
      try {
        const urlRes = await app.getTempFileURL({ fileList: [avatarVal] });
        const fileList = urlRes.fileList || [];
        const first = fileList[0];
        const tempUrl = first && first.tempFileURL ? first.tempFileURL : (first && first.status === 0 && first.tempFileURL ? first.tempFileURL : null);
        avatarVal = tempUrl || "";
      } catch (e) {
        console.warn("[getProfile] getTempFileURL 失败:", e.message);
        avatarVal = "";
      }
    }

    console.log("[getProfile] 数据库读取成功:", {
      userId,
      nickname: data.nickname,
      avatarLen: avatarVal.length,
      avatarPreview: avatarVal ? avatarVal.slice(0, 60) + "..." : "(empty)"
    });

    return {
      success: true,
      data: {
        _id: data._id || userId,
        nickname: data.nickname || "用户",
        avatar: avatarVal,
        phone_number: data.phone_number ?? null,
        created_at: createdAtToSeconds(data.createdAt) ?? Date.now() / 1000,
      },
    };
  } catch (e) {
    console.error("getProfile error:", e);
    return { success: false, message: "获取资料失败: " + e.message };
  }
};

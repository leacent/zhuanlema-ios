/**
 * 获取当前用户资料（需登录）
 * 新用户（无 users 文档）时：昵称由 CloudBase AI（混元）生成，头像从 avatar_pool 集合随机取；失败则用默认「用户」和空头像。
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

/** 使用 CloudBase AI（混元）生成 2–6 字中文昵称，失败返回 null */
async function getNicknameWithAI() {
  try {
    const ai = app.ai();
    const model = ai.createModel("hunyuan-exp");
    const res = await model.generateText({
      model: "hunyuan-turbos-latest",
      messages: [{
        role: "user",
        content: "请生成一个 2 到 6 个汉字的中文昵称，用于投资理财社区 App，要求可爱、有趣、不涉及真实名人。只输出昵称本身，不要引号、不要解释、不要标点。",
      }],
    });
    if (!res || typeof res.text !== "string") return null;
    let name = res.text.trim().replace(/["""''\n\r]/g, "").slice(0, 6);
    if (!name) return null;
    return name;
  } catch (e) {
    console.warn("[getProfile] AI 昵称生成失败，使用默认:", e.message);
    return null;
  }
}

/** 从 avatar_pool 集合随机取一条头像 URL，失败或空返回 "" */
async function getRandomAvatarFromPool() {
  try {
    const col = db.collection("avatar_pool");
    const res = await col.limit(50).get();
    // 兼容多种可能返回格式：Node SDK 通常 { data: Array }，部分环境可能 result.data / list
    const rawList = res.data ?? res.result?.data ?? res.list;
    const list = Array.isArray(rawList) ? rawList : (rawList != null ? [rawList] : []);
    console.log("[getProfile] avatar_pool res.keys=" + Object.keys(res).join(",") + " list.length=" + list.length);
    if (list.length === 0) {
      console.warn("[getProfile] avatar_pool 无数据，请确认集合已有记录且 getProfile 有读权限");
      return "";
    }
    const item = list[Math.floor(Math.random() * list.length)];
    const url = item && (item.url || item.avatar);
    const result = typeof url === "string" && url.trim() ? url.trim() : "";
    if (!result && item) {
      console.warn("[getProfile] avatar_pool 项无 url/avatar 字段, item.keys=" + Object.keys(item).join(","));
    }
    console.log("[getProfile] 随机头像 URL:", result ? result.slice(0, 80) + "..." : "(empty)");
    return result;
  } catch (e) {
    console.warn("[getProfile] avatar_pool 读取失败:", e.message, e.code || "");
    return "";
  }
}

/** iOS AsyncImage 不支持 SVG，将 DiceBear 的 SVG URL 转为 PNG 以便客户端能正常显示 */
function avatarUrlToPng(url) {
  if (typeof url !== "string" || !url.trim()) return url;
  if (url.includes("dicebear.com") && url.includes("/svg")) {
    return url.replace(/\/svg\?/, "/png?").replace(/\/svg$/, "/png");
  }
  return url;
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
      const nickname = (await getNicknameWithAI()) || "用户";
      const avatarRaw = (await getRandomAvatarFromPool()) || "";
      const avatar = avatarUrlToPng(avatarRaw);
      console.log("[getProfile] 新用户创建 nickname=" + nickname + " avatarLen=" + avatar.length);
      const now = Date.now();
      const created_at = now / 1000;
      const phone_number = phoneForNewUser || null;
      await usersCol.doc(userId).set({
        nickname,
        avatar,
        phone_number,
        createdAt: now,
        updatedAt: now,
      });
      return {
        success: true,
        data: { _id: userId, nickname, avatar, phone_number, created_at },
      };
    }

    console.log("[getProfile] 文档字段:", Object.keys(data));

    // 约定：仅从 data.avatar 读，不写 data.avatarUrl / data.avatar_url 等兜底，错误及时暴露
    let avatarVal = typeof data.avatar === "string" ? data.avatar.trim() : "";
    // 老用户曾未写过头像（空），则从 avatar_pool 补一份并写回
    if (!avatarVal) {
      const pooled = await getRandomAvatarFromPool();
      if (pooled) {
        avatarVal = avatarUrlToPng(pooled);
        const now = Date.now();
        await usersCol.doc(userId).update({ avatar: avatarVal, updatedAt: now });
        console.log("[getProfile] 已为无头像用户补写随机头像");
      }
    }

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

    let avatarForClient = avatarUrlToPng(avatarVal);
    if (avatarForClient !== avatarVal && avatarForClient) {
      const now = Date.now();
      await usersCol.doc(userId).update({ avatar: avatarForClient, updatedAt: now });
    }
    console.log("[getProfile] 数据库读取成功:", {
      userId,
      nickname: data.nickname,
      avatarLen: avatarForClient.length,
      avatarPreview: avatarForClient ? avatarForClient.slice(0, 60) + "..." : "(empty)"
    });

    return {
      success: true,
      data: {
        _id: data._id || userId,
        nickname: data.nickname || "用户",
        avatar: avatarForClient,
        phone_number: data.phone_number ?? null,
        created_at: createdAtToSeconds(data.createdAt) ?? Date.now() / 1000,
      },
    };
  } catch (e) {
    console.error("getProfile error:", e);
    return { success: false, message: "获取资料失败: " + e.message };
  }
};

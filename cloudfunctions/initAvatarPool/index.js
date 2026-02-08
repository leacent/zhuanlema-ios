/**
 * 一次性初始化：向 avatar_pool 集合写入 50 条动漫头像 URL，供 getProfile 新用户随机分配。
 * 若集合中已有文档则不再写入（幂等）。部署后手动调用一次即可。
 *
 * 使用前请在 CloudBase 控制台先创建集合：数据库 -> 添加集合 -> 集合名称 avatar_pool。
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: "prod-1-3g3ukjzod3d5e3a1",
});

const db = app.database();

// 50 个公开免费的动漫风格头像 URL（DiceBear PNG 格式，iOS AsyncImage 兼容）
const AVATAR_URLS = [
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a1&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a2&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a3&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a4&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a5&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a6&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a7&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a8&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a9&size=200",
  "https://api.dicebear.com/7.x/adventurer-neutral/png?seed=a10&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b1&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b2&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b3&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b4&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b5&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b6&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b7&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b8&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b9&size=200",
  "https://api.dicebear.com/7.x/lorelei-neutral/png?seed=b10&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c1&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c2&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c3&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c4&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c5&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c6&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c7&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c8&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c9&size=200",
  "https://api.dicebear.com/7.x/notionists/png?seed=c10&size=200",
  "https://api.dicebear.com/7.x/fun-emoji/png?seed=d1&size=200",
  "https://api.dicebear.com/7.x/fun-emoji/png?seed=d2&size=200",
  "https://api.dicebear.com/7.x/fun-emoji/png?seed=d3&size=200",
  "https://api.dicebear.com/7.x/fun-emoji/png?seed=d4&size=200",
  "https://api.dicebear.com/7.x/fun-emoji/png?seed=d5&size=200",
  "https://api.dicebear.com/7.x/avataaars-neutral/png?seed=e1&size=200",
  "https://api.dicebear.com/7.x/avataaars-neutral/png?seed=e2&size=200",
  "https://api.dicebear.com/7.x/avataaars-neutral/png?seed=e3&size=200",
  "https://api.dicebear.com/7.x/avataaars-neutral/png?seed=e4&size=200",
  "https://api.dicebear.com/7.x/avataaars-neutral/png?seed=e5&size=200",
  "https://api.dicebear.com/7.x/bottts-neutral/png?seed=f1&size=200",
  "https://api.dicebear.com/7.x/bottts-neutral/png?seed=f2&size=200",
  "https://api.dicebear.com/7.x/bottts-neutral/png?seed=f3&size=200",
  "https://api.dicebear.com/7.x/bottts-neutral/png?seed=f4&size=200",
  "https://api.dicebear.com/7.x/bottts-neutral/png?seed=f5&size=200",
  "https://api.dicebear.com/7.x/micah/png?seed=g1&size=200",
  "https://api.dicebear.com/7.x/micah/png?seed=g2&size=200",
  "https://api.dicebear.com/7.x/micah/png?seed=g3&size=200",
  "https://api.dicebear.com/7.x/micah/png?seed=g4&size=200",
  "https://api.dicebear.com/7.x/micah/png?seed=g5&size=200",
  "https://api.dicebear.com/7.x/thumbs/png?seed=h1&size=200",
  "https://api.dicebear.com/7.x/thumbs/png?seed=h2&size=200",
];

exports.main = async (event, context) => {
  try {
    // 是否强制重新初始化（删除旧数据重写）
    const force = (event && event.force) || (event && event.body && typeof event.body === "string" ? JSON.parse(event.body).force : false);
    const col = db.collection("avatar_pool");

    if (force) {
      // 强制模式：清空旧数据再写入
      console.log("[initAvatarPool] 强制模式，清空旧数据...");
      try {
        // 分批删除（每次最多 500 条）
        let deleted = 0;
        while (true) {
          const batch = await col.limit(500).get();
          const docs = Array.isArray(batch.data) ? batch.data : [];
          if (docs.length === 0) break;
          for (const doc of docs) {
            await col.doc(doc._id).remove();
            deleted++;
          }
        }
        console.log(`[initAvatarPool] 已清空 ${deleted} 条旧数据`);
      } catch (e) {
        console.warn("[initAvatarPool] 清空失败:", e.message);
      }
    } else {
      // 非强制模式：已有数据则跳过
      try {
        const existing = await col.limit(1).get();
        const hasData = existing.data && Array.isArray(existing.data) && existing.data.length > 0;
        if (hasData) {
          return { success: true, message: "avatar_pool 已有数据，跳过初始化（传 force=true 可强制重写）" };
        }
      } catch (e) {
        if (e.code !== "DATABASE_COLLECTION_NOT_EXIST") throw e;
      }
    }

    for (const url of AVATAR_URLS) {
      await col.add({ url });
    }
    return { success: true, message: `已写入 ${AVATAR_URLS.length} 条 PNG 头像 URL` };
  } catch (e) {
    console.error("initAvatarPool error:", e);
    return { success: false, message: "初始化失败: " + e.message };
  }
};

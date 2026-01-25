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

// 50 个公开免费的动漫风格头像 URL（DiceBear 等）
const AVATAR_URLS = [
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
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b6",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b7",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b8",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b9",
  "https://api.dicebear.com/7.x/lorelei-neutral/svg?seed=b10",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c1",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c2",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c3",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c4",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c5",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c6",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c7",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c8",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c9",
  "https://api.dicebear.com/7.x/notionists/svg?seed=c10",
  "https://api.dicebear.com/7.x/fun-emoji/svg?seed=d1",
  "https://api.dicebear.com/7.x/fun-emoji/svg?seed=d2",
  "https://api.dicebear.com/7.x/fun-emoji/svg?seed=d3",
  "https://api.dicebear.com/7.x/fun-emoji/svg?seed=d4",
  "https://api.dicebear.com/7.x/fun-emoji/svg?seed=d5",
  "https://api.dicebear.com/7.x/avataaars-neutral/svg?seed=e1",
  "https://api.dicebear.com/7.x/avataaars-neutral/svg?seed=e2",
  "https://api.dicebear.com/7.x/avataaars-neutral/svg?seed=e3",
  "https://api.dicebear.com/7.x/avataaars-neutral/svg?seed=e4",
  "https://api.dicebear.com/7.x/avataaars-neutral/svg?seed=e5",
  "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=f1",
  "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=f2",
  "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=f3",
  "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=f4",
  "https://api.dicebear.com/7.x/bottts-neutral/svg?seed=f5",
  "https://api.dicebear.com/7.x/micah/svg?seed=g1",
  "https://api.dicebear.com/7.x/micah/svg?seed=g2",
  "https://api.dicebear.com/7.x/micah/svg?seed=g3",
  "https://api.dicebear.com/7.x/micah/svg?seed=g4",
  "https://api.dicebear.com/7.x/micah/svg?seed=g5",
  "https://api.dicebear.com/7.x/thumbs/svg?seed=h1",
  "https://api.dicebear.com/7.x/thumbs/svg?seed=h2",
];

exports.main = async (event, context) => {
  try {
    const col = db.collection("avatar_pool");
    let skipInit = false;
    try {
      const existing = await col.limit(1).get();
      skipInit = existing.data && Array.isArray(existing.data) && existing.data.length > 0;
    } catch (e) {
      if (e.code !== "DATABASE_COLLECTION_NOT_EXIST") throw e;
      // 集合不存在，下面 add 时会自动创建
    }
    if (skipInit) {
      return { success: true, message: "avatar_pool 已有数据，跳过初始化" };
    }
    for (const url of AVATAR_URLS) {
      await col.add({ url });
    }
    return { success: true, message: `已写入 ${AVATAR_URLS.length} 条头像 URL` };
  } catch (e) {
    console.error("initAvatarPool error:", e);
    return { success: false, message: "初始化失败: " + e.message };
  }
};

const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();

exports.main = async (event, context) => {
  const { limit = 20, offset = 0 } = event;

  try {
    const res = await db.collection("user_posts")
      .orderBy("createdAt", "desc")
      .skip(offset)
      .limit(limit)
      .get();

    return {
      success: true,
      data: {
        posts: res.data
      }
    };
  } catch (e) {
    return {
      success: false,
      message: "获取帖子失败: " + e.message
    };
  }
};

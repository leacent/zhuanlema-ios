/**
 * 获取用户资料统计
 * 输入: userId
 * 返回: checkInCount, postCount, totalLikeCount
 */
const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();

exports.main = async (event, context) => {
  const { userId } = event;

  if (!userId) {
    return {
      success: false,
      message: "缺少 userId",
    };
  }

  try {
    // 打卡数: check_ins 中 _openid === userId 的条数
    const checkInsCol = db.collection("check_ins");
    const checkInRes = await checkInsCol.where({ _openid: userId }).count();
    const checkInCount = checkInRes.total || 0;

    // 帖子数 + 点赞总和: user_posts 中 userId === userId
    const postsCol = db.collection("user_posts");
    const postsRes = await postsCol.where({ userId: userId }).get();
    const posts = postsRes.data || [];
    const postCount = posts.length;
    const totalLikeCount = posts.reduce((sum, p) => sum + (p.likeCount || 0), 0);

    return {
      success: true,
      data: {
        checkInCount,
        postCount,
        totalLikeCount,
      },
    };
  } catch (e) {
    console.error("getUserStats error:", e);
    return {
      success: false,
      message: "获取用户统计失败: " + e.message,
    };
  }
};

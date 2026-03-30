/**
 * 获取用户资料统计
 * 输入: userId
 * 返回: checkInCount, postCount, totalLikeCount
 */
const { db, parseEvent, ok, fail } = require("./cloudbase-common");

exports.main = async (event, context) => {
  const params = parseEvent(event);
  const { userId } = params;

  if (!userId) {
    return fail("缺少 userId");
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

    return ok({
      checkInCount,
      postCount,
      totalLikeCount,
    });
  } catch (e) {
    console.error("getUserStats error:", e);
    return fail("获取用户统计失败: " + e.message);
  }
};

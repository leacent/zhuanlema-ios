const cloud = require("@cloudbase/node-sdk");

const app = cloud.init({
  env: cloud.SYMBOL_CURRENT_ENV,
});

const db = app.database();

exports.main = async (event, context) => {
  const { userId, result, date } = event;

  if (!userId || !result || !date) {
    return {
      success: false,
      message: "参数缺失",
    };
  }

  try {
    await db.collection("check_ins").add({
      _openid: userId, // 这里我们手动指定 _openid 为用户 ID，方便后续权限管理
      result: result,
      date: date,
      createTime: Date.now(),
    });

    return {
      success: true,
      message: "打卡成功",
    };
  } catch (e) {
    return {
      success: false,
      message: "数据库写入失败: " + e.message,
    };
  }
};

/**
 * 获取今日打卡统计云函数
 * 
 * @returns {Object} - 返回今日打卡统计数据
 */
const cloud = require('wx-server-sdk');

cloud.init({
  env: cloud.DYNAMIC_CURRENT_ENV
});

exports.main = async (event, context) => {
  const db = cloud.database();
  const _ = db.command;
  
  try {
    // 获取今天的日期字符串 (YYYY-MM-DD)
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    
    // 统计今日打卡数据
    const collection = db.collection('check_ins');
    
    // 统计总打卡人数
    const totalResult = await collection
      .where({
        date: todayStr
      })
      .count();
    
    const totalCount = totalResult.total;
    
    // 统计赚钱人数（result: 'yes'）
    const yesResult = await collection
      .where({
        date: todayStr,
        result: 'yes'
      })
      .count();
    
    const yesCount = yesResult.total;
    
    // 统计亏钱人数（result: 'no'）
    const noResult = await collection
      .where({
        date: todayStr,
        result: 'no'
      })
      .count();
    
    const noCount = noResult.total;
    
    // 计算百分比
    const yesPercentage = totalCount > 0 ? Math.round((yesCount / totalCount) * 100) : 0;
    const noPercentage = totalCount > 0 ? Math.round((noCount / totalCount) * 100) : 0;
    
    return {
      success: true,
      data: {
        date: todayStr,
        totalCount,
        yesCount,
        noCount,
        yesPercentage,
        noPercentage,
        message: totalCount > 0 
          ? `今日 ${yesPercentage}% 的人赚了` 
          : '今日还没有人打卡'
      }
    };
  } catch (error) {
    console.error('获取打卡统计失败:', error);
    return {
      success: false,
      message: '获取统计数据失败'
    };
  }
};

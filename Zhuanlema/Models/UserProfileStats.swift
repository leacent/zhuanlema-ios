/**
 * 用户资料统计模型
 * 对应 getUserStats 云函数返回
 */
import Foundation

struct UserProfileStats: Codable {
    /// 打卡次数
    let checkInCount: Int
    /// 帖子数
    let postCount: Int
    /// 收到的点赞总数
    let totalLikeCount: Int
}

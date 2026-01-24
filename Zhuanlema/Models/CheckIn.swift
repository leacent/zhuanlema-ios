/**
 * 打卡记录数据模型
 * 对应 CloudBase check_ins 集合
 */
import Foundation

struct CheckIn: Codable, Identifiable {
    /// 打卡记录ID
    let id: String
    /// 用户ID
    let userId: String
    /// 日期 (YYYY-MM-DD)
    let date: String
    /// 打卡结果: "yes" 或 "no"
    let result: String
    /// 创建时间
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case date
        case result
        case createdAt
    }
}

/// 打卡统计数据
struct CheckInStats: Codable {
    /// 日期
    let date: String
    /// 总打卡人数
    let totalCount: Int
    /// 赚钱人数
    let yesCount: Int
    /// 亏钱人数
    let noCount: Int
    /// 赚钱百分比
    let yesPercentage: Int
    /// 亏钱百分比
    let noPercentage: Int
    /// 统计描述
    let message: String
}

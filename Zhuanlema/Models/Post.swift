/**
 * 帖子数据模型
 * 对应 CloudBase posts 集合
 */
import Foundation

struct Post: Codable, Identifiable {
    /// 帖子ID
    let id: String
    /// 用户ID
    let userId: String
    /// 内容
    var content: String
    /// 用户昵称 (冗余字段)
    var nickname: String?
    /// 图片URL列表
    var images: [String]
    /// 标签列表
    var tags: [String]
    /// 点赞数
    var likeCount: Int
    /// 发布时间
    let createdAt: Double
    
    /// 用户信息（扩展字段，不存储在数据库）
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case content
        case nickname
        case images
        case tags
        case likeCount
        case createdAt
    }
}

extension Post {
    var createdAtDate: Date {
        return Date(timeIntervalSince1970: createdAt / 1000)
    }
}

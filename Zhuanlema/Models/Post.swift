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
    /// 评论数
    var commentCount: Int
    /// 发布时间
    let createdAt: Double
    
    /// 用户信息（扩展字段，不存储在数据库）
    var user: User?
    
    /// 当前用户是否已点赞（扩展字段，不存储在数据库）
    var isLiked: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case content
        case nickname
        case images
        case tags
        case likeCount
        case commentCount
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        content = try container.decode(String.self, forKey: .content)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        createdAt = try container.decode(Double.self, forKey: .createdAt)
    }

    /// Memberwise init for previews and tests
    init(id: String, userId: String, content: String, nickname: String?, images: [String], tags: [String], likeCount: Int, commentCount: Int, createdAt: Double, user: User? = nil, isLiked: Bool = false) {
        self.id = id
        self.userId = userId
        self.content = content
        self.nickname = nickname
        self.images = images
        self.tags = tags
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.user = user
        self.isLiked = isLiked
    }
}

extension Post {
    /// 格式化的创建时间
    var createdAtDate: Date? {
        return Date(timeIntervalSince1970: createdAt / 1000)
    }
}

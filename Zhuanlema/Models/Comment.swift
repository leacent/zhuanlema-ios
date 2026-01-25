/**
 * 评论数据模型
 * 对应 CloudBase post_comments 集合
 */
import Foundation

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    var content: String
    var nickname: String?
    /// 父评论 ID（为空表示一级评论）
    var parentId: String?
    /// 被回复的评论 ID（通常等于 parentId）
    var replyToCommentId: String?
    /// 被回复的用户昵称（冗余字段，用于展示“回复 XXX”）
    var replyToNickname: String?
    /// 点赞数
    var likeCount: Int
    /// 当前用户是否已点赞（扩展字段，本地合并）
    var isLiked: Bool = false
    let createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case postId
        case userId
        case content
        case nickname
        case parentId
        case replyToCommentId
        case replyToNickname
        case likeCount
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        postId = try c.decode(String.self, forKey: .postId)
        userId = try c.decode(String.self, forKey: .userId)
        content = try c.decode(String.self, forKey: .content)
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        parentId = try c.decodeIfPresent(String.self, forKey: .parentId)
        replyToCommentId = try c.decodeIfPresent(String.self, forKey: .replyToCommentId)
        replyToNickname = try c.decodeIfPresent(String.self, forKey: .replyToNickname)
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        createdAt = try c.decode(Double.self, forKey: .createdAt)
    }

    init(id: String, postId: String, userId: String, content: String, nickname: String?, parentId: String? = nil, replyToCommentId: String? = nil, replyToNickname: String? = nil, likeCount: Int = 0, isLiked: Bool = false, createdAt: Double) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.content = content
        self.nickname = nickname
        self.parentId = parentId
        self.replyToCommentId = replyToCommentId
        self.replyToNickname = replyToNickname
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.createdAt = createdAt
    }
}

extension Comment {
    var createdAtDate: Date? {
        Date(timeIntervalSince1970: createdAt / 1000)
    }
}

/**
 * AI 对话数据模型
 * 对应 CloudBase ai_conversations 集合
 */
import Foundation

struct AIConversation: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    var messages: [ChatMessage]
    let createdAt: Double
    let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, title, messages, createdAt, updatedAt
    }
}

struct ChatMessage: Codable, Identifiable {
    let role: String
    var content: String
    let timestamp: Double?

    let stableId: String

    var id: String { stableId }
    var isUser: Bool { role == "user" }

    init(role: String, content: String, timestamp: Double?) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.stableId = UUID().uuidString
    }

    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp)
        stableId = UUID().uuidString
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
    }
}

enum MessageFeedback: String {
    case none
    case positive
    case negative
}

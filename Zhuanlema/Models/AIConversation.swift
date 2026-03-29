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
    let content: String
    let timestamp: Double?

    var id: String { "\(role)_\(timestamp ?? 0)_\(content.hashValue)" }
    var isUser: Bool { role == "user" }
}

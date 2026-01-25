/**
 * 消息通知模型
 * 对应 CloudBase notifications 集合 / getNotifications 返回项
 */
import Foundation

struct NotificationItem: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let body: String
    var read: Bool
    let createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case title
        case body
        case read
        case createdAt
    }

    var createdAtDate: Date {
        Date(timeIntervalSince1970: createdAt / 1000)
    }
}

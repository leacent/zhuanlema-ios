/**
 * 用户数据模型
 * 支持从 CloudBase 身份认证用户转换
 */
import Foundation

struct User: Codable, Identifiable {
    /// 用户ID
    let id: String
    /// 手机号
    let phoneNumber: String?
    /// 昵称
    var nickname: String
    /// 头像URL
    var avatar: String
    /// 注册时间
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case phoneNumber
        case nickname
        case avatar
        case createdAt
    }
    
    /// 从 CloudBase 用户转换
    init(from cloudBaseUser: CloudBaseUser) {
        self.id = cloudBaseUser.uid
        self.phoneNumber = cloudBaseUser.phone_number?.replacingOccurrences(of: "+86 ", with: "")
        self.nickname = cloudBaseUser.nickname ?? "用户\(cloudBaseUser.uid.prefix(4))"
        self.avatar = cloudBaseUser.avatar ?? "https://thirdwx.qlogo.cn/mmopen/vi_32/POgEwh4mIHO4nibH0KlMECNjjGxQUq24ZEaGT4poC6icRiccVGKSyXwibcPq4BWmiaIGuG1icwxaQX6grC9VemZoJ8rg/132"
        
        if let timestamp = cloudBaseUser.created_at {
            self.createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp))
        } else {
            self.createdAt = Date()
        }
    }

    /// 从 getProfile 接口返回数据转换
    init(id: String, phoneNumber: String?, nickname: String, avatar: String, createdAt: Date) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.nickname = nickname
        self.avatar = avatar
        self.createdAt = createdAt
    }
}

/// getProfile 云函数返回的 data 结构
struct GetProfileData: Codable {
    let _id: String
    let nickname: String
    let avatar: String
    let phone_number: String?
    let created_at: Double?

    func toUser() -> User {
        let created = created_at.map { Date(timeIntervalSince1970: $0) } ?? Date()
        let phone = phone_number?.replacingOccurrences(of: "+86 ", with: "")
        return User(id: _id, phoneNumber: phone, nickname: nickname, avatar: avatar, createdAt: created)
    }
}

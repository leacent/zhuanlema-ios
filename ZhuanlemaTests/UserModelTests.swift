/**
 * User 模型单元测试
 *
 * 覆盖场景：
 * 1. 从 CloudBaseUser 转换
 * 2. 默认值处理（昵称、头像）
 * 3. 手机号格式清理
 */
import XCTest
@testable import Zhuanlema

final class UserModelTests: XCTestCase {

    func test_from_cloudbase_user_with_full_data() {
        let cbUser = CloudBaseUser(
            uid: "uid-123",
            nickname: "测试用户",
            avatar: "https://example.com/avatar.png",
            email: "test@example.com",
            phone_number: "+86 13800138000",
            created_at: 1700000000,
            updated_at: 1700000001
        )

        let user = User(from: cbUser)

        XCTAssertEqual(user.id, "uid-123")
        XCTAssertEqual(user.nickname, "测试用户")
        XCTAssertEqual(user.avatar, "https://example.com/avatar.png")
        XCTAssertEqual(user.phoneNumber, "13800138000")
    }

    func test_from_cloudbase_user_with_nil_nickname_uses_uid_prefix() {
        let cbUser = CloudBaseUser(
            uid: "abcd-efgh",
            nickname: nil,
            avatar: nil,
            email: nil,
            phone_number: nil,
            created_at: nil,
            updated_at: nil
        )

        let user = User(from: cbUser)

        XCTAssertEqual(user.nickname, "用户abcd")
    }

    func test_from_cloudbase_user_with_nil_avatar_uses_empty_string() {
        let cbUser = CloudBaseUser(
            uid: "uid-123",
            nickname: "昵称",
            avatar: nil,
            email: nil,
            phone_number: nil,
            created_at: nil,
            updated_at: nil
        )

        let user = User(from: cbUser)

        XCTAssertEqual(user.avatar, "")
    }

    func test_user_codable_roundtrip() throws {
        let user = User(
            id: "uid-1",
            phoneNumber: "13800138000",
            nickname: "小明",
            avatar: "https://example.com/a.png",
            createdAt: Date(timeIntervalSince1970: 1700000000)
        )

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        XCTAssertEqual(decoded.id, user.id)
        XCTAssertEqual(decoded.nickname, user.nickname)
        XCTAssertEqual(decoded.avatar, user.avatar)
        XCTAssertEqual(decoded.phoneNumber, user.phoneNumber)
    }
}

/**
 * 用户数据仓库
 * 使用 CloudBase 身份认证模块
 */
import Foundation

class UserRepository {
    /// 使用计算属性访问单例，避免存储强引用导致 @MainActor 类析构时内存错误
    private var authService: CloudBaseAuthService { CloudBaseAuthService.shared }
    private var databaseService: CloudBaseDatabaseService { CloudBaseDatabaseService.shared }
    private let keychain = KeychainService.shared

    private static let tokenKey = "userAccessToken"
    
    // MARK: - 短信验证码登录
    
    /**
     * 发送短信验证码
     *
     * @param phoneNumber 手机号
     * @returns verification_id, expires_in, is_user
     */
    func sendSMSVerification(phoneNumber: String) async throws -> (verificationId: String, expiresIn: Int, isUser: Bool) {
        return try await authService.sendSMSVerification(phoneNumber: phoneNumber)
    }
    
    /**
     * 短信验证码登录
     *
     * @param phoneNumber 手机号
     * @param verificationId 验证码 ID
     * @param verificationCode 验证码
     * @returns 用户信息和访问令牌
     */
    func signInWithSMS(phoneNumber: String, verificationId: String, verificationCode: String) async throws -> (user: User, accessToken: String) {
        let result = try await authService.signInWithSMS(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
            verificationCode: verificationCode
        )
        
        // 保存 token 到 Keychain（安全存储）
        keychain.set(result.accessToken, forKey: Self.tokenKey)
        var user = User(from: result.user)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        // 拉取后台资料（新用户会创建 users 文档，含 AI 昵称 + 随机头像）；用本次登录的手机号写入 users 表
        let phoneForSync = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+86", with: "").trimmingCharacters(in: .whitespaces)
        var refreshed: User?
        refreshed = try? await databaseService.getProfile(accessToken: result.accessToken, phoneNumberForNewUser: phoneForSync.isEmpty ? nil : phoneForSync)
        if refreshed == nil {
            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshed = try? await databaseService.getProfile(accessToken: result.accessToken, phoneNumberForNewUser: phoneForSync.isEmpty ? nil : phoneForSync)
        }
        if let refreshed = refreshed {
            user = refreshed
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            let existingPhone = (refreshed.phoneNumber ?? "").trimmingCharacters(in: .whitespaces)
            if existingPhone.isEmpty && !phoneForSync.isEmpty {
                try? await databaseService.updateProfile(nickname: nil, avatar: nil, phoneNumber: phoneForSync, accessToken: result.accessToken)
            }
        }
        return (user, result.accessToken)
    }
    
    // MARK: - 用户信息管理
    
    /**
     * 获取当前用户
     *
     * @returns 当前登录的用户信息
     */
    func getCurrentUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
    
    /**
     * 获取当前访问令牌
     *
     * @returns 当前用户的访问令牌
     */
    func getCurrentAccessToken() -> String? {
        return keychain.get(forKey: Self.tokenKey)
    }
    
    /**
     * 登出
     */
    func logout() {
        keychain.delete(forKey: Self.tokenKey)
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    /**
     * 检查是否已登录
     *
     * @returns 登录状态
     */
    func isLoggedIn() -> Bool {
        return getCurrentAccessToken() != nil && getCurrentUser() != nil
    }
    
    // MARK: - 资料拉取与更新（云函数 getProfile / updateProfile / uploadAvatar）
    
    /**
     * 更新资料（昵称、头像）并刷新本地缓存
     * 若 token 过期会清除本地登录态并抛出 sessionExpired
     */
    func updateProfile(nickname: String?, avatar: String?) async throws {
        guard let token = getCurrentAccessToken() else {
            throw UserRepositoryError.notLoggedIn
        }
        do {
            try await databaseService.updateProfile(nickname: nickname, avatar: avatar, accessToken: token)
            let user = try await databaseService.getProfile(accessToken: token)
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
        } catch {
            if isTokenExpiredError(error) {
                logout()
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
                throw UserRepositoryError.sessionExpired
            }
            throw error
        }
    }

    /**
     * 从后台拉取最新资料并更新本地
     * 若 token 过期会清除登录态并抛出 sessionExpired
     */
    func refreshProfile() async throws -> User {
        guard let token = getCurrentAccessToken() else {
            throw UserRepositoryError.notLoggedIn
        }
        do {
            let user = try await databaseService.getProfile(accessToken: token)
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            return user
        } catch {
            if isTokenExpiredError(error) {
                logout()
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
                throw UserRepositoryError.sessionExpired
            }
            throw error
        }
    }

    /// 判断是否为 token 过期类错误（含 access token expire / 401 等）
    private func isTokenExpiredError(_ error: Error) -> Bool {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("expire") || msg.contains("token") && msg.contains("invalid") {
            return true
        }
        let nserror = error as NSError
        return nserror.domain == "CloudBaseHTTPClient" && nserror.code == 401
    }
}

/// 用户仓库错误
enum UserRepositoryError: LocalizedError {
    case userNotFound
    case notLoggedIn
    /// 访问令牌已过期，需重新登录
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "用户不存在"
        case .notLoggedIn: return "请先登录"
        case .sessionExpired: return "登录已过期，请重新登录"
        }
    }
}

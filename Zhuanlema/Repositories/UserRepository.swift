/**
 * 用户数据仓库
 * 使用 CloudBase 身份认证模块
 */
import Foundation

class UserRepository {
    private let authService = CloudBaseAuthService.shared
    private let databaseService = CloudBaseDatabaseService.shared
    
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
        
        // 保存 token，先写入 auth 用户以便立即可用
        UserDefaults.standard.set(result.accessToken, forKey: "userAccessToken")
        var user = User(from: result.user)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        // 拉取后台资料（新用户会创建 users 文档）；用本次登录的手机号写入 users 表（Auth 返回的 user 可能不含 phone_number）
        let phoneForSync = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+86", with: "").trimmingCharacters(in: .whitespaces)
        if let refreshed = try? await databaseService.getProfile(accessToken: result.accessToken, phoneNumberForNewUser: phoneForSync.isEmpty ? nil : phoneForSync) {
            user = refreshed
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            // 老用户补写手机号：若后台资料无 phone_number 且本地有手机号，调用 updateProfile 补写
            let existingPhone = (refreshed.phoneNumber ?? "").trimmingCharacters(in: .whitespaces)
            if existingPhone.isEmpty && !phoneForSync.isEmpty {
                try? await databaseService.updateProfile(nickname: nil, avatar: nil, phoneNumber: phoneForSync, accessToken: result.accessToken)
            }
        }
        return (user, result.accessToken)
    }
    
    // MARK: - 微信授权登录
    
    /**
     * 生成微信授权页 URL
     *
     * @param redirectUri 重定向 URI
     * @param state 自定义状态标识
     * @returns 授权页 URL
     */
    func genWeChatRedirectUri(redirectUri: String, state: String) async throws -> String {
        return try await authService.genWeChatRedirectUri(redirectUri: redirectUri, state: state)
    }
    
    /**
     * 获取微信授权 Token
     *
     * @param providerCode 微信授权返回的 code
     * @param redirectUri 重定向 URI
     * @returns provider_token
     */
    func grantWeChatToken(providerCode: String, redirectUri: String) async throws -> String {
        return try await authService.grantWeChatToken(providerCode: providerCode, redirectUri: redirectUri)
    }
    
    /**
     * 微信登录
     *
     * @param providerToken 微信授权 Token
     * @returns 用户信息和访问令牌
     */
    func signInWithWeChat(providerToken: String) async throws -> (user: User, accessToken: String) {
        do {
            let result = try await authService.signInWithWeChat(providerToken: providerToken)
            UserDefaults.standard.set(result.accessToken, forKey: "userAccessToken")
            var user = User(from: result.user)
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            // 拉取后台资料（新用户会拿到随机头像和昵称）并更新本地
            if let refreshed = try? await refreshProfile() {
                user = refreshed
            }
            return (user, result.accessToken)
        } catch CloudBaseAuthError.userNotFound {
            // 用户不存在，需要先注册
            throw UserRepositoryError.userNotFound
        }
    }
    
    /**
     * 绑定微信账号（首次微信登录时使用）
     *
     * @param providerToken 微信授权 Token
     * @param accessToken 当前用户的访问令牌
     */
    func bindWeChatProvider(providerToken: String, accessToken: String) async throws {
        try await authService.bindWeChatProvider(providerToken: providerToken, accessToken: accessToken)
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
        return UserDefaults.standard.string(forKey: "userAccessToken")
    }
    
    /**
     * 登出
     */
    func logout() {
        UserDefaults.standard.removeObject(forKey: "userAccessToken")
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

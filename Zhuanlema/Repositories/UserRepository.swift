/**
 * 用户数据仓库
 * 使用 CloudBase 身份认证模块
 */
import Foundation

class UserRepository {
    private let authService = CloudBaseAuthService.shared
    
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
        
        // 转换为 User 模型
        let user = User(from: result.user)
        
        // 保存用户信息和 token 到本地
        UserDefaults.standard.set(result.accessToken, forKey: "userAccessToken")
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
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
            let user = User(from: result.user)
            
            // 保存用户信息和 token 到本地
            UserDefaults.standard.set(result.accessToken, forKey: "userAccessToken")
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
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
}

/// 用户仓库错误
enum UserRepositoryError: Error {
    case userNotFound
}

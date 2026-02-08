/**
 * CloudBase 身份认证服务
 * 使用 CloudBase 官方身份认证模块实现登录功能
 * 支持：短信验证码登录（用户不存在时自动注册）
 */
import Foundation

class CloudBaseAuthService {
    static let shared = CloudBaseAuthService()
    
    private init() {}
    
    // MARK: - 短信验证码登录
    
    /**
     * 发送短信验证码
     * POST /auth/v1/verification
     *
     * @param phoneNumber 手机号（需要 +86 前缀）
     * @returns verification_id 和 expires_in
     */
    func sendSMSVerification(phoneNumber: String) async throws -> (verificationId: String, expiresIn: Int, isUser: Bool) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        
        // 格式化手机号：添加 +86 前缀
        let formattedPhone = phoneNumber.hasPrefix("+86") ? phoneNumber : "+86 \(phoneNumber)"
        
        let url = URL(string: "\(CloudBaseConfig.baseURL)/auth/v1/verification")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(CloudBaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "phone_number": formattedPhone,
            "target": "ANY"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔄 [CloudBaseAuth] 发送短信验证码: \(formattedPhone)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        
        if statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ [CloudBaseAuth] 发送验证码失败 HTTP \(statusCode): \(errorBody)")
            throw NSError(domain: "CloudBaseAuthService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "发送验证码失败"])
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(SMSVerificationResponse.self, from: data)
        
        print("✅ [CloudBaseAuth] 验证码发送成功，verificationId=\(result.verification_id), isUser=\(result.is_user ?? false)")
        return (result.verification_id, result.expires_in, result.is_user ?? false)
    }
    
    /**
     * 验证短信验证码并登录
     * POST /auth/v1/verification/verify
     * 然后 POST /auth/v1/signin
     *
     * @param phoneNumber 手机号
     * @param verificationId 验证码 ID
     * @param verificationCode 用户输入的验证码
     * @returns 用户信息和访问令牌
     */
    func signInWithSMS(phoneNumber: String, verificationId: String, verificationCode: String) async throws -> (user: CloudBaseUser, accessToken: String) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        
        let formattedPhone = phoneNumber.hasPrefix("+86") ? phoneNumber : "+86 \(phoneNumber)"
        
        // 第一步：验证验证码
        let verifyUrl = URL(string: "\(CloudBaseConfig.baseURL)/auth/v1/verification/verify")!
        var verifyRequest = URLRequest(url: verifyUrl)
        verifyRequest.httpMethod = "POST"
        verifyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        verifyRequest.setValue("Bearer \(CloudBaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        
        let verifyBody: [String: Any] = [
            "verification_id": verificationId,
            "verification_code": verificationCode
        ]
        verifyRequest.httpBody = try JSONSerialization.data(withJSONObject: verifyBody)
        
        print("🔄 [CloudBaseAuth] 验证验证码...")
        
        let (verifyData, verifyResponse) = try await URLSession.shared.data(for: verifyRequest)
        let verifyHttpResponse = verifyResponse as? HTTPURLResponse
        let verifyStatusCode = verifyHttpResponse?.statusCode ?? -1
        
        if verifyStatusCode != 200 {
            let errorBody = String(data: verifyData, encoding: .utf8) ?? ""
            print("❌ [CloudBaseAuth] 验证码验证失败 HTTP \(verifyStatusCode): \(errorBody)")
            throw NSError(domain: "CloudBaseAuthService", code: verifyStatusCode, userInfo: [NSLocalizedDescriptionKey: "验证码错误或已过期"])
        }
        
        // 打印原始响应以便调试
        let verifyResponseString = String(data: verifyData, encoding: .utf8) ?? ""
        print("📋 [CloudBaseAuth] 验证码验证响应原始数据: \(verifyResponseString)")
        
        let verifyDecoder = JSONDecoder()
        let verifyResult = try verifyDecoder.decode(VerificationVerifyResponse.self, from: verifyData)
        
        // 第二步：使用 verification_token 登录
        let signInUrl = URL(string: "\(CloudBaseConfig.baseURL)/auth/v1/signin")!
        var signInRequest = URLRequest(url: signInUrl)
        signInRequest.httpMethod = "POST"
        signInRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        signInRequest.setValue("Bearer \(CloudBaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        
        let signInBody: [String: Any] = [
            "verification_token": verifyResult.verification_token,
            "phone_number": formattedPhone
        ]
        signInRequest.httpBody = try JSONSerialization.data(withJSONObject: signInBody)
        
        print("🔄 [CloudBaseAuth] 执行登录...")
        
        let (signInData, signInResponse) = try await URLSession.shared.data(for: signInRequest)
        let signInHttpResponse = signInResponse as? HTTPURLResponse
        let signInStatusCode = signInHttpResponse?.statusCode ?? -1
        
        if signInStatusCode != 200 {
            let errorBody = String(data: signInData, encoding: .utf8) ?? ""
            // User not exist (404) → auto register then continue
            if signInStatusCode == 404, isUserNotExistError(signInData) {
                print("🔄 [CloudBaseAuth] 用户不存在，自动注册...")
                return try await signUpWithSMS(
                    verificationToken: verifyResult.verification_token,
                    phoneNumber: formattedPhone
                )
            }
            print("❌ [CloudBaseAuth] 登录失败 HTTP \(signInStatusCode): \(errorBody)")
            throw NSError(domain: "CloudBaseAuthService", code: signInStatusCode, userInfo: [NSLocalizedDescriptionKey: "登录失败"])
        }
        
        return try parseSignInResponse(signInData, formattedPhone: formattedPhone, logPrefix: "登录")
    }
    
    /// 判断错误响应是否为「用户不存在」
    private func isUserNotExistError(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        let error = (json["error"] as? String) ?? ""
        let code = json["error_code"] as? Int
        let desc = (json["error_description"] as? String) ?? ""
        return error == "not_found" || code == 5 || desc.contains("User not exist")
    }
    
    /**
     * 短信验证码注册（新用户）
     * POST /auth/v1/signup
     */
    private func signUpWithSMS(verificationToken: String, phoneNumber: String) async throws -> (user: CloudBaseUser, accessToken: String) {
        let url = URL(string: "\(CloudBaseConfig.baseURL)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(CloudBaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "verification_token": verificationToken,
            "phone_number": phoneNumber
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔄 [CloudBaseAuth] 执行注册...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        
        guard statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            print("❌ [CloudBaseAuth] 注册失败 HTTP \(statusCode): \(errorBody)")
            throw NSError(domain: "CloudBaseAuthService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "注册失败"])
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? ""
        print("📋 [CloudBaseAuth] 注册响应原始数据: \(responseString)")
        
        return try parseSignInResponse(data, formattedPhone: phoneNumber, logPrefix: "注册")
    }
    
    private func parseSignInResponse(_ data: Data, formattedPhone: String, logPrefix: String) throws -> (user: CloudBaseUser, accessToken: String) {
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let decoder = JSONDecoder()
        let signInResult: SignInResponse
        do {
            signInResult = try decoder.decode(SignInResponse.self, from: data)
        } catch {
            print("❌ [CloudBaseAuth] \(logPrefix)响应 JSON 解码失败: \(error)")
            print("📋 [CloudBaseAuth] 响应数据: \(responseString)")
            throw NSError(
                domain: "CloudBaseAuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "\(logPrefix)响应格式错误: \(error.localizedDescription)"]
            )
        }
        
        let userId: String
        if let sub = signInResult.sub, !sub.isEmpty {
            userId = sub
        } else if let userUid = signInResult.user?.uid {
            userId = userUid
        } else {
            throw NSError(
                domain: "CloudBaseAuthService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "响应中缺少用户ID"]
            )
        }
        
        let user: CloudBaseUser
        if let existingUser = signInResult.user {
            user = existingUser
        } else {
            user = CloudBaseUser(
                uid: userId,
                nickname: nil,
                avatar: nil,
                email: nil,
                phone_number: formattedPhone,
                created_at: nil,
                updated_at: nil
            )
        }
        
        print("✅ [CloudBaseAuth] \(logPrefix)成功，userId=\(userId)")
        return (user, signInResult.access_token)
    }
    
}

// MARK: - 响应数据结构

/// 短信验证码响应
private struct SMSVerificationResponse: Codable {
    let verification_id: String
    let expires_in: Int
    let is_user: Bool?
}

/// 验证码验证响应
private struct VerificationVerifyResponse: Codable {
    let verification_token: String
}

/// 登录响应（匹配 CloudBase 实际 API 响应格式）
private struct SignInResponse: Codable {
    let token_type: String?
    let access_token: String
    let refresh_token: String?
    let id_token: String?
    let expires_in: Int?
    let scope: String?
    let sub: String?  // 用户ID（可能在某些情况下为空）
    let groups: [String]?
    let need_weda_resource: Bool?
    
    // 兼容旧格式：如果响应中包含 user 对象
    let user: CloudBaseUser?
    
    enum CodingKeys: String, CodingKey {
        case token_type
        case access_token
        case refresh_token
        case id_token
        case expires_in
        case scope
        case sub
        case groups
        case need_weda_resource
        case user
    }
}

/// CloudBase 用户信息
struct CloudBaseUser: Codable {
    let uid: String
    let nickname: String?
    let avatar: String?
    let email: String?
    let phone_number: String?
    let created_at: Int64?
    let updated_at: Int64?
}


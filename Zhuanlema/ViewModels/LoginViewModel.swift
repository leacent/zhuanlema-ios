/**
 * 登录视图模型
 * 支持短信验证码登录和微信授权登录
 */
import Foundation
import Combine
import UIKit

@MainActor
class LoginViewModel: ObservableObject {
    /// 手机号
    @Published var phoneNumber: String = ""
    /// 验证码
    @Published var verificationCode: String = ""
    /// 是否正在加载
    @Published var isLoading: Bool = false
    /// 错误消息
    @Published var errorMessage: String?
    /// 倒计时秒数
    @Published var countdown: Int = 0
    /// 是否登录成功
    @Published var isLoggedIn: Bool = false
    /// 是否已发送验证码
    @Published var codeSent: Bool = false
    /// 验证码 ID（用于登录）
    @Published var verificationId: String?
    
    private let userRepository = UserRepository()
    private var countdownTimer: Timer?
    
    /// 手机号格式是否正确
    var isPhoneNumberValid: Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    /// 验证码格式是否正确
    var isCodeValid: Bool {
        return verificationCode.count == 6 && verificationCode.allSatisfy { $0.isNumber }
    }
    
    /// 是否可以发送验证码
    var canSendCode: Bool {
        return isPhoneNumberValid && countdown == 0 && !isLoading
    }
    
    /// 是否可以登录
    var canLogin: Bool {
        return isPhoneNumberValid && isCodeValid && verificationId != nil && !isLoading
    }
    
    // MARK: - 短信验证码登录
    
    /**
     * 发送短信验证码
     */
    func sendVerificationCode() {
        guard canSendCode else { return }
        
        isLoading = true
        errorMessage = nil
        verificationId = nil
        
        Task {
            do {
                let result = try await userRepository.sendSMSVerification(phoneNumber: phoneNumber)
                verificationId = result.verificationId
                codeSent = true
                startCountdown()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /**
     * 短信验证码登录
     */
    func loginWithSMS() {
        guard canLogin, let verificationId = verificationId else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await userRepository.signInWithSMS(
                    phoneNumber: phoneNumber,
                    verificationId: verificationId,
                    verificationCode: verificationCode
                )
                
                // 登录成功
                isLoggedIn = true
                
                // 发送登录成功通知
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    // MARK: - 微信授权登录
    
    /**
     * 微信登录
     */
    func loginWithWeChat() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 生成重定向 URI（iOS 使用 URL Scheme）
                let redirectUri = "zhuanlema://wechat/callback"
                let state = UUID().uuidString
                
                // 生成授权页 URL
                let authUrl = try await userRepository.genWeChatRedirectUri(
                    redirectUri: redirectUri,
                    state: state
                )
                
                // 打开微信授权页（需要在 Info.plist 配置 URL Scheme）
                if let url = URL(string: authUrl) {
                    await UIApplication.shared.open(url)
                } else {
                    throw NSError(domain: "LoginViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法打开授权页"])
                }
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    /**
     * 处理微信授权回调
     * 从 URL Scheme 回调中获取 code 和 state
     */
    func handleWeChatCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            errorMessage = "授权回调参数错误"
            isLoading = false
            return
        }
        
        var code: String?
        var state: String?
        
        for item in queryItems {
            if item.name == "code" {
                code = item.value
            } else if item.name == "state" {
                state = item.value
            }
        }
        
        guard let providerCode = code else {
            errorMessage = "未获取到授权码"
            isLoading = false
            return
        }
        
        Task {
            do {
                // 获取微信授权 Token
                let redirectUri = "zhuanlema://wechat/callback"
                let providerToken = try await userRepository.grantWeChatToken(
                    providerCode: providerCode,
                    redirectUri: redirectUri
                )
                
                // 使用 Token 登录
                do {
                    let result = try await userRepository.signInWithWeChat(providerToken: providerToken)
                    
                    // 登录成功
                    isLoggedIn = true
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                } catch UserRepositoryError.userNotFound {
                    // 用户不存在，需要先注册（使用短信验证码注册）
                    errorMessage = "首次使用微信登录，请先使用手机号注册"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    /**
     * 开始倒计时
     */
    private func startCountdown() {
        countdown = 60
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                }
            }
        }
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
}

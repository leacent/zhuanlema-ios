/**
 * 登录视图模型
 * 支持短信验证码登录，用户不存在时自动注册
 */
import Foundation
import Combine

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
    private var countdownTask: Task<Void, Never>?
    
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
    
    /**
     * 开始倒计时（使用 Task 替代 Timer，避免 @MainActor deinit 内存问题）
     */
    private func startCountdown() {
        countdown = 60
        
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while let self, self.countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self.countdown -= 1
            }
        }
    }
    
    deinit {
        countdownTask?.cancel()
    }
}

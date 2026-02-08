/**
 * 登录界面
 * 支持短信验证码登录，用户不存在时自动注册
 */
import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    
    /// 是否作为弹窗展示（可选绑定，用于关闭弹窗）
    @Binding var isPresented: Bool
    
    enum Field {
        case phoneNumber
        case verificationCode
    }
    
    /// 默认初始化（非弹窗模式）
    init() {
        self._isPresented = .constant(true)
    }
    
    /// 弹窗模式初始化
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 关闭按钮（弹窗模式）
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo 和标题
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                            
                            Text("赚了吗")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                            
                            Text("轻量级投资交易社区")
                                .font(.system(size: 16))
                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        }
                        .padding(.top, 20)
                        
                        // 登录表单
                        VStack(spacing: 20) {
                            // 手机号输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("手机号")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                                
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                    
                                    TextField("请输入手机号", text: $viewModel.phoneNumber)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .phoneNumber)
                                        .onChange(of: viewModel.phoneNumber) { oldValue, newValue in
                                            if newValue.count > 11 {
                                                viewModel.phoneNumber = String(newValue.prefix(11))
                                            }
                                        }
                                }
                                .padding()
                                .background(Color(uiColor: ColorPalette.bgSecondary))
                                .cornerRadius(12)
                            }
                            
                            // 验证码输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("验证码")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                                
                                HStack {
                                    Image(systemName: "number.circle.fill")
                                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                    
                                    TextField("请输入验证码", text: $viewModel.verificationCode)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .verificationCode)
                                        .onChange(of: viewModel.verificationCode) { oldValue, newValue in
                                            if newValue.count > 6 {
                                                viewModel.verificationCode = String(newValue.prefix(6))
                                            }
                                        }
                                    
                                    Divider()
                                        .frame(height: 24)
                                    
                                    Button(action: viewModel.sendVerificationCode) {
                                        if viewModel.countdown > 0 {
                                            Text("\(viewModel.countdown)s")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                                        } else {
                                            Text("获取验证码")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                        }
                                    }
                                    .disabled(!viewModel.canSendCode)
                                }
                                .padding()
                                .background(Color(uiColor: ColorPalette.bgSecondary))
                                .cornerRadius(12)
                            }
                            
                            // 错误提示
                            if let errorMessage = viewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(errorMessage)
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(Color(uiColor: ColorPalette.error))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: SemanticColors.alertErrorBackground))
                                .cornerRadius(8)
                            }
                            
                            // 短信验证码登录按钮
                            Button(action: {
                                viewModel.loginWithSMS()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("登录")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.canLogin ? Color(uiColor: ColorPalette.brandPrimary) : Color(uiColor: ColorPalette.textDisabled))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.canLogin)
                            
                            // 提示文字
                            Text("登录即同意用户协议和隐私政策")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: viewModel.isLoggedIn) { oldValue, newValue in
            if newValue {
                // 登录成功，刷新状态并关闭弹窗
                appState.checkLoginStatus()
                isPresented = false
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}

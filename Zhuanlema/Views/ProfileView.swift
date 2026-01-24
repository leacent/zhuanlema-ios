/**
 * 个人中心页面
 * 未登录时显示登录入口，已登录时显示用户信息
 */
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    @State private var showLoginSheet = false
    
    private let userRepository = UserRepository()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()
                
                if appState.isLoggedIn {
                    // 已登录 - 显示用户信息
                    loggedInView
                } else {
                    // 未登录 - 显示登录入口
                    notLoggedInView
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .alert("确认退出", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("退出", role: .destructive) {
                    logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView(isPresented: $showLoginSheet)
                    .environmentObject(appState)
            }
        }
    }
    
    /// 未登录视图
    private var notLoggedInView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo
            ZStack {
                Circle()
                    .fill(Color(uiColor: ColorPalette.brandPrimary).opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            }
            
            // 标题
            VStack(spacing: 8) {
                Text("赚了吗")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Text("登录后可发布心得、参与评论")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
            
            // 登录按钮
            Button(action: {
                showLoginSheet = true
            }) {
                Text("登录 / 注册")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: ColorPalette.brandPrimary))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // 提示文字
            Text("登录即同意用户协议和隐私政策")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    /// 已登录视图
    private var loggedInView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 用户信息卡片
                if let user = userRepository.getCurrentUser() {
                    VStack(spacing: 16) {
                        // 头像
                        Circle()
                            .fill(Color(uiColor: ColorPalette.brandPrimary))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(user.nickname.prefix(1)))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        // 昵称
                        Text(user.nickname)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                        
                        // 手机号（部分隐藏）
                        if let phoneNumber = user.phoneNumber {
                            Text(maskPhoneNumber(phoneNumber))
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(16)
                }
                
                // 统计信息
                HStack(spacing: 1) {
                    StatItem(title: "打卡", value: "-")
                    StatItem(title: "帖子", value: "-")
                    StatItem(title: "点赞", value: "-")
                }
                .background(Color(uiColor: ColorPalette.bgSecondary))
                .cornerRadius(12)
                
                // 功能列表
                VStack(spacing: 1) {
                    SettingRow(icon: "person.circle", title: "编辑资料", showArrow: true) {
                        // TODO: 编辑资料
                    }
                    
                    SettingRow(icon: "bell", title: "消息通知", showArrow: true) {
                        // TODO: 消息通知
                    }
                    
                    SettingRow(icon: "gear", title: "设置", showArrow: true) {
                        // TODO: 设置
                    }
                    
                    SettingRow(icon: "questionmark.circle", title: "帮助与反馈", showArrow: true) {
                        // TODO: 帮助与反馈
                    }
                }
                .background(Color(uiColor: ColorPalette.bgSecondary))
                .cornerRadius(12)
                
                // 登出按钮
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Text("退出登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.error))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: ColorPalette.bgSecondary))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
    }
    
    /**
     * 隐藏手机号中间四位
     */
    private func maskPhoneNumber(_ phoneNumber: String) -> String {
        guard phoneNumber.count == 11 else { return phoneNumber }
        let prefix = phoneNumber.prefix(3)
        let suffix = phoneNumber.suffix(4)
        return "\(prefix)****\(suffix)"
    }
    
    /**
     * 登出
     */
    private func logout() {
        appState.logout()
    }
}

/// 统计项
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

/// 设置行
struct SettingRow: View {
    let icon: String
    let title: String
    let showArrow: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Spacer()
                
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

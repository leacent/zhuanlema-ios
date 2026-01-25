/**
 * 个人中心页面
 * 未登录时显示登录入口，已登录时显示用户信息
 */
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutAlert = false
    @State private var showLoginSheet = false
    @State private var profileStats: UserProfileStats?
    @State private var statsLoading = false
    @State private var showEditProfile = false
    /// 展示用用户（与 UserDefaults 同步；编辑或切回本 Tab 时显式更新，保证 UI 刷新）
    @State private var displayedUser: User?
    /// 编辑资料保存后递增，用于强制头像/昵称视图重绘
    @State private var profileRefreshId = 0
    
    private let userRepository = UserRepository()
    private let databaseService = CloudBaseDatabaseService.shared

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
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
            .navigationBarHidden(true)
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
            .sheet(isPresented: $showEditProfile, onDismiss: {
                // 兜底刷新：关闭弹窗后再拉一次资料并更新展示用户
                Task {
                    if let u = try? await userRepository.refreshProfile() {
                        await MainActor.run {
                            displayedUser = u
                            profileRefreshId += 1
                        }
                    }
                }
            }) {
                if let user = displayedUser ?? userRepository.getCurrentUser() {
                    EditProfileView(initialUser: user, onSaved: { updated in
                        await MainActor.run {
                            displayedUser = updated
                            profileRefreshId += 1
                        }
                    })
                }
            }
            .task(id: appState.isLoggedIn) {
                if appState.isLoggedIn {
                    displayedUser = userRepository.getCurrentUser()
                } else {
                    displayedUser = nil
                }
            }
            .onAppear {
                // 切回「我的」Tab 时拉取最新资料，保证与其他端或编辑后的数据一致
                if appState.isLoggedIn {
                    Task {
                        if let u = try? await userRepository.refreshProfile() {
                            await MainActor.run { displayedUser = u }
                        }
                    }
                }
            }
        }
    }
    
    /// 未登录视图
    private var notLoggedInView: some View {
        VStack(spacing: 0) {
            // 品牌背景：固定高度并顶部对齐，保证副标题在渐变区内可见
            ZStack(alignment: .top) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(uiColor: ColorPalette.brandPrimary),
                        Color(uiColor: ColorPalette.brandSecondary)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 320)
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("赚了吗")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("聪明的投资小伙伴")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 320)
            
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Text("登录后可发布心得、参与评论")
                        .font(.system(size: 15))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    
                    // 登录按钮
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        Text("登录 / 注册")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(uiColor: ColorPalette.brandPrimary),
                                        Color(uiColor: ColorPalette.brandSecondary)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 提示文字
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    Text("登录即同意用户协议和隐私政策")
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
                .font(.system(size: 12))
                .padding(.bottom, 40)
            }
            .padding(.top, 24)
        }
    }
    
    /// 已登录视图
    private var loggedInView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 1. 品牌渐变头部
                ZStack(alignment: .bottom) {
                    // 渐变背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(uiColor: ColorPalette.brandPrimary),
                            Color(uiColor: ColorPalette.brandSecondary)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)
                    
                    // 用户信息内容（使用 displayedUser，编辑或切回 Tab 时已更新）
                    if let user = displayedUser {
                        VStack(spacing: 12) {
                            // 头像
                            avatarView(user: user)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(user.nickname)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if let phoneNumber = user.phoneNumber {
                                    Text(maskPhoneNumber(phoneNumber))
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .id(profileRefreshId)
                        .padding(.bottom, 60) // 为下方悬浮统计卡片留出空间
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                VStack(spacing: 24) {
                    // 2. 悬浮统计信息卡片（点击打卡进入日历页）
                    HStack(spacing: 0) {
                        NavigationLink(destination: CheckInCalendarView()) {
                            StatItem(title: "打卡", value: statsDisplayValue(for: \.checkInCount), icon: "calendar.badge.checkmark")
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider().frame(height: 30).background(Color(uiColor: ColorPalette.border))
                        StatItem(title: "帖子", value: statsDisplayValue(for: \.postCount), icon: "doc.text.fill")
                        Divider().frame(height: 30).background(Color(uiColor: ColorPalette.border))
                        StatItem(title: "点赞", value: statsDisplayValue(for: \.totalLikeCount), icon: "heart.fill")
                    }
                    .padding(.vertical, 20)
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .offset(y: -40) // 向上偏移形成悬浮效果
                    .task(id: appState.isLoggedIn) {
                        await loadProfileStats()
                    }
                    
                    // 3. 功能列表
                    VStack(spacing: 0) {
                        SettingRow(icon: "person.fill", title: "编辑资料", showArrow: true, color: .blue) {
                            showEditProfile = true
                        }
                        
                        Divider().padding(.leading, 56)
                        
                        NavigationLink(destination: NotificationsView()) {
                            SettingRowContent(icon: "bell.fill", title: "消息通知", showArrow: true, color: .orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 56)
                        
                        NavigationLink(destination: SettingsView()) {
                            SettingRowContent(icon: "gearshape.fill", title: "设置", showArrow: true, color: .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 56)
                        
                        NavigationLink(destination: HelpAndFeedbackView()) {
                            SettingRowContent(icon: "questionmark.circle.fill", title: "帮助与反馈", showArrow: true, color: .green)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    .offset(y: -24)
                    
                    // 4. 登出按钮
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("退出登录")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color(uiColor: ColorPalette.error))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: ColorPalette.bgSecondary))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .offset(y: -12)
                }
            }
        }
        .background(Color(uiColor: ColorPalette.bgPrimary))
    }
    
    /// 头像视图：云函数返回的 avatar 就是可用的 URL（或空），直接用来展示
    private func avatarView(user: User) -> some View {
        Group {
            if !user.avatar.isEmpty, let url = URL(string: user.avatar) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        avatarPlaceholder(nickname: user.nickname)
                    @unknown default:
                        avatarPlaceholder(nickname: user.nickname)
                    }
                }
            } else {
                avatarPlaceholder(nickname: user.nickname)
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 3))
        .id(profileRefreshId)
    }
    
    /**
     * 统计项显示值：有数据显示数字，否则显示 "-"
     */
    private func statsDisplayValue(for keyPath: KeyPath<UserProfileStats, Int>) -> String {
        if statsLoading { return "..." }
        guard let stats = profileStats else { return "-" }
        return "\(stats[keyPath: keyPath])"
    }
    
    /**
     * 加载用户统计（已登录时）
     */
    private func loadProfileStats() async {
        guard appState.isLoggedIn, let userId = displayedUser?.id ?? userRepository.getCurrentUser()?.id else {
            profileStats = nil
            return
        }
        statsLoading = true
        defer { statsLoading = false }
        do {
            profileStats = try await databaseService.getUserStats(userId: userId)
        } catch {
            profileStats = nil
        }
    }
    
    /// 头像占位：圆形背景 + 昵称首字
    private func avatarPlaceholder(nickname: String) -> some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: ColorPalette.brandPrimary))
            
            Text(String(nickname.prefix(1)))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
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
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary).opacity(0.7))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
        .frame(maxWidth: .infinity)
    }
}

/// 设置行内容（图标 + 标题 + 箭头），供 Button 或 NavigationLink 使用
struct SettingRowContent: View {
    let icon: String
    let title: String
    let showArrow: Bool
    var color: Color = Color(uiColor: ColorPalette.brandPrimary)
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标背景
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            
            Spacer()
            
            if showArrow {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .contentShape(Rectangle()) // 确保整行都是点击热区
    }
}

/// 设置行（可点击）
struct SettingRow: View {
    let icon: String
    let title: String
    let showArrow: Bool
    var color: Color = Color(uiColor: ColorPalette.brandPrimary)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingRowContent(icon: icon, title: title, showArrow: showArrow, color: color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

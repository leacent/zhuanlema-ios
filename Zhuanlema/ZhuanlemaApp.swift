//
//  ZhuanlemaApp.swift
//  Zhuanlema
//
//  Created by leacent song on 2026/1/24.
//

import SwiftUI
import Combine

@main
struct ZhuanlemaApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            // 根据打卡状态显示不同页面
            if appState.hasCheckedInToday {
                // 已打卡，显示主界面
                MainTabView()
                    .environmentObject(appState)
                    .onAppear {
                        setupNotifications()
                    }
            } else {
                // 未打卡，显示全屏打卡页面
                DailyCheckInView()
                    .environmentObject(appState)
                    .onAppear {
                        setupNotifications()
                    }
            }
        }
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        // 监听登录成功事件：刷新登录态并将本地打卡同步到云端（与 user 绑定）
        NotificationCenter.default.addObserver(forName: .userDidLogin, object: nil, queue: .main) { _ in
            appState.checkLoginStatus()
            appState.syncLocalCheckInsAfterLogin()
        }
        // 监听登出事件
        NotificationCenter.default.addObserver(forName: .userDidLogout, object: nil, queue: .main) { _ in
            appState.checkLoginStatus()
        }
    }
}

/**
 * App 全局状态管理
 */
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var hasCheckedInToday: Bool = false
    /// 底部 Tab 选中索引（0=社区, 1=行情, 2=我的）
    @Published var selectedMainTab: Int = 0
    
    private let userRepository = UserRepository()
    private let checkInRepository = CheckInRepository()
    
    init() {
        // 一次性迁移：将 UserDefaults 中的旧 token 迁移到 Keychain
        KeychainService.shared.migrateTokenFromUserDefaults()

        // 🔧 开发调试：清除打卡缓存
        #if DEBUG
        checkInRepository.clearLocalCheckInCache()
        #endif
        
        checkLoginStatus()
        checkTodayCheckInStatus()
    }
    
    func checkLoginStatus() {
        isLoggedIn = userRepository.isLoggedIn()
    }

    /// 登录成功后将本地打卡记录同步到数据库并与当前用户绑定
    func syncLocalCheckInsAfterLogin() {
        Task { await checkInRepository.syncLocalCheckInsToCloud() }
    }
    
    func checkTodayCheckInStatus() {
        hasCheckedInToday = checkInRepository.hasCheckedInToday()
        print("📋 检查打卡状态: hasCheckedInToday = \(hasCheckedInToday)")
    }
    
    func logout() {
        userRepository.logout()
        isLoggedIn = false
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
}

/// 通知名称
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}

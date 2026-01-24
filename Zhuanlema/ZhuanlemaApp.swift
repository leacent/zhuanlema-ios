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
        // 监听登录成功事件
        NotificationCenter.default.addObserver(forName: .userDidLogin, object: nil, queue: .main) { _ in
            appState.checkLoginStatus()
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
    
    private let userRepository = UserRepository()
    private let checkInRepository = CheckInRepository()
    
    init() {
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

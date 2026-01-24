/**
 * 主导航视图
 * 底部 TabBar 导航 - 社区（首页）+ 我的
 */
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 社区（首页）
            CommunityView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("社区")
                }
                .tag(0)
            
            // 我的
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.fill" : "person")
                    Text("我的")
                }
                .tag(1)
        }
        .accentColor(Color(uiColor: ColorPalette.brandPrimary))
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

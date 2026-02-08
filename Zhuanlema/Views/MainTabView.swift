/**
 * 主导航视图
 * 底部 TabBar 导航 - 社区（首页）+ 行情 + 我的
 */
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedMainTab) {
            // 社区（首页）
            CommunityView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: appState.selectedMainTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("社区")
                }
                .tag(0)
            
            // 行情
            MarketView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: appState.selectedMainTab == 1 ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                    Text("行情")
                }
                .tag(1)
            
            // 我的
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: appState.selectedMainTab == 2 ? "person.fill" : "person")
                    Text("我的")
                }
                .tag(2)
        }
        .accentColor(Color(uiColor: ColorPalette.brandPrimary))
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

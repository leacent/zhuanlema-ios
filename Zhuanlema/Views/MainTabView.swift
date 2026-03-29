/**
 * 主导航视图
 * 底部 TabBar 导航 - 首页 + AI 复盘 + 我的
 */
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedMainTab) {
            HomeView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: appState.selectedMainTab == 0 ? "house.fill" : "house")
                    Text("首页")
                }
                .tag(0)
            
            AITabView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: appState.selectedMainTab == 1 ? "brain.fill" : "brain")
                    Text("AI 复盘")
                }
                .tag(1)
            
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

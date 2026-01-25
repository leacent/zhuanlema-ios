/**
 * 快捷功能入口
 * 4个核心功能图标：榜单、讨论、资讯、自选
 */
import SwiftUI

struct QuickActionsView: View {
    /// 点击榜单回调
    let onRankingTap: () -> Void
    /// 点击讨论回调
    let onDiscussionTap: () -> Void
    /// 点击资讯回调
    let onNewsTap: () -> Void
    /// 点击添加自选回调
    let onAddWatchlistTap: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 涨跌榜单
            QuickActionButton(
                icon: "chart.bar.fill",
                title: "涨跌榜",
                color: Color(uiColor: ColorPalette.brandPrimary),
                action: onRankingTap
            )
            
            Spacer()
            
            // 热门讨论
            QuickActionButton(
                icon: "bubble.left.and.bubble.right.fill",
                title: "热门讨论",
                color: Color(uiColor: ColorPalette.textSecondary),
                action: onDiscussionTap
            )
            
            Spacer()
            
            // 财经资讯
            QuickActionButton(
                icon: "newspaper.fill",
                title: "财经资讯",
                color: Color(uiColor: ColorPalette.textSecondary),
                action: onNewsTap
            )
            
            Spacer()
            
            // 添加自选
            QuickActionButton(
                icon: "plus.circle.fill",
                title: "添加自选",
                color: Color(uiColor: ColorPalette.textSecondary),
                action: onAddWatchlistTap
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(12)
    }
}

/// 快捷功能按钮
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        QuickActionsView(
            onRankingTap: { print("榜单") },
            onDiscussionTap: { print("讨论") },
            onNewsTap: { print("资讯") },
            onAddWatchlistTap: { print("添加自选") }
        )
        .padding()
    }
    .background(Color(uiColor: ColorPalette.bgPrimary))
}

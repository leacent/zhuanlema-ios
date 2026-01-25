/**
 * 行情页顶部Tab选择器
 * 用于切换行情/自选两个视图
 */
import SwiftUI

struct MarketTabSelector: View {
    @Binding var selectedTab: MarketTab
    
    /// Tab指示器的动画命名空间
    @Namespace private var tabAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MarketTab.allCases) { tab in
                TabItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabAnimation,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: ColorPalette.bgSecondary))
    }
}

/// 单个Tab项
private struct TabItem: View {
    let tab: MarketTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(tab.title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ?
                        Color(uiColor: ColorPalette.brandPrimary) :
                        Color(uiColor: ColorPalette.textSecondary)
                    )
                
                // 下划线指示器
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(uiColor: ColorPalette.brandPrimary))
                            .frame(width: 24, height: 3)
                            .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clear)
                            .frame(width: 24, height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 选中行情
        MarketTabSelector(selectedTab: .constant(.market))
        
        // 选中自选
        MarketTabSelector(selectedTab: .constant(.watchlist))
    }
    .padding()
    .background(Color(uiColor: ColorPalette.bgPrimary))
}

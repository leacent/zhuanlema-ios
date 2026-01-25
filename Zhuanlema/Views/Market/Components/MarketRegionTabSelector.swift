/**
 * 行情页市场区域 Tab 选择器（A股 / 港股 / 美股）
 * 仅在「行情」Tab 下显示
 */
import SwiftUI

struct MarketRegionTabSelector: View {
    @Binding var selectedRegion: MarketRegion

    @Namespace private var regionTabAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MarketRegion.allCases) { region in
                RegionTabItem(
                    region: region,
                    isSelected: selectedRegion == region,
                    namespace: regionTabAnimation,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRegion = region
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: ColorPalette.bgPrimary))
    }
}

private struct RegionTabItem: View {
    let region: MarketRegion
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(region.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ?
                        Color(uiColor: ColorPalette.brandPrimary) :
                        Color(uiColor: ColorPalette.textSecondary)
                    )
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(uiColor: ColorPalette.brandPrimary))
                            .frame(width: 24, height: 3)
                            .matchedGeometryEffect(id: "regionTabIndicator", in: namespace)
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
    VStack(spacing: 0) {
        MarketRegionTabSelector(selectedRegion: .constant(.aShare))
        MarketRegionTabSelector(selectedRegion: .constant(.hongKong))
    }
    .padding()
    .background(Color(uiColor: ColorPalette.bgPrimary))
}

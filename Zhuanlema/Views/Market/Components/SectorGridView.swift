/**
 * 板块网格组件
 * 用于展示行业板块和概念板块
 * 2列网格布局
 */
import SwiftUI

struct SectorGridView: View {
    let title: String
    let sectors: [SectorItem]
    let isLoading: Bool
    let onSectorTap: (SectorItem) -> Void
    let onMoreTap: () -> Void
    
    /// 2列网格布局
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Spacer()
                
                Button(action: onMoreTap) {
                    HStack(spacing: 4) {
                        Text("更多")
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // 内容区
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else if sectors.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                // 网格布局
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sectors.prefix(6)) { sector in
                        SectorCard(sector: sector)
                            .onTapGesture {
                                onSectorTap(sector)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(12)
    }
}

/// 板块卡片
struct SectorCard: View {
    let sector: SectorItem
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 板块名称和涨跌幅
            HStack {
                Text(sector.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    .lineLimit(1)
                
                Spacer()
                
                Text(sector.formattedChangePercent)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(sector.isUp ?
                        Color(uiColor: ColorPalette.tradingUp) :
                        Color(uiColor: ColorPalette.tradingDown)
                    )
            }
            
            // 领涨股信息
            if !sector.leadingStock.isEmpty {
                HStack(spacing: 4) {
                    Text("领涨:")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    
                    Text(sector.leadingStock)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        .lineLimit(1)
                    
                    if let change = sector.leadingStockChange {
                        Text(String(format: "%@%.2f%%", change >= 0 ? "+" : "", change))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(change >= 0 ?
                                Color(uiColor: ColorPalette.tradingUp) :
                                Color(uiColor: ColorPalette.tradingDown)
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: ColorPalette.bgTertiary))
        .cornerRadius(8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SectorGridView(
            title: "行业板块",
            sectors: [
                SectorItem(id: "1", name: "电力设备", changePercent: 3.25, leadingStock: "宁德时代", leadingStockChange: 5.62, volume: nil),
                SectorItem(id: "2", name: "医药生物", changePercent: 2.18, leadingStock: "恒瑞医药", leadingStockChange: 4.33, volume: nil),
                SectorItem(id: "3", name: "电子", changePercent: -1.95, leadingStock: "立讯精密", leadingStockChange: -0.89, volume: nil),
                SectorItem(id: "4", name: "计算机", changePercent: 1.67, leadingStock: "中科曙光", leadingStockChange: 6.21, volume: nil)
            ],
            isLoading: false,
            onSectorTap: { sector in print("点击板块: \(sector.name)") },
            onMoreTap: { print("点击更多") }
        )
        .padding()
    }
    .background(Color(uiColor: ColorPalette.bgPrimary))
}

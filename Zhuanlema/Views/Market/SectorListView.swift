/**
 * 板块列表页面
 * 展示完整的行业板块或概念板块列表
 */
import SwiftUI

struct SectorListView: View {
    let title: String
    let sectorType: SectorType
    let sectors: [SectorItem]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()
            
            if sectors.isEmpty {
                emptyStateView
            } else {
                sectorListContent
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                }
            }
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            
            Text("暂无\(title)数据")
                .font(.system(size: 16))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
    }
    
    /// 板块列表内容
    private var sectorListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(sectors.enumerated()), id: \.element.id) { index, sector in
                    SectorListRow(sector: sector, rank: index + 1)
                    
                    if index < sectors.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }
}

/// 板块列表行
struct SectorListRow: View {
    let sector: SectorItem
    let rank: Int
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            Text("\(rank)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(
                    rank <= 3 ?
                    Color(uiColor: ColorPalette.brandPrimary) :
                    Color(uiColor: ColorPalette.textTertiary)
                )
                .frame(width: 28, alignment: .center)
            
            // 板块信息
            VStack(alignment: .leading, spacing: 4) {
                Text(sector.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                if !sector.leadingStock.isEmpty {
                    HStack(spacing: 4) {
                        Text("领涨:")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        
                        Text(sector.leadingStock)
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    }
                }
            }
            
            Spacer()
            
            // 涨跌幅
            VStack(alignment: .trailing, spacing: 4) {
                Text(sector.formattedChangePercent)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(sector.isUp ?
                        Color(uiColor: ColorPalette.tradingUp) :
                        Color(uiColor: ColorPalette.tradingDown)
                    )
                
                if let change = sector.leadingStockChange {
                    Text(String(format: "领涨 %@%.2f%%", change >= 0 ? "+" : "", change))
                        .font(.system(size: 11))
                        .foregroundColor(change >= 0 ?
                            Color(uiColor: ColorPalette.tradingUp) :
                            Color(uiColor: ColorPalette.tradingDown)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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
    NavigationView {
        SectorListView(
            title: "行业板块",
            sectorType: .industry,
            sectors: [
                SectorItem(id: "1", name: "电力设备", changePercent: 3.25, leadingStock: "宁德时代", leadingStockChange: 5.62, volume: nil),
                SectorItem(id: "2", name: "医药生物", changePercent: 2.18, leadingStock: "恒瑞医药", leadingStockChange: 4.33, volume: nil),
                SectorItem(id: "3", name: "电子", changePercent: 1.95, leadingStock: "立讯精密", leadingStockChange: 3.89, volume: nil),
                SectorItem(id: "4", name: "计算机", changePercent: 1.67, leadingStock: "中科曙光", leadingStockChange: 6.21, volume: nil),
                SectorItem(id: "5", name: "汽车", changePercent: -0.52, leadingStock: "比亚迪", leadingStockChange: 1.25, volume: nil),
                SectorItem(id: "6", name: "有色金属", changePercent: -1.23, leadingStock: "紫金矿业", leadingStockChange: -0.85, volume: nil)
            ]
        )
    }
}

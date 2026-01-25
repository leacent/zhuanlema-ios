/**
 * 个股详情页（占位）
 * 展示名称/代码、价格、分时/K线占位、相关讨论占位；后续接入行情 API 与社区按 tag 筛选
 */
import SwiftUI
import UIKit

struct StockDetailView: View {
    let item: WatchlistItem
    @Environment(\.dismiss) private var dismiss
    
    private var changeColor: Color {
        guard let pct = item.changePercent else {
            return Color(uiColor: ColorPalette.textPrimary)
        }
        if pct > 0 { return Color(uiColor: ColorPalette.tradingUp) }
        if pct < 0 { return Color(uiColor: ColorPalette.tradingDown) }
        return Color(uiColor: ColorPalette.textPrimary)
    }
    
    private var changeText: String {
        guard let pct = item.changePercent else { return "--" }
        let sign = pct >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, pct)
    }
    
    private var priceText: String {
        guard let p = item.price else { return "--" }
        return String(format: "%.2f", p)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题区：名称 + 代码
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    Text(item.displayCode)
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
                
                // 价格块
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(priceText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(changeColor)
                    Text(changeText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(changeColor)
                }
                
                // 分时/K线占位
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: ColorPalette.bgTertiary))
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        Text("分时 / K线")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        Text("接入行情 API 后展示")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: ColorPalette.textDisabled))
                    }
                    .frame(height: 180)
                }
                
                // 相关讨论占位
                VStack(alignment: .leading, spacing: 8) {
                    Text("相关讨论")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: ColorPalette.bgTertiary))
                        VStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 28))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                            Text("社区中带 #\(item.name)# 的讨论将在此展示")
                                .font(.system(size: 13))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: 100)
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: ColorPalette.bgPrimary))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        StockDetailView(item: WatchlistItem(id: "sh600519", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 1.25, volume: 2_340_000))
    }
}

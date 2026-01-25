/**
 * 自选股行视图
 * 展示名称/代码、现价、涨跌幅、成交量；红涨绿跌
 */
import SwiftUI
import UIKit

struct WatchlistRowView: View {
    let item: WatchlistItem
    
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
    
    private var volumeText: String {
        guard let v = item.volume else { return "" }
        if v >= 1_000_000 {
            return String(format: "%.2fM", Double(v) / 1_000_000)
        }
        if v >= 1_000 {
            return String(format: "%.2fK", Double(v) / 1_000)
        }
        return "\(v)"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Text(item.displayCode)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(priceText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(changeColor)
                if !volumeText.isEmpty {
                    Text(volumeText)
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
            }
            Text(changeText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(changeColor)
                .frame(minWidth: 56, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        WatchlistRowView(item: WatchlistItem(id: "sh600519", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 1.25, volume: 2_340_000))
        WatchlistRowView(item: WatchlistItem(id: "sz000858", name: "五粮液", code: "sz000858", price: 156.32, changePercent: -0.45, volume: 5_120_000))
    }
}

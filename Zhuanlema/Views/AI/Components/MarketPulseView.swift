/**
 * 大盘心跳卡片
 * 三列展示三大指数的收盘价和涨跌幅
 */
import SwiftUI

struct MarketPulseView: View {
    let marketData: MarketDataSnapshot?

    var body: some View {
        HStack(spacing: 0) {
            indexColumn(name: "上证", quote: marketData?.shIndex)
            Divider().frame(height: 36)
            indexColumn(name: "深证", quote: marketData?.szIndex)
            Divider().frame(height: 36)
            indexColumn(name: "创业板", quote: marketData?.cyIndex)
        }
    }

    private func indexColumn(name: String, quote: IndexQuote?) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))

            if let q = quote, let close = q.close {
                Text(String(format: "%.0f", close))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))

                Text(q.changeText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(q.isUp ? Color(uiColor: ColorPalette.brandPrimary) : .green)
            } else {
                Text("--")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                Text("--")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MarketPulseView(marketData: MarketDataSnapshot(
        shIndex: IndexQuote(name: "上证指数", close: 3250.12, changePercent: -0.32),
        szIndex: IndexQuote(name: "深证成指", close: 10856.78, changePercent: 0.15),
        cyIndex: IndexQuote(name: "创业板指", close: 2180.45, changePercent: 0.52)
    ))
    .padding()
}

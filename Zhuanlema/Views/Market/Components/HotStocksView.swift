/**
 * 热门股票榜单组件
 * 支持涨幅榜、跌幅榜、活跃榜切换
 */
import SwiftUI

struct HotStocksView: View {
    @Binding var selectedType: HotStockType
    let stocks: [WatchlistItem]
    let displayCount: Int
    let isLoading: Bool
    let onStockTap: (WatchlistItem) -> Void
    let onLoadMore: () -> Void
    
    private var displayed: [WatchlistItem] {
        Array(stocks.prefix(displayCount))
    }
    
    private var hasMore: Bool {
        displayCount < stocks.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题和Tab
            HStack {
                Text("热门榜单")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach(HotStockType.allCases) { type in
                        TabButton(
                            title: type.tabTitle,
                            isSelected: selectedType == type,
                            action: { selectedType = type }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color(uiColor: ColorPalette.divider))
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                        .padding(.vertical, 40)
                    Spacer()
                }
            } else if stocks.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, stock in
                        Button(action: { onStockTap(stock) }) {
                            HotStockRow(
                                rank: index + 1,
                                stock: stock
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if index == displayed.count - 1 && hasMore {
                                onLoadMore()
                            }
                        }
                        
                        if index < displayed.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                    
                    if hasMore {
                        Button(action: onLoadMore) {
                            HStack {
                                Spacer()
                                Text("上拉加载更多")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    } else if stocks.count > 20 {
                        Text("已加载全部 \(stocks.count) 条")
                            .font(.system(size: 12))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(12)
    }
}

/// Tab按钮
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(
                    isSelected ?
                    Color(uiColor: ColorPalette.brandPrimary) :
                    Color(uiColor: ColorPalette.textSecondary)
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ?
                    Color(uiColor: ColorPalette.brandLight) :
                    Color.clear
                )
                .cornerRadius(12)
        }
    }
}

/// 热门股票行
struct HotStockRow: View {
    let rank: Int
    let stock: WatchlistItem
    
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
                .frame(width: 24, alignment: .center)
            
            // 股票信息
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Text(stock.displayCode)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            
            Spacer()
            
            // 价格和涨跌幅
            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.price {
                    Text(String(format: "%.2f", price))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                }
                
                if let changePercent = stock.changePercent {
                    let isUp = changePercent >= 0
                    let color = isUp ?
                        Color(uiColor: ColorPalette.tradingUp) :
                        Color(uiColor: ColorPalette.tradingDown)
                    
                    Text(String(format: "%@%.2f%%", isUp ? "+" : "", changePercent))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(color)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 16) {
        HotStocksView(
            selectedType: .constant(.gainers),
            stocks: [
                WatchlistItem(id: "1", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 10.01, volume: nil),
                WatchlistItem(id: "2", name: "五粮液", code: "sz000858", price: 156.32, changePercent: 9.99, volume: nil),
                WatchlistItem(id: "3", name: "中国平安", code: "sh601318", price: 48.90, changePercent: 5.62, volume: nil)
            ],
            displayCount: 20,
            isLoading: false,
            onStockTap: { _ in },
            onLoadMore: {}
        )
        .padding()
    }
    .background(Color(uiColor: ColorPalette.bgPrimary))
}

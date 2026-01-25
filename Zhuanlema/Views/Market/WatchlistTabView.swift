/**
 * 自选股Tab视图
 * 独立的自选股列表页面
 */
import SwiftUI

struct WatchlistTabView: View {
    let watchlist: [WatchlistItem]
    let isLoading: Bool
    let onAddTap: () -> Void
    let onStockTap: (WatchlistItem) -> Void
    
    var body: some View {
        if isLoading {
            loadingView
        } else if watchlist.isEmpty {
            emptyStateView
        } else {
            watchlistContent
        }
    }
    
    /// 加载视图
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
            Text("加载中...")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(uiColor: ColorPalette.brandPrimary).opacity(0.1),
                                Color(uiColor: ColorPalette.brandSecondary).opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "star.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            }
            
            // 文字提示
            VStack(spacing: 8) {
                Text("暂无自选股")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Text("添加感兴趣的股票，随时关注行情")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            
            // 添加按钮
            Button(action: onAddTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("添加自选")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(uiColor: ColorPalette.brandPrimary),
                            Color(uiColor: ColorPalette.brandSecondary)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(24)
                .shadow(
                    color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 自选股列表内容
    private var watchlistContent: some View {
        VStack(spacing: 0) {
            // 顶部操作栏
            HStack {
                Text("共 \(watchlist.count) 只")
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                
                Spacer()
                
                Button(action: onAddTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        
                        Text("添加")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 自选股列表
            LazyVStack(spacing: 0) {
                ForEach(watchlist) { item in
                    Button(action: { onStockTap(item) }) {
                        WatchlistRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    
                    if item.id != watchlist.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 空状态
        WatchlistTabView(
            watchlist: [],
            isLoading: false,
            onAddTap: {},
            onStockTap: { _ in }
        )
        .frame(height: 400)
        .background(Color(uiColor: ColorPalette.bgPrimary))
        
        // 有数据状态
        WatchlistTabView(
            watchlist: [
                WatchlistItem(id: "1", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 1.25, volume: nil),
                WatchlistItem(id: "2", name: "五粮液", code: "sz000858", price: 156.32, changePercent: -0.45, volume: nil)
            ],
            isLoading: false,
            onAddTap: {},
            onStockTap: { _ in }
        )
        .frame(height: 300)
        .background(Color(uiColor: ColorPalette.bgPrimary))
    }
}

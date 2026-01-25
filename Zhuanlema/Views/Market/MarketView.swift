/**
 * 行情页
 * 顶部Tab切换：行情 / 自选
 * 行情Tab：市场总览、大盘指数、行业板块、概念板块、涨跌榜单、社区热点
 * 自选Tab：自选股列表
 */
import SwiftUI
import UIKit

struct MarketView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MarketViewModel()
    @State private var showStockSearch = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部Tab切换：行情 / 自选
                    MarketTabSelector(selectedTab: $viewModel.selectedTab)

                    // 行情 Tab 下：A股 / 港股 / 美股
                    if viewModel.selectedTab == .market {
                        MarketRegionTabSelector(selectedRegion: $viewModel.selectedRegion)
                            .onChange(of: viewModel.selectedRegion) { _ in
                                Task {
                                    await viewModel.loadDataForSelectedRegion()
                                }
                            }
                    }
                    
                    // 内容区域
                    TabView(selection: $viewModel.selectedTab) {
                        // 行情Tab
                        marketTabContent
                            .tag(MarketTab.market)
                        
                        // 自选Tab
                        watchlistTabContent
                            .tag(MarketTab.watchlist)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("行情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStockSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
            .tint(Color(uiColor: ColorPalette.brandPrimary))
            .fullScreenCover(isPresented: $showStockSearch) {
                StockSearchView()
            }
            .refreshable {
                await refreshAsync()
            }
            .alert("加载失败", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - 行情Tab内容

    private var marketTabContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. 大盘指数（按当前区域：A股/港股/美股）
                indicesSection
                    .padding(.top, 12)
                
                // 2. 快捷功能入口
                QuickActionsView(
                    onRankingTap: handleRankingTap,
                    onDiscussionTap: handleDiscussionTap,
                    onNewsTap: handleNewsTap,
                    onAddWatchlistTap: handleAddWatchlistTap
                )
                .padding(.horizontal, 16)
                
                // 3. 社区热点（移至此位置，可选展示）
                if !viewModel.trendingTopics.isEmpty {
                    TrendingTopicsView(
                        topics: viewModel.trendingTopics,
                        onTopicTap: handleTopicTap
                    )
                    .padding(.horizontal, 16)
                }
                
                // 4. 行业板块
                NavigationLink(destination: SectorListView(
                    title: "行业板块",
                    sectorType: .industry,
                    sectors: viewModel.industrySectors
                )) {
                    SectorGridView(
                        title: "行业板块",
                        sectors: viewModel.industrySectors,
                        isLoading: viewModel.isSectorsLoading,
                        onSectorTap: handleSectorTap,
                        onMoreTap: {}
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                
                // 5. 概念板块
                NavigationLink(destination: SectorListView(
                    title: "概念板块",
                    sectorType: .concept,
                    sectors: viewModel.conceptSectors
                )) {
                    SectorGridView(
                        title: "概念板块",
                        sectors: viewModel.conceptSectors,
                        isLoading: viewModel.isSectorsLoading,
                        onSectorTap: handleSectorTap,
                        onMoreTap: {}
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                
                // 6. 热门股票榜单（全量，上拉加载更多）
                HotStocksView(
                    selectedType: $viewModel.hotStockType,
                    stocks: viewModel.hotStocks,
                    displayCount: viewModel.hotStocksDisplayCount,
                    isLoading: viewModel.isHotStocksLoading,
                    onStockTap: handleStockTap,
                    onLoadMore: viewModel.loadMoreHotStocks
                )
                .padding(.horizontal, 16)
                .onChange(of: viewModel.hotStockType) { newType in
                    Task {
                        await viewModel.switchHotStockType(newType)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - 自选Tab内容
    
    private var watchlistTabContent: some View {
        WatchlistTabView(
            watchlist: viewModel.watchlist,
            isLoading: viewModel.isLoading,
            onAddTap: handleAddWatchlistTap,
            onStockTap: { stock in
                // 导航到详情页
                handleStockTap(stock)
            }
        )
    }
    
    // MARK: - 大盘指数
    
    /// 大盘指数区域（标题随当前区域：A股指数 / 港股指数 / 美股指数）
    private var indicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.selectedRegion.indicesSectionTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.indices.isEmpty {
                        Text("暂无数据")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                            .frame(height: 80)
                            .padding(.horizontal, 16)
                    } else {
                        ForEach(viewModel.indices) { index in
                            indexCard(index)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    /// 指数卡片
    private func indexCard(_ index: MarketIndex) -> some View {
        let isUp = index.changePercent >= 0
        let color = isUp ? Color(uiColor: ColorPalette.tradingUp) : Color(uiColor: ColorPalette.tradingDown)
        let pctStr = String(format: "%@%.2f%%", index.changePercent >= 0 ? "+" : "", index.changePercent)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(index.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            
            Text(String(format: "%.2f", index.value))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            
            Text(pctStr)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(16)
        .frame(minWidth: 120)
        .background(Color(uiColor: ColorPalette.brandLight))
        .cornerRadius(12)
    }
    
    // MARK: - 事件处理
    
    /// 处理榜单点击
    private func handleRankingTap() {
        // 滚动到热门榜单区域
        print("滚动到榜单区域")
    }
    
    /// 处理讨论点击
    private func handleDiscussionTap() {
        // 跳转到社区页
        print("跳转到社区")
    }
    
    /// 处理资讯点击
    private func handleNewsTap() {
        // 打开财经资讯页面
        print("打开财经资讯")
    }
    
    /// 处理添加自选点击
    private func handleAddWatchlistTap() {
        // 切换到自选Tab
        withAnimation {
            viewModel.selectedTab = .watchlist
        }
        print("添加自选")
    }
    
    /// 处理话题点击
    private func handleTopicTap(_ topic: String) {
        // 跳转到社区，筛选该话题的帖子
        print("查看话题: \(topic)")
    }
    
    /// 处理股票点击
    private func handleStockTap(_ stock: WatchlistItem) {
        // 进入个股详情页
        print("查看股票: \(stock.name)")
    }
    
    /// 处理板块点击
    private func handleSectorTap(_ sector: SectorItem) {
        // 进入板块详情页
        print("查看板块: \(sector.name)")
    }
    
    /// 异步刷新
    private func refreshAsync() async {
        viewModel.refresh()
        while viewModel.isRefreshing {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}

#Preview {
    MarketView()
        .environmentObject(AppState())
}

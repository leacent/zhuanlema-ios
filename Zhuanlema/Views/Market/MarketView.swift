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
    /// 当前选中的股票（用于导航到详情页）
    @State private var selectedStock: WatchlistItem?

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
                    .onChange(of: viewModel.selectedTab) { newTab in
                        if newTab == .watchlist {
                            Task {
                                await viewModel.loadWatchlistIfNeeded()
                            }
                        }
                    }
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
            .background(
                // 隐藏的 NavigationLink，用于程序式导航到个股详情
                NavigationLink(
                    destination: Group {
                        if let stock = selectedStock {
                            StockDetailView(item: stock)
                        }
                    },
                    isActive: Binding(
                        get: { selectedStock != nil },
                        set: { if !$0 { selectedStock = nil } }
                    ),
                    label: { EmptyView() }
                )
                .hidden()
            )
            .tint(Color(uiColor: ColorPalette.brandPrimary))
            .fullScreenCover(isPresented: $showStockSearch) {
                StockSearchView()
            }
            .refreshable {
                await viewModel.refresh()
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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    // 0. 市场总览卡片（赚钱比例 & 涨跌分布）
                    if viewModel.selectedRegion == .aShare {
                        MarketOverviewCard(stats: viewModel.marketStats)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    
                    // 1. 大盘指数（按当前区域：A股/港股/美股）
                    indicesSection
                        .padding(.top, viewModel.selectedRegion == .aShare ? 0 : 12)
                    
                    // 2. 快捷功能入口
                    QuickActionsView(
                        onRankingTap: {
                            withAnimation {
                                proxy.scrollTo("hotStocksSection", anchor: .top)
                            }
                        },
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
                    .id("hotStocksSection")
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
    
    /// 处理讨论点击 → 切换到社区 Tab
    private func handleDiscussionTap() {
        withAnimation {
            appState.selectedMainTab = 0
        }
    }
    
    /// 处理资讯点击（功能待开发，打开搜索页作为临时替代）
    private func handleNewsTap() {
        // TODO: 后续接入财经资讯页面
        showStockSearch = true
    }
    
    /// 处理添加自选点击 → 打开搜索页以搜索并添加自选
    private func handleAddWatchlistTap() {
        showStockSearch = true
    }
    
    /// 处理话题点击 → 跳转到社区 Tab
    private func handleTopicTap(_ topic: String) {
        // TODO: 后续支持带话题筛选参数跳转
        withAnimation {
            appState.selectedMainTab = 0
        }
    }
    
    /// 处理股票点击 → 导航到个股详情页
    private func handleStockTap(_ stock: WatchlistItem) {
        selectedStock = stock
    }
    
    /// 处理板块点击（由外层 NavigationLink 导航到 SectorListView）
    private func handleSectorTap(_ sector: SectorItem) {
        // 板块卡片的点击导航由外层 NavigationLink 处理
    }
    
}

#Preview {
    MarketView()
        .environmentObject(AppState())
}

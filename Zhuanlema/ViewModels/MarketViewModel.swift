/**
 * 行情页视图模型
 * 管理Tab状态、大盘指数、板块数据、热门股票榜单、社区话题、自选股
 */
import Foundation
import Combine
import UIKit

@MainActor
class MarketViewModel: ObservableObject {
    // MARK: - Tab状态
    
    /// 当前选中的Tab
    @Published var selectedTab: MarketTab = .market

    /// 当前选中的市场区域（A股/港股/美股），仅行情 Tab 下有效
    @Published var selectedRegion: MarketRegion = .aShare
    
    // MARK: - 行情数据
    
    /// 当前区域的大盘指数列表
    @Published var indices: [MarketIndex] = []
    
    /// 行业板块列表
    @Published var industrySectors: [SectorItem] = []
    
    /// 概念板块列表
    @Published var conceptSectors: [SectorItem] = []
    
    /// 热门股票列表（排行榜，全量最多100条）
    @Published var hotStocks: [WatchlistItem] = []
    
    /// 热门榜单当前展示条数（上拉加载更多时增加）
    @Published var hotStocksDisplayCount: Int = 20
    
    /// 当前热门股票类型
    @Published var hotStockType: HotStockType = .gainers
    
    /// 社区热点话题
    @Published var trendingTopics: [String] = []
    
    /// 市场总览统计（赚钱比例、涨跌分布）
    @Published var marketStats: MarketStats?
    
    // MARK: - 自选数据
    
    /// 自选列表
    @Published var watchlist: [WatchlistItem] = []
    
    /// 自选股是否已加载过（懒加载标志）
    private var watchlistLoaded: Bool = false
    
    // MARK: - 加载状态
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 是否正在刷新
    @Published var isRefreshing: Bool = false
    
    /// 是否正在加载板块数据
    @Published var isSectorsLoading: Bool = false
    
    /// 是否正在加载热门股票
    @Published var isHotStocksLoading: Bool = false
    
    /// 错误消息
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    
    /// 行情数据服务
    private let marketDataService = MarketDataService.shared
    
    /// 数据缓存
    private let cache = MarketDataCache.shared
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /// 加载过程中收集的失败模块名称（用于汇总错误提示）
    private var loadErrors: [String] = []
    
    // MARK: - 初始化
    
    init() {
        Task {
            await loadMarketData()
        }
    }
    
    // MARK: - 公开方法
    
    /// 加载所有市场数据
    func loadMarketData() async {
        guard !isLoading else { return }
        isLoading = true
        isSectorsLoading = true
        isHotStocksLoading = true
        errorMessage = nil
        loadErrors = []
        
        // 并行加载多个数据源
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadIndices() }
            group.addTask { await self.loadIndustrySectors() }
            group.addTask { await self.loadConceptSectors() }
            group.addTask { await self.loadHotStocks() }
            group.addTask { await self.loadMarketStats() }
            group.addTask { await self.loadTrendingTopics() }
            // 注意：自选股使用懒加载，切换到自选 Tab 时才请求
        }
        
        isLoading = false
        isSectorsLoading = false
        isHotStocksLoading = false
        
        // 汇总错误提示
        if !loadErrors.isEmpty {
            let modules = loadErrors.joined(separator: "、")
            errorMessage = "\(modules)加载失败，请下拉刷新重试"
        }
    }
    
    /// 下拉刷新（async，可直接 await）
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        
        // 清除缓存和懒加载标志
        cache.clearAll()
        watchlistLoaded = false
        
        // 重新加载数据
        await loadMarketData()
        
        // 如果当前在自选 Tab，也刷新自选数据
        if selectedTab == .watchlist {
            watchlistLoaded = true
            await loadWatchlist()
        }
        
        isRefreshing = false
    }
    
    /// 切换热门股票类型
    func switchHotStockType(_ type: HotStockType) async {
        hotStockType = type
        hotStocksDisplayCount = 20
        await loadHotStocks()
    }
    
    /// 热门榜单上拉加载更多（每次 +20，不超过总数）
    func loadMoreHotStocks() {
        let next = min(hotStocksDisplayCount + 20, hotStocks.count)
        if next > hotStocksDisplayCount {
            hotStocksDisplayCount = next
        }
    }

    /// 切换 A股/港股/美股 时调用：并行重载指数、行业板块、概念板块、排行榜
    func loadDataForSelectedRegion() async {
        hotStocksDisplayCount = 20
        isSectorsLoading = true
        isHotStocksLoading = true
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadIndices() }
            group.addTask { await self.loadIndustrySectors() }
            group.addTask { await self.loadConceptSectors() }
            group.addTask { await self.loadHotStocks() }
        }
        
        isSectorsLoading = false
        isHotStocksLoading = false
    }
    
    /// 懒加载自选股（首次切到自选 Tab 时调用）
    func loadWatchlistIfNeeded() async {
        guard !watchlistLoaded else { return }
        watchlistLoaded = true
        await loadWatchlist()
    }
    
    /// 根据 code 获取自选项
    func watchlistItem(forCode code: String) -> WatchlistItem? {
        watchlist.first { $0.code == code }
    }
    
    // MARK: - 私有方法
    
    /// 加载当前区域的指数数据
    private func loadIndices() async {
        let region = selectedRegion
        do {
            if let cached = cache.getCachedIndices(region: region) {
                indices = cached
                return
            }
            let data = try await marketDataService.fetchIndices(region: region)
            indices = data
            cache.setCachedIndices(data, region: region)
        } catch {
            print("加载指数失败 (\(region.title)): \(error.localizedDescription)")
            indices = []
            loadErrors.append("指数")
        }
    }
    
    /// 加载行业板块（按当前选中市场，带缓存）
    private func loadIndustrySectors() async {
        let region = selectedRegion
        if let cached = cache.getCachedSectors(type: .industry, region: region) {
            industrySectors = cached
            return
        }
        do {
            let data = try await marketDataService.fetchIndustrySectors(region: region)
            industrySectors = data
            cache.setCachedSectors(data, type: .industry, region: region)
        } catch {
            print("加载行业板块失败 (\(region.title)): \(error.localizedDescription)")
            industrySectors = []
            loadErrors.append("行业板块")
        }
    }
    
    /// 加载概念板块（按当前选中市场，带缓存）
    private func loadConceptSectors() async {
        let region = selectedRegion
        if let cached = cache.getCachedSectors(type: .concept, region: region) {
            conceptSectors = cached
            return
        }
        do {
            let data = try await marketDataService.fetchConceptSectors(region: region)
            conceptSectors = data
            cache.setCachedSectors(data, type: .concept, region: region)
        } catch {
            print("加载概念板块失败 (\(region.title)): \(error.localizedDescription)")
            conceptSectors = []
            loadErrors.append("概念板块")
        }
    }
    
    /// 加载热门股票排行榜（按当前选中市场，带缓存）
    /// Mock 回退逻辑统一在 MarketDataService 中处理
    private func loadHotStocks() async {
        isHotStocksLoading = true
        let region = selectedRegion
        let type = hotStockType
        if let cached = cache.getCachedHotStocks(type: type, region: region) {
            hotStocks = cached
            isHotStocksLoading = false
            return
        }
        do {
            let data = try await marketDataService.fetchHotStocks(type: type, region: region)
            hotStocks = data
            cache.setCachedHotStocks(data, type: type, region: region)
        } catch {
            print("加载热门股票失败 (\(region.title)): \(error.localizedDescription)")
            hotStocks = []
            loadErrors.append("热门榜单")
        }
        isHotStocksLoading = false
    }
    
    /// 加载市场总览统计（赚钱比例、涨跌分布）
    private func loadMarketStats() async {
        // 优先使用缓存
        if let cached = cache.getCachedStats() {
            marketStats = cached
            return
        }
        // TODO: 接入 CloudBase 云函数获取真实市场统计（getTodayCheckInStats 或行情统计 API）
        // 目前使用模拟数据
        let stats = MarketStats(
            upCount: 2733,
            downCount: 1336,
            flatCount: 135,
            totalVolume: "31,184亿",
            winRate: 0.62
        )
        marketStats = stats
        cache.setCachedStats(stats)
    }
    
    /// 加载社区热点话题
    private func loadTrendingTopics() async {
        // TODO: 从CloudBase查询社区帖子，聚合高频标签
        // 目前使用模拟数据
        trendingTopics = ["大盘", "茅台", "新能源", "芯片", "价值投资", "今日复盘"]
    }
    
    /// 加载自选股列表
    private func loadWatchlist() async {
        // TODO: 从CloudBase读取用户自选股列表
        // 然后批量获取行情数据
        let mockCodes = ["sh600519", "sz000858", "sh601318"]
        
        do {
            let data = try await marketDataService.fetchStockData(codes: mockCodes)
            watchlist = data
            
            // 缓存数据
            cache.setCachedStocks(data)
        } catch {
            print("加载自选股失败: \(error.localizedDescription)")
            watchlist = []
        }
    }
}

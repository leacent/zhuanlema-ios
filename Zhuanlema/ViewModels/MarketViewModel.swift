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
    
    // MARK: - 自选数据
    
    /// 自选列表
    @Published var watchlist: [WatchlistItem] = []
    
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
        
        // 并行加载多个数据源
        await withTaskGroup(of: Void.self) { group in
            // 加载指数数据
            group.addTask {
                await self.loadIndices()
            }
            
            // 加载行业板块
            group.addTask {
                await self.loadIndustrySectors()
            }
            
            // 加载概念板块
            group.addTask {
                await self.loadConceptSectors()
            }
            
            // 加载热门股票排行榜
            group.addTask {
                await self.loadHotStocks()
            }
            
            // 加载社区话题
            group.addTask {
                await self.loadTrendingTopics()
            }
            
            // 加载自选股（如果有）
            group.addTask {
                await self.loadWatchlist()
            }
        }
        
        isLoading = false
        isSectorsLoading = false
        isHotStocksLoading = false
    }
    
    /// 下拉刷新
    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        
        Task {
            // 清除缓存
            cache.clearAll()
            
            // 重新加载数据
            await loadMarketData()
            isRefreshing = false
        }
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

    /// 切换 A股/港股/美股 时调用：重载指数、行业板块、概念板块、排行榜
    func loadDataForSelectedRegion() async {
        hotStocksDisplayCount = 20
        await loadIndices()
        await loadIndustrySectors()
        await loadConceptSectors()
        await loadHotStocks()
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
        }
    }
    
    /// 加载行业板块（按当前选中市场）
    private func loadIndustrySectors() async {
        let region = selectedRegion
        do {
            industrySectors = try await marketDataService.fetchIndustrySectors(region: region)
        } catch {
            print("加载行业板块失败 (\(region.title)): \(error.localizedDescription)")
            industrySectors = []
        }
    }
    
    /// 加载概念板块（按当前选中市场）
    private func loadConceptSectors() async {
        let region = selectedRegion
        do {
            conceptSectors = try await marketDataService.fetchConceptSectors(region: region)
        } catch {
            print("加载概念板块失败 (\(region.title)): \(error.localizedDescription)")
            conceptSectors = []
        }
    }
    
    /// 加载热门股票排行榜（按当前选中市场，东方财富全量）
    private func loadHotStocks() async {
        isHotStocksLoading = true
        let region = selectedRegion
        do {
            let data = try await marketDataService.fetchHotStocks(type: hotStockType, region: region)
            hotStocks = data.isEmpty && region == .aShare ? getMockHotStocks() : data
        } catch {
            print("加载热门股票失败 (\(region.title)): \(error.localizedDescription)")
            hotStocks = region == .aShare ? getMockHotStocks() : []
        }
        isHotStocksLoading = false
    }
    
    /// 获取模拟热门股票数据
    private func getMockHotStocks() -> [WatchlistItem] {
        switch hotStockType {
        case .gainers:
            return [
                WatchlistItem(id: "1", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 5.62, volume: 2_340_000),
                WatchlistItem(id: "2", name: "五粮液", code: "sz000858", price: 156.32, changePercent: 4.89, volume: 5_120_000),
                WatchlistItem(id: "3", name: "宁德时代", code: "sz300750", price: 218.45, changePercent: 4.25, volume: 8_900_000),
                WatchlistItem(id: "4", name: "比亚迪", code: "sz002594", price: 256.78, changePercent: 3.98, volume: 6_780_000),
                WatchlistItem(id: "5", name: "招商银行", code: "sh600036", price: 32.56, changePercent: 3.45, volume: 12_300_000),
                WatchlistItem(id: "6", name: "中国平安", code: "sh601318", price: 48.90, changePercent: 2.89, volume: 18_900_000),
                WatchlistItem(id: "7", name: "美的集团", code: "sz000333", price: 58.23, changePercent: 2.56, volume: 7_650_000),
                WatchlistItem(id: "8", name: "隆基绿能", code: "sh601012", price: 28.45, changePercent: 2.12, volume: 9_870_000),
                WatchlistItem(id: "9", name: "恒瑞医药", code: "sh600276", price: 42.36, changePercent: 1.89, volume: 4_560_000),
                WatchlistItem(id: "10", name: "东方财富", code: "sz300059", price: 18.92, changePercent: 1.56, volume: 15_600_000)
            ]
        case .losers:
            return [
                WatchlistItem(id: "1", name: "工商银行", code: "sh601398", price: 4.85, changePercent: -2.42, volume: 45_600_000),
                WatchlistItem(id: "2", name: "农业银行", code: "sh601288", price: 3.52, changePercent: -2.21, volume: 38_900_000),
                WatchlistItem(id: "3", name: "建设银行", code: "sh601939", price: 6.28, changePercent: -1.89, volume: 28_700_000),
                WatchlistItem(id: "4", name: "中国银行", code: "sh601988", price: 3.68, changePercent: -1.61, volume: 32_400_000),
                WatchlistItem(id: "5", name: "中国石油", code: "sh601857", price: 7.85, changePercent: -1.38, volume: 25_600_000),
                WatchlistItem(id: "6", name: "中国石化", code: "sh600028", price: 5.12, changePercent: -1.15, volume: 18_900_000),
                WatchlistItem(id: "7", name: "中国神华", code: "sh601088", price: 32.45, changePercent: -0.92, volume: 8_760_000),
                WatchlistItem(id: "8", name: "长江电力", code: "sh600900", price: 25.68, changePercent: -0.78, volume: 6_540_000),
                WatchlistItem(id: "9", name: "中国建筑", code: "sh601668", price: 5.62, changePercent: -0.53, volume: 15_200_000),
                WatchlistItem(id: "10", name: "中国电建", code: "sh601669", price: 4.28, changePercent: -0.46, volume: 12_300_000)
            ]
        case .active:
            return [
                WatchlistItem(id: "1", name: "东方财富", code: "sz300059", price: 18.92, changePercent: 1.56, volume: 156_000_000),
                WatchlistItem(id: "2", name: "工商银行", code: "sh601398", price: 4.85, changePercent: -0.42, volume: 145_600_000),
                WatchlistItem(id: "3", name: "比亚迪", code: "sz002594", price: 256.78, changePercent: 3.98, volume: 98_700_000),
                WatchlistItem(id: "4", name: "宁德时代", code: "sz300750", price: 218.45, changePercent: 4.25, volume: 89_000_000),
                WatchlistItem(id: "5", name: "中国平安", code: "sh601318", price: 48.90, changePercent: 2.89, volume: 78_900_000),
                WatchlistItem(id: "6", name: "招商银行", code: "sh600036", price: 32.56, changePercent: 3.45, volume: 72_300_000),
                WatchlistItem(id: "7", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 5.62, volume: 65_400_000),
                WatchlistItem(id: "8", name: "立讯精密", code: "sz002475", price: 28.56, changePercent: 2.12, volume: 58_700_000),
                WatchlistItem(id: "9", name: "美的集团", code: "sz000333", price: 58.23, changePercent: 2.56, volume: 52_600_000),
                WatchlistItem(id: "10", name: "隆基绿能", code: "sh601012", price: 28.45, changePercent: 2.12, volume: 48_700_000)
            ]
        }
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

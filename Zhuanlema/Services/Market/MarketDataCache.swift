/**
 * 行情数据缓存服务
 * 分层缓存策略：高频数据（指数/个股）短缓存，低频数据（板块/排行/统计）长缓存
 */
import Foundation

@MainActor
class MarketDataCache {
    /// 单例
    static let shared = MarketDataCache()
    
    // MARK: - 缓存超时时间（秒）
    
    /// 指数/个股行情缓存（交易时段高频更新）
    private let quoteTimeout: TimeInterval = 30
    
    /// 板块数据缓存（更新频率较低）
    private let sectorTimeout: TimeInterval = 120
    
    /// 排行榜缓存（更新频率较低）
    private let hotStocksTimeout: TimeInterval = 60
    
    /// 市场统计缓存（打卡数据不常变）
    private let statsTimeout: TimeInterval = 300
    
    // MARK: - 缓存存储
    
    /// 指数数据缓存（按市场区域）
    private var indicesCache: [MarketRegion: (data: [MarketIndex], timestamp: Date)] = [:]

    /// 股票数据缓存
    private var stocksCache: [String: (data: WatchlistItem, timestamp: Date)] = [:]
    
    /// 市场统计缓存
    private var statsCache: (data: MarketStats, timestamp: Date)?
    
    /// 板块数据缓存（按 "类型_区域" 作为 key）
    private var sectorsCache: [String: (data: [SectorItem], timestamp: Date)] = [:]
    
    /// 热门股票排行缓存（按 "类型_区域" 作为 key）
    private var hotStocksCache: [String: (data: [WatchlistItem], timestamp: Date)] = [:]
    
    private init() {}
    
    // MARK: - 指数缓存

    /// 获取指定区域的缓存指数数据
    /// - Parameter region: 市场区域
    /// - Returns: 缓存的指数数据，如果过期则返回 nil
    func getCachedIndices(region: MarketRegion) -> [MarketIndex]? {
        guard let cache = indicesCache[region] else { return nil }

        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < quoteTimeout {
            return cache.data
        }

        indicesCache.removeValue(forKey: region)
        return nil
    }

    /// 设置指定区域的指数数据缓存
    /// - Parameters:
    ///   - data: 指数数据
    ///   - region: 市场区域
    func setCachedIndices(_ data: [MarketIndex], region: MarketRegion) {
        indicesCache[region] = (data, Date())
    }
    
    // MARK: - 股票缓存
    
    /// 获取缓存的股票数据
    /// - Parameter code: 股票代码
    /// - Returns: 缓存的股票数据，如果过期则返回nil
    func getCachedStock(code: String) -> WatchlistItem? {
        guard let cache = stocksCache[code] else { return nil }
        
        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < quoteTimeout {
            return cache.data
        }
        
        stocksCache.removeValue(forKey: code)
        return nil
    }
    
    /// 设置股票数据缓存
    func setCachedStock(_ data: WatchlistItem, code: String) {
        stocksCache[code] = (data, Date())
    }
    
    /// 批量设置股票数据缓存
    func setCachedStocks(_ stocks: [WatchlistItem]) {
        let timestamp = Date()
        for stock in stocks {
            stocksCache[stock.code] = (stock, timestamp)
        }
    }
    
    // MARK: - 板块缓存
    
    /// 获取缓存的板块数据
    /// - Parameters:
    ///   - type: 板块类型（行业/概念）
    ///   - region: 市场区域
    /// - Returns: 缓存的板块数据，如果过期则返回 nil
    func getCachedSectors(type: SectorType, region: MarketRegion) -> [SectorItem]? {
        let key = "\(type)_\(region)"
        guard let cache = sectorsCache[key] else { return nil }
        
        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < sectorTimeout {
            return cache.data
        }
        
        sectorsCache.removeValue(forKey: key)
        return nil
    }
    
    /// 设置板块数据缓存
    func setCachedSectors(_ data: [SectorItem], type: SectorType, region: MarketRegion) {
        let key = "\(type)_\(region)"
        sectorsCache[key] = (data, Date())
    }
    
    // MARK: - 热门排行缓存
    
    /// 获取缓存的热门股票排行数据
    /// - Parameters:
    ///   - type: 榜单类型（涨幅/跌幅/活跃）
    ///   - region: 市场区域
    /// - Returns: 缓存的排行数据，如果过期则返回 nil
    func getCachedHotStocks(type: HotStockType, region: MarketRegion) -> [WatchlistItem]? {
        let key = "\(type)_\(region)"
        guard let cache = hotStocksCache[key] else { return nil }
        
        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < hotStocksTimeout {
            return cache.data
        }
        
        hotStocksCache.removeValue(forKey: key)
        return nil
    }
    
    /// 设置热门股票排行缓存
    func setCachedHotStocks(_ data: [WatchlistItem], type: HotStockType, region: MarketRegion) {
        let key = "\(type)_\(region)"
        hotStocksCache[key] = (data, Date())
    }
    
    // MARK: - 市场统计缓存
    
    /// 获取缓存的市场统计数据
    func getCachedStats() -> MarketStats? {
        guard let cache = statsCache else { return nil }
        
        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < statsTimeout {
            return cache.data
        }
        
        statsCache = nil
        return nil
    }
    
    /// 设置市场统计缓存
    func setCachedStats(_ data: MarketStats) {
        statsCache = (data, Date())
    }
    
    // MARK: - 清除缓存
    
    /// 清除所有缓存
    func clearAll() {
        indicesCache.removeAll()
        stocksCache.removeAll()
        sectorsCache.removeAll()
        hotStocksCache.removeAll()
        statsCache = nil
    }
    
    /// 清除指定股票的缓存
    func clearStock(code: String) {
        stocksCache.removeValue(forKey: code)
    }
}

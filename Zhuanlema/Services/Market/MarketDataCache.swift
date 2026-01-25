/**
 * 行情数据缓存服务
 * 减少API请求频率，提升响应速度
 */
import Foundation

@MainActor
class MarketDataCache {
    /// 单例
    static let shared = MarketDataCache()
    
    /// 缓存超时时间（秒）
    private let cacheTimeout: TimeInterval = 5
    
    /// 指数数据缓存（按市场区域）
    private var indicesCache: [MarketRegion: (data: [MarketIndex], timestamp: Date)] = [:]

    /// 股票数据缓存
    private var stocksCache: [String: (data: WatchlistItem, timestamp: Date)] = [:]
    
    /// 市场统计缓存
    private var statsCache: (data: MarketStats, timestamp: Date)?
    
    private init() {}
    
    // MARK: - 指数缓存

    /// 获取指定区域的缓存指数数据
    /// - Parameter region: 市场区域
    /// - Returns: 缓存的指数数据，如果过期则返回 nil
    func getCachedIndices(region: MarketRegion) -> [MarketIndex]? {
        guard let cache = indicesCache[region] else { return nil }

        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < cacheTimeout {
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
        if elapsed < cacheTimeout {
            return cache.data
        }
        
        // 缓存已过期
        stocksCache.removeValue(forKey: code)
        return nil
    }
    
    /// 设置股票数据缓存
    /// - Parameters:
    ///   - data: 股票数据
    ///   - code: 股票代码
    func setCachedStock(_ data: WatchlistItem, code: String) {
        stocksCache[code] = (data, Date())
    }
    
    /// 批量设置股票数据缓存
    /// - Parameter stocks: 股票数据数组
    func setCachedStocks(_ stocks: [WatchlistItem]) {
        let timestamp = Date()
        for stock in stocks {
            stocksCache[stock.code] = (stock, timestamp)
        }
    }
    
    // MARK: - 市场统计缓存
    
    /// 获取缓存的市场统计数据
    /// - Returns: 缓存的市场统计，如果过期则返回nil
    func getCachedStats() -> MarketStats? {
        guard let cache = statsCache else { return nil }
        
        let elapsed = Date().timeIntervalSince(cache.timestamp)
        if elapsed < cacheTimeout {
            return cache.data
        }
        
        // 缓存已过期
        statsCache = nil
        return nil
    }
    
    /// 设置市场统计缓存
    /// - Parameter data: 市场统计数据
    func setCachedStats(_ data: MarketStats) {
        statsCache = (data, Date())
    }
    
    // MARK: - 清除缓存
    
    /// 清除所有缓存
    func clearAll() {
        indicesCache.removeAll()
        stocksCache.removeAll()
        statsCache = nil
    }
    
    /// 清除指定股票的缓存
    /// - Parameter code: 股票代码
    func clearStock(code: String) {
        stocksCache.removeValue(forKey: code)
    }
}

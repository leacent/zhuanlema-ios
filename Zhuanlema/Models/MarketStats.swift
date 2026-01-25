/**
 * 市场统计数据模型
 * 用于市场总览卡片展示
 */
import Foundation

struct MarketStats {
    /// 上涨家数
    let upCount: Int
    
    /// 下跌家数
    let downCount: Int
    
    /// 平盘家数
    let flatCount: Int
    
    /// 总成交额（格式化字符串，如 "31,184亿"）
    let totalVolume: String
    
    /// 赚钱比例（0-1之间的小数，如 0.62 表示 62%）
    let winRate: Double
    
    /// 总股票数
    var totalCount: Int {
        upCount + downCount + flatCount
    }
    
    /// 上涨占比
    var upRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(upCount) / Double(totalCount)
    }
    
    /// 下跌占比
    var downRatio: Double {
        guard totalCount > 0 else { return 0 }
        return Double(downCount) / Double(totalCount)
    }
}

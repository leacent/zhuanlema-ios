/**
 * 热门股票榜单类型
 * 用于切换不同维度的排行榜
 */
import Foundation

enum HotStockType: String, CaseIterable, Identifiable {
    /// 涨幅榜
    case gainers = "gainers"
    
    /// 跌幅榜
    case losers = "losers"
    
    /// 活跃榜（成交量）
    case active = "active"
    
    var id: String { rawValue }
    
    /// 显示标题
    var title: String {
        switch self {
        case .gainers:
            return "涨幅榜"
        case .losers:
            return "跌幅榜"
        case .active:
            return "活跃榜"
        }
    }
    
    /// Tab显示文字
    var tabTitle: String {
        switch self {
        case .gainers:
            return "涨幅"
        case .losers:
            return "跌幅"
        case .active:
            return "活跃"
        }
    }
}

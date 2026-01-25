/**
 * 行情页面Tab类型
 * 用于顶部Tab切换
 */
import Foundation

enum MarketTab: String, CaseIterable, Identifiable {
    /// 行情Tab
    case market = "market"
    
    /// 自选Tab
    case watchlist = "watchlist"
    
    var id: String { rawValue }
    
    /// Tab显示标题
    var title: String {
        switch self {
        case .market:
            return "行情"
        case .watchlist:
            return "自选"
        }
    }
}

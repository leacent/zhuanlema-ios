/**
 * 自选股/行情列表项模型
 * 用于行情页自选列表展示；行情 API 对接后可扩展字段
 */
import Foundation

struct WatchlistItem: Identifiable {
    let id: String
    /// 股票名称
    var name: String
    /// 行情代码，如 sh600519、sz000001
    var code: String
    /// 现价
    var price: Double?
    /// 涨跌幅（如 2.5 表示 +2.5%）
    var changePercent: Double?
    /// 成交量（手或股，展示用）
    var volume: Int64?
    
    /// 显示用简短代码，如 600519、00700、AAPL
    var displayCode: String {
        if code.hasPrefix("sh") || code.hasPrefix("sz") {
            return String(code.dropFirst(2))
        }
        if code.hasPrefix("hk") {
            return String(code.dropFirst(2))
        }
        if code.hasPrefix("us") {
            return String(code.dropFirst(2))
        }
        return code
    }
}

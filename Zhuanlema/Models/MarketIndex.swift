/**
 * 大盘指数模型
 * 用于行情页顶部指数条展示（上证、深证、创业板等）
 */
import Foundation

struct MarketIndex: Identifiable {
    let id: String
    /// 指数名称，如 上证指数
    var name: String
    /// 行情代码，如 sh000001
    var code: String
    /// 最新点位
    var value: Double
    /// 涨跌幅（如 0.5 表示 +0.5%）
    var changePercent: Double
}

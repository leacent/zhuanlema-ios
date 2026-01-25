/**
 * 板块数据模型
 * 用于行业板块和概念板块的展示
 */
import Foundation

struct SectorItem: Identifiable, Codable {
    /// 板块代码
    let id: String
    
    /// 板块名称
    let name: String
    
    /// 涨跌幅（百分比）
    let changePercent: Double
    
    /// 领涨股名称
    let leadingStock: String
    
    /// 领涨股涨幅
    let leadingStockChange: Double?
    
    /// 成交额（可选）
    let volume: String?
    
    /// 是否上涨
    var isUp: Bool {
        changePercent >= 0
    }
    
    /// 格式化的涨跌幅字符串
    var formattedChangePercent: String {
        String(format: "%@%.2f%%", changePercent >= 0 ? "+" : "", changePercent)
    }
}

/// 板块类型
enum SectorType: String, CaseIterable {
    /// 行业板块
    case industry = "industry"
    
    /// 概念板块
    case concept = "concept"
    
    var title: String {
        switch self {
        case .industry:
            return "行业板块"
        case .concept:
            return "概念板块"
        }
    }
}

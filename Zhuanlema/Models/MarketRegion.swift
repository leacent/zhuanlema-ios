/**
 * 市场区域（行情页 A股/港股/美股 Tab）
 */
import Foundation

enum MarketRegion: String, CaseIterable, Identifiable {
    case aShare = "a_share"
    case hongKong = "hong_kong"
    case us = "us"

    var id: String { rawValue }

    /// Tab 显示标题
    var title: String {
        switch self {
        case .aShare: return "A股"
        case .hongKong: return "港股"
        case .us: return "美股"
        }
    }

    /// 指数区块标题（如「A股指数」）
    var indicesSectionTitle: String {
        switch self {
        case .aShare: return "A股指数"
        case .hongKong: return "港股指数"
        case .us: return "美股指数"
        }
    }
}

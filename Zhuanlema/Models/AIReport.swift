/**
 * AI 每日复盘报告数据模型
 * 对应 CloudBase ai_reports 集合
 */
import Foundation

struct AIReport: Codable, Identifiable {
    let id: String
    let date: String
    let type: String
    let marketData: MarketDataSnapshot?
    let sentimentData: SentimentSnapshot?
    let aiContent: AIContent?
    let model: String?
    let createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case date, type, marketData, sentimentData, aiContent, model, createdAt
    }

    /// 报告日期是否与今天一致（北京时间）
    var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return date == formatter.string(from: Date())
    }
}

struct MarketDataSnapshot: Codable {
    let shIndex: IndexQuote?
    let szIndex: IndexQuote?
    let cyIndex: IndexQuote?
}

struct IndexQuote: Codable {
    let name: String?
    let close: Double?
    let changePercent: Double?

    var changeText: String {
        guard let pct = changePercent else { return "--" }
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", pct))%"
    }

    var isUp: Bool { (changePercent ?? 0) >= 0 }
}

struct SentimentSnapshot: Codable {
    let totalCheckIns: Int
    let yesCount: Int
    let noCount: Int
    let yesPercent: Int
    let isSufficientSample: Bool?

    /// 客户端兜底判断：样本量 ≥ 30 才认为情绪百分比有统计意义（统计学大样本标准）
    static let minSampleSize = 30
    var hasSufficientSample: Bool {
        isSufficientSample ?? (totalCheckIns >= Self.minSampleSize)
    }
}

struct AIContent: Codable {
    let oneLiner: String?
    let summary: String?
    let insight: String?
    let outlook: String?
}

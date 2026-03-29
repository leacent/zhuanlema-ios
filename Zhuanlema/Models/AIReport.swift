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
}

struct AIContent: Codable {
    let oneLiner: String?
    let summary: String?
    let insight: String?
    let outlook: String?
}

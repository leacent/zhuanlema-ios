/**
 * 个人复盘日记数据模型
 * 对应 CloudBase trading_reviews 集合
 */
import Foundation

struct TradingReview: Codable, Identifiable {
    let id: String
    let userId: String
    let date: String
    let actions: [String]
    let drivers: [String]
    let emotions: [String]
    let content: String
    let satisfaction: Int
    let checkInResult: String?
    let checkInMagnitude: String?
    let createdAt: Double?
    let updatedAt: Double?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, date, actions, drivers, emotions, content
        case satisfaction, checkInResult, checkInMagnitude
        case createdAt, updatedAt
    }
}

// MARK: - 标签选项定义

enum ReviewAction: String, CaseIterable, Identifiable {
    case buy = "buy"
    case sell = "sell"
    case addPosition = "add_position"
    case reducePosition = "reduce_position"
    case hold = "hold"
    case empty = "empty"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .addPosition: return "加仓"
        case .reducePosition: return "减仓"
        case .hold: return "持仓观望"
        case .empty: return "空仓"
        }
    }

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle"
        case .sell: return "arrow.up.circle"
        case .addPosition: return "plus.circle"
        case .reducePosition: return "minus.circle"
        case .hold: return "eye"
        case .empty: return "moon.zzz"
        }
    }
}

enum ReviewDriver: String, CaseIterable, Identifiable {
    case planned = "planned"
    case intuition = "intuition"
    case news = "news"
    case following = "following"
    case technical = "technical"
    case fundamental = "fundamental"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .planned: return "计划内"
        case .intuition: return "盘感"
        case .news: return "消息面"
        case .following: return "跟风"
        case .technical: return "技术面"
        case .fundamental: return "基本面"
        }
    }
}

enum ReviewEmotion: String, CaseIterable, Identifiable {
    case calm = "calm"
    case excited = "excited"
    case anxious = "anxious"
    case regretful = "regretful"
    case fomo = "fomo"
    case frustrated = "frustrated"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calm: return "淡定"
        case .excited: return "兴奋"
        case .anxious: return "焦虑"
        case .regretful: return "后悔"
        case .fomo: return "FOMO"
        case .frustrated: return "不甘"
        }
    }

    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .excited: return "😄"
        case .anxious: return "😰"
        case .regretful: return "😫"
        case .fomo: return "🫣"
        case .frustrated: return "😤"
        }
    }
}

// MARK: - 满意度

enum ReviewSatisfaction: Int, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }
}

// MARK: - 列表展示用辅助

extension TradingReview {
    var actionLabels: [String] {
        actions.compactMap { raw in ReviewAction(rawValue: raw)?.label }
    }

    var driverLabels: [String] {
        drivers.compactMap { raw in ReviewDriver(rawValue: raw)?.label }
    }

    var emotionEmojis: [String] {
        emotions.compactMap { raw in ReviewEmotion(rawValue: raw)?.emoji }
    }

    var satisfactionEmoji: String {
        ReviewSatisfaction(rawValue: satisfaction)?.emoji ?? "😐"
    }

    var contentPreview: String {
        if content.isEmpty { return "" }
        return content.count > 60 ? String(content.prefix(60)) + "…" : content
    }

    var formattedDate: String {
        let parts = date.split(separator: "-")
        guard parts.count == 3 else { return date }
        return "\(parts[1])/\(parts[2])"
    }

    var weekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        guard let d = formatter.date(from: date) else { return "" }
        let weekday = Calendar.current.component(.weekday, from: d)
        let names = ["", "日", "一", "二", "三", "四", "五", "六"]
        return "周\(names[weekday])"
    }
}

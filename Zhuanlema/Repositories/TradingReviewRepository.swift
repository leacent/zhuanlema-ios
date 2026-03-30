/**
 * 个人复盘日记数据仓库
 * 负责复盘日记的 CRUD 及缓存管理
 */
import Foundation

class TradingReviewRepository {
    private let databaseService = CloudBaseDatabaseService.shared
    private let userRepository = UserRepository()

    /**
     * 保存复盘日记（创建或更新）
     */
    func save(
        date: String,
        actions: [String],
        drivers: [String],
        emotions: [String],
        content: String,
        satisfaction: Int,
        checkInResult: String? = nil,
        checkInMagnitude: String? = nil
    ) async throws -> TradingReview {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "TradingReviewRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.saveTradingReview(
            date: date,
            actions: actions,
            drivers: drivers,
            emotions: emotions,
            content: content,
            satisfaction: satisfaction,
            checkInResult: checkInResult,
            checkInMagnitude: checkInMagnitude,
            accessToken: token
        )
    }

    /**
     * 获取指定日期的复盘（用于编辑页加载已有数据）
     */
    func getReview(for date: String) async throws -> TradingReview? {
        guard let token = userRepository.getCurrentAccessToken() else { return nil }
        let list = try await databaseService.getTradingReviews(date: date, accessToken: token)
        return list.first
    }

    /**
     * 获取最近的复盘列表
     */
    func getRecentReviews(limit: Int = 20) async throws -> [TradingReview] {
        guard let token = userRepository.getCurrentAccessToken() else { return [] }
        return try await databaseService.getTradingReviews(limit: limit, accessToken: token)
    }

    /**
     * 获取某月的复盘记录
     */
    func getMonthReviews(year: Int, month: Int) async throws -> [TradingReview] {
        guard let token = userRepository.getCurrentAccessToken() else { return [] }
        return try await databaseService.getTradingReviews(year: year, month: month, accessToken: token)
    }
}

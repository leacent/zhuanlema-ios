/**
 * AI 数据仓库
 * 封装 AI 复盘报告和对话相关的数据访问
 */
import Foundation

class AIRepository {
    private let databaseService = CloudBaseDatabaseService.shared
    private let userRepository = UserRepository()

    /**
     * 获取每日报告
     * @param date YYYY-MM-DD，nil 返回最新
     */
    func getDailyReport(date: String? = nil) async throws -> AIReport {
        return try await databaseService.getDailyReport(date: date)
    }

    /**
     * 发送 AI 对话消息
     * @param message 用户消息
     * @param conversationId 对话 ID（续聊时传入）
     * @returns (回复文本, 对话 ID)
     */
    func sendChat(message: String, conversationId: String?) async throws -> (reply: String, conversationId: String) {
        let userId = userRepository.getCurrentUser()?.id ?? "anonymous"
        let response = try await databaseService.sendAIChat(userId: userId, message: message, conversationId: conversationId)
        return (response.reply, response.conversationId)
    }

    /**
     * 手动触发生成报告（调试用）
     */
    func generateReport(date: String? = nil, force: Bool = false) async throws -> AIReport {
        return try await databaseService.generateDailyReport(date: date, force: force)
    }

    /**
     * 提交 AI 回复反馈
     * @param conversationId 对话 ID
     * @param messageTimestamp 消息时间戳
     * @param feedback "positive" / "negative"
     */
    func submitFeedback(conversationId: String, messageTimestamp: Double, feedback: String) async throws {
        try await databaseService.submitAIChatFeedback(
            conversationId: conversationId,
            messageTimestamp: messageTimestamp,
            feedback: feedback
        )
    }
}

/**
 * AI 复盘视图模型
 * 管理每日报告加载、对话消息状态
 */
import Foundation
import SwiftUI
import Combine

@MainActor
class AIViewModel: ObservableObject {
    // MARK: - 每日报告

    @Published var dailyReport: AIReport?
    @Published var isLoadingReport = false
    @Published var reportError: String?

    // MARK: - 对话

    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var inputText = ""
    @Published var chatError: String?

    private var conversationId: String?
    private let aiRepository = AIRepository()

    init() {
        loadDailyReport()
    }

    // MARK: - 报告

    func loadDailyReport() {
        guard !isLoadingReport else { return }
        isLoadingReport = true
        reportError = nil

        Task {
            do {
                let report = try await aiRepository.getDailyReport()
                self.dailyReport = report
            } catch {
                self.reportError = error.localizedDescription
                print("⚠️ [AIViewModel] 加载报告失败: \(error.localizedDescription)")
            }
            self.isLoadingReport = false
        }
    }

    /// 首页摘要卡片用的一句话文本
    var summaryOneLiner: String {
        dailyReport?.aiContent?.oneLiner ?? "AI 复盘加载中…"
    }

    // MARK: - 对话

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }

        let userMsg = ChatMessage(role: "user", content: text, timestamp: Date().timeIntervalSince1970 * 1000)
        messages.append(userMsg)
        inputText = ""
        isGenerating = true
        chatError = nil

        Task {
            do {
                let (reply, convId) = try await aiRepository.sendChat(message: text, conversationId: conversationId)
                self.conversationId = convId
                let assistantMsg = ChatMessage(role: "assistant", content: reply, timestamp: Date().timeIntervalSince1970 * 1000)
                self.messages.append(assistantMsg)
            } catch {
                self.chatError = error.localizedDescription
                print("⚠️ [AIViewModel] 对话失败: \(error.localizedDescription)")
            }
            self.isGenerating = false
        }
    }

    func startNewConversation() {
        messages = []
        conversationId = nil
        chatError = nil
        inputText = ""
    }
}

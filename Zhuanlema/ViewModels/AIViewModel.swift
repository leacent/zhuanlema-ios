/**
 * AI 复盘视图模型
 * 管理每日报告加载、对话消息状态、流式打字机动画
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
    @Published var isStreaming = false
    @Published var inputText = ""
    @Published var chatError: String?

    /// messageId → feedback 的映射（本地状态）
    @Published var messageFeedback: [String: MessageFeedback] = [:]

    private var conversationId: String?
    private let aiRepository = AIRepository()
    private var streamingTask: Task<Void, Never>?
    private var fullReplyText = ""

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
        if isStreaming { completeStreamingImmediately() }

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
                self.isGenerating = false

                let assistantMsg = ChatMessage(role: "assistant", content: "", timestamp: Date().timeIntervalSince1970 * 1000)
                self.messages.append(assistantMsg)
                self.startStreamingAnimation(fullText: reply)
            } catch {
                self.chatError = error.localizedDescription
                self.isGenerating = false
                print("⚠️ [AIViewModel] 对话失败: \(error.localizedDescription)")
            }
        }
    }

    func startNewConversation() {
        completeStreamingImmediately()
        messages = []
        conversationId = nil
        chatError = nil
        inputText = ""
        messageFeedback = [:]
    }

    // MARK: - 流式打字机动画

    private func startStreamingAnimation(fullText: String) {
        fullReplyText = fullText
        isStreaming = true

        let totalChars = fullText.count
        guard totalChars > 0 else {
            isStreaming = false
            return
        }

        let targetSeconds = min(max(Double(totalChars) / 120.0, 1.5), 8.0)
        let intervalNs: UInt64 = 30_000_000
        let totalTicks = Int(targetSeconds * 1000.0 / 30.0)
        let charsPerTick = max(1, Int(ceil(Double(totalChars) / Double(totalTicks))))

        streamingTask = Task {
            var revealed = 0
            while revealed < totalChars {
                if Task.isCancelled { break }

                revealed = min(revealed + charsPerTick, totalChars)
                let endIndex = fullText.index(fullText.startIndex, offsetBy: revealed)
                if let lastIdx = messages.indices.last {
                    messages[lastIdx].content = String(fullText[..<endIndex])
                }

                try? await Task.sleep(nanoseconds: intervalNs)
            }

            if !Task.isCancelled, let lastIdx = messages.indices.last {
                messages[lastIdx].content = fullText
            }
            isStreaming = false
            fullReplyText = ""
        }
    }

    private func completeStreamingImmediately() {
        streamingTask?.cancel()
        streamingTask = nil
        if !fullReplyText.isEmpty, let lastIdx = messages.indices.last {
            messages[lastIdx].content = fullReplyText
        }
        isStreaming = false
        fullReplyText = ""
    }

    // MARK: - 反馈

    func submitFeedback(for message: ChatMessage, isPositive: Bool) {
        let feedback: MessageFeedback = isPositive ? .positive : .negative
        messageFeedback[message.id] = feedback

        guard let convId = conversationId else { return }
        Task {
            do {
                try await aiRepository.submitFeedback(
                    conversationId: convId,
                    messageTimestamp: message.timestamp ?? 0,
                    feedback: feedback.rawValue
                )
            } catch {
                print("⚠️ [AIViewModel] 反馈提交失败: \(error.localizedDescription)")
            }
        }
    }
}

/**
 * 首页视图模型
 * 统一管理打卡卡片 + AI 摘要卡片的状态
 * 帖子列表由 CommunityViewModel 独立管理
 */
import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - 打卡卡片状态

    @Published var hasCheckedInToday: Bool = false
    @Published var todayResult: String? = nil
    @Published var checkInStats: CheckInStats? = nil
    @Published var isSubmittingCheckIn: Bool = false
    @Published var showGoldConfetti: Bool = false
    @Published var showGrayConfetti: Bool = false

    // MARK: - AI 摘要卡片状态

    @Published var aiSummaryText: String = "加载中…"
    @Published var isAISummaryLoading: Bool = false

    private let checkInRepository = CheckInRepository()
    private let aiRepository = AIRepository()

    init() {
        loadInitialState()
    }

    /**
     * 加载初始状态：检查打卡 + 拉取统计 + 加载 AI 摘要
     */
    func loadInitialState() {
        hasCheckedInToday = checkInRepository.hasCheckedInToday()
        todayResult = loadTodayResult()
        Task {
            await loadCheckInStats()
            await loadAISummary()
        }
    }

    /**
     * 提交打卡
     *
     * @param magnitude 盈亏幅度: "big_win" / "small_win" / "neutral" / "small_loss" / "big_loss"
     * @param appState 用于同步全局打卡状态
     */
    func submitCheckIn(magnitude: String, appState: AppState) {
        guard !isSubmittingCheckIn else { return }
        isSubmittingCheckIn = true

        let result: String
        switch magnitude {
        case "big_win", "small_win": result = "yes"
        case "big_loss", "small_loss": result = "no"
        default: result = "neutral"
        }

        if result == "yes" {
            showGoldConfetti = true
        } else if result == "no" {
            showGrayConfetti = true
        }

        Task {
            do {
                _ = try await checkInRepository.submitCheckIn(result: result, magnitude: magnitude)
                checkInRepository.markCheckedInToday()
            } catch {
                checkInRepository.saveCheckInLocallyOnly(result: result, magnitude: magnitude)
                checkInRepository.markCheckedInToday()
                print("打卡记录失败(已落本地): \(error.localizedDescription)")
            }

            saveTodayResult(result)

            try? await Task.sleep(nanoseconds: 400_000_000)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasCheckedInToday = true
                todayResult = result
                appState.hasCheckedInToday = true
            }

            isSubmittingCheckIn = false
            await loadCheckInStats()
        }
    }

    /**
     * 拉取今日打卡统计
     */
    func loadCheckInStats() async {
        do {
            checkInStats = try await checkInRepository.getTodayStats()
        } catch {
            print("⚠️ [HomeViewModel] 加载打卡统计失败: \(error.localizedDescription)")
        }
    }

    /**
     * 加载 AI 一句话摘要（首页卡片展示）
     */
    func loadAISummary() async {
        isAISummaryLoading = true
        do {
            let report = try await aiRepository.getDailyReport()
            self.aiSummaryText = report.aiContent?.oneLiner ?? "暂无今日复盘"
        } catch {
            self.aiSummaryText = "点击查看 AI 复盘"
            print("⚠️ [HomeViewModel] 加载 AI 摘要失败: \(error.localizedDescription)")
        }
        isAISummaryLoading = false
    }

    // MARK: - Private

    private func saveTodayResult(_ result: String) {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        UserDefaults.standard.set(result, forKey: "checkInResult_\(today)")
    }

    private func loadTodayResult() -> String? {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        return UserDefaults.standard.string(forKey: "checkInResult_\(today)")
    }
}

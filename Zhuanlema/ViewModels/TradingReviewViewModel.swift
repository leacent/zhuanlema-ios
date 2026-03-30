/**
 * 个人复盘日记视图模型
 * 管理编辑页状态和历史列表
 */
import Foundation
import SwiftUI
import Combine

@MainActor
class TradingReviewViewModel: ObservableObject {
    // MARK: - 编辑状态

    @Published var selectedActions: Set<String> = []
    @Published var selectedDrivers: Set<String> = []
    @Published var selectedEmotions: Set<String> = []
    @Published var content: String = ""
    @Published var satisfaction: Int = 3
    @Published var reviewDate: String = ""

    // MARK: - 保存状态

    @Published var isSaving = false
    @Published var saveError: String?
    @Published var didSaveSuccessfully = false

    // MARK: - 历史列表

    @Published var reviews: [TradingReview] = []
    @Published var isLoadingHistory = false

    // MARK: - 关联打卡数据

    var checkInResult: String?
    var checkInMagnitude: String?

    private let repository = TradingReviewRepository()
    private var existingReview: TradingReview?

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        reviewDate = formatter.string(from: Date())
    }

    /// 是否有内容可以保存
    var canSave: Bool {
        !selectedActions.isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 编辑页操作

    func toggleAction(_ action: String) {
        if selectedActions.contains(action) {
            selectedActions.remove(action)
        } else {
            selectedActions.insert(action)
        }
    }

    func toggleDriver(_ driver: String) {
        if selectedDrivers.contains(driver) {
            selectedDrivers.remove(driver)
        } else {
            selectedDrivers.insert(driver)
        }
    }

    func toggleEmotion(_ emotion: String) {
        if selectedEmotions.contains(emotion) {
            selectedEmotions.remove(emotion)
        } else {
            selectedEmotions.insert(emotion)
        }
    }

    /**
     * 加载指定日期的已有复盘（用于编辑已有记录）
     */
    func loadExistingReview() {
        Task {
            if let review = try? await repository.getReview(for: reviewDate) {
                existingReview = review
                selectedActions = Set(review.actions)
                selectedDrivers = Set(review.drivers)
                selectedEmotions = Set(review.emotions)
                content = review.content
                satisfaction = review.satisfaction
                checkInResult = review.checkInResult
                checkInMagnitude = review.checkInMagnitude
            }
        }
    }

    /**
     * 保存复盘日记
     */
    func save() {
        guard canSave, !isSaving else { return }
        isSaving = true
        saveError = nil

        Task {
            do {
                let review = try await repository.save(
                    date: reviewDate,
                    actions: Array(selectedActions),
                    drivers: Array(selectedDrivers),
                    emotions: Array(selectedEmotions),
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    satisfaction: satisfaction,
                    checkInResult: checkInResult,
                    checkInMagnitude: checkInMagnitude
                )
                existingReview = review
                didSaveSuccessfully = true
            } catch {
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }

    /**
     * 重置编辑状态（新建时使用）
     */
    func resetEditor() {
        selectedActions = []
        selectedDrivers = []
        selectedEmotions = []
        content = ""
        satisfaction = 3
        saveError = nil
        didSaveSuccessfully = false
        existingReview = nil
    }

    // MARK: - 历史列表

    func loadHistory() {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true

        Task {
            do {
                reviews = try await repository.getRecentReviews(limit: 30)
            } catch {
                print("⚠️ [TradingReviewVM] 加载历史失败: \(error.localizedDescription)")
            }
            isLoadingHistory = false
        }
    }
}

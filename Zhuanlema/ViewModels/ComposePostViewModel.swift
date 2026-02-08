/**
 * 发布帖子视图模型
 * 管理发布流程：草稿、图片上传（并发+进度）、防抖、发布结果回调
 */
import Foundation
import Combine
import UIKit

@MainActor
class ComposePostViewModel: ObservableObject {
    // MARK: - Published State

    /// 帖子内容
    @Published var content: String = "" {
        didSet { scheduleDraftSave() }
    }
    /// 标签输入文本
    @Published var tagInput: String = "" {
        didSet { scheduleDraftSave() }
    }
    /// 已选择的图片
    @Published var selectedImages: [UIImage] = []
    /// 是否正在发布
    @Published var isPublishing: Bool = false
    /// 上传进度文案（如 "上传图片 2/5"）
    @Published var progressText: String?
    /// 发布错误信息
    @Published var publishError: String?
    /// 发布是否成功（用于 View 层关闭页面和触发反馈）
    @Published var publishSucceeded: Bool = false

    // MARK: - Config

    let maxImages = 9
    let maxContentLength = 500

    // MARK: - Callbacks

    /// 发布成功后回调，传回新帖子 ID 供列表页刷新
    var onPublishSuccess: ((String) -> Void)?

    // MARK: - Dependencies

    private let postRepository = PostRepository()
    private let storageService = CloudBaseStorageService.shared

    /// 草稿 key
    private static let draftContentKey = "compose_draft_content"
    private static let draftTagsKey = "compose_draft_tags"

    /// 草稿保存防抖
    private var draftSaveTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        loadDraft()
    }

    // MARK: - Computed Properties

    /// 去重后的标签数组
    var parsedTags: [String] {
        let raw = tagInput
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // 去重并保持顺序
        var seen = Set<String>()
        return raw.filter { seen.insert($0).inserted }
    }

    /// 是否可以发布
    var canPublish: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxContentLength && !isPublishing
    }

    /// 是否有未保存的内容（用于关闭确认）
    var hasUnsavedContent: Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty || !selectedImages.isEmpty || !tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Publish

    /**
     * 发布帖子
     * 1. 并发上传图片 + 进度更新
     * 2. 调用 createPost
     * 3. 成功后清除草稿并回调
     */
    func publish() {
        guard canPublish else { return }

        isPublishing = true
        publishError = nil
        progressText = nil

        Task {
            do {
                // Step 1: 并发上传图片
                let imageURLs: [String]
                if selectedImages.isEmpty {
                    imageURLs = []
                } else {
                    imageURLs = try await uploadImagesConcurrently()
                }

                // Step 2: 创建帖子
                progressText = "正在发布..."
                let postId = try await postRepository.createPost(
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageURLs: imageURLs,
                    tags: parsedTags
                )

                // Step 3: 成功
                clearDraft()
                progressText = nil
                publishSucceeded = true
                onPublishSuccess?(postId)

            } catch {
                publishError = error.localizedDescription
                progressText = nil
            }

            isPublishing = false
        }
    }

    // MARK: - Concurrent Image Upload

    /**
     * 使用 TaskGroup 并发上传图片，实时更新进度
     */
    private func uploadImagesConcurrently() async throws -> [String] {
        let images = selectedImages
        let total = images.count
        let service = storageService

        // 在后台并发上传，收集 (索引, URL) 对
        let indexedResults = try await withThrowingTaskGroup(
            of: (Int, String).self,
            returning: [(Int, String)].self
        ) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let url = try await service.uploadImage(image)
                    return (index, url)
                }
            }

            var collected: [(Int, String)] = []
            for try await result in group {
                collected.append(result)
                // 更新进度
                let completedCount = collected.count
                self.progressText = "上传图片 \(completedCount)/\(total)"
            }
            return collected
        }

        // 按原始顺序排列
        return indexedResults.sorted { $0.0 < $1.0 }.map { $0.1 }
    }

    // MARK: - Draft

    /**
     * 防抖保存草稿（500ms）
     */
    private func scheduleDraftSave() {
        draftSaveTask?.cancel()
        draftSaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            UserDefaults.standard.set(content, forKey: Self.draftContentKey)
            UserDefaults.standard.set(tagInput, forKey: Self.draftTagsKey)
        }
    }

    /**
     * 加载草稿
     */
    private func loadDraft() {
        if let savedContent = UserDefaults.standard.string(forKey: Self.draftContentKey), !savedContent.isEmpty {
            content = savedContent
        }
        if let savedTags = UserDefaults.standard.string(forKey: Self.draftTagsKey), !savedTags.isEmpty {
            tagInput = savedTags
        }
    }

    /**
     * 清除草稿
     */
    func clearDraft() {
        draftSaveTask?.cancel()
        UserDefaults.standard.removeObject(forKey: Self.draftContentKey)
        UserDefaults.standard.removeObject(forKey: Self.draftTagsKey)
        content = ""
        tagInput = ""
        selectedImages = []
    }
}

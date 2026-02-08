/**
 * 帖子详情视图模型
 * 管理评论列表、发表评论、点赞、删除等业务逻辑
 */
import Foundation
import Combine
import UIKit

@MainActor
class PostDetailViewModel: ObservableObject {
    /// 帖子
    let post: Post
    /// 评论数变化回调
    var onCommentCountChanged: ((Int) -> Void)?

    /// 评论列表
    @Published var comments: [Comment] = []
    /// 评论总数
    @Published var commentCount: Int
    /// 是否正在加载评论
    @Published var isLoadingComments = false
    /// 是否正在加载更多评论
    @Published var isLoadingMoreComments = false
    /// 是否有更多评论
    @Published var hasMoreComments = true
    /// 评论错误信息
    @Published var commentErrorMessage: String?
    /// 正在回复的评论
    @Published var replyingTo: Comment?
    /// 是否正在发送评论
    @Published var isSendingComment = false
    /// 待删除的评论
    @Published var pendingDelete: Comment?
    /// 是否显示删除确认
    @Published var showDeleteConfirm = false
    /// 评论排序方式
    @Published var commentSortMode: String = "latest"

    private let commentRepository = CommentRepository()
    private let userRepository = UserRepository()
    private var commentsOffset = 0
    private let commentsPageSize = 20

    init(post: Post, onCommentCountChanged: ((Int) -> Void)? = nil) {
        self.post = post
        self.onCommentCountChanged = onCommentCountChanged
        self.commentCount = post.commentCount
    }

    // MARK: - Computed Properties

    /// 一级评论（无 parentId）
    var topLevelComments: [Comment] {
        comments
            .filter { ($0.parentId ?? "").isEmpty }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// 获取某条一级评论的子回复
    func replies(for parent: Comment) -> [Comment] {
        comments
            .filter { $0.parentId == parent.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// 当前用户是否可以删除该评论
    func canDelete(comment: Comment, isLoggedIn: Bool) -> Bool {
        guard isLoggedIn, let uid = userRepository.getCurrentUser()?.id else { return false }
        return comment.userId == uid
    }

    // MARK: - Load Comments

    /**
     * 切换评论排序方式
     */
    func switchCommentSort(_ mode: String) {
        guard mode != commentSortMode else { return }
        commentSortMode = mode
        loadInitialComments()
    }

    /**
     * 加载初始评论
     */
    func loadInitialComments() {
        guard !isLoadingComments else { return }
        isLoadingComments = true
        isLoadingMoreComments = false
        commentErrorMessage = nil
        commentsOffset = 0
        hasMoreComments = true
        Task {
            do {
                let page = try await commentRepository.getComments(postId: post.id, limit: commentsPageSize, offset: 0, sortBy: commentSortMode)
                comments = page
                commentsOffset = page.count
                hasMoreComments = page.count >= commentsPageSize
            } catch {
                commentErrorMessage = error.localizedDescription
            }
            isLoadingComments = false
        }
    }

    /**
     * 加载更多评论
     */
    func loadMoreComments() {
        guard hasMoreComments, !isLoadingComments, !isLoadingMoreComments else { return }
        isLoadingMoreComments = true
        Task {
            do {
                let page = try await commentRepository.getComments(postId: post.id, limit: commentsPageSize, offset: commentsOffset, sortBy: commentSortMode)
                if !page.isEmpty {
                    comments.append(contentsOf: page)
                }
                commentsOffset += page.count
                hasMoreComments = page.count >= commentsPageSize
            } catch {
                commentErrorMessage = error.localizedDescription
            }
            isLoadingMoreComments = false
        }
    }

    // MARK: - Send Comment

    /**
     * 发送评论
     *
     * @param text 评论内容
     */
    func sendComment(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSendingComment else { return }
        isSendingComment = true
        Task {
            do {
                let newCount = try await commentRepository.createComment(postId: post.id, content: trimmed, parentId: replyingTo?.id)
                commentCount = newCount
                onCommentCountChanged?(newCount)
                replyingTo = nil
                loadInitialComments()
            } catch {
                commentErrorMessage = error.localizedDescription
            }
            isSendingComment = false
        }
    }

    // MARK: - Like / Unlike Comment

    /**
     * 切换评论点赞状态（乐观更新）
     */
    func toggleLike(comment: Comment) {
        guard let idx = comments.firstIndex(where: { $0.id == comment.id }) else { return }

        // 乐观更新
        let wasLiked = comment.isLiked
        let oldCount = comment.likeCount
        comments[idx].isLiked = !wasLiked
        comments[idx].likeCount = wasLiked ? max(0, oldCount - 1) : oldCount + 1

        Task {
            do {
                let result: (commentId: String, likeCount: Int, isLiked: Bool)
                if wasLiked {
                    result = try await commentRepository.unlikeComment(commentId: comment.id)
                } else {
                    result = try await commentRepository.likeComment(commentId: comment.id)
                }
                if let i = comments.firstIndex(where: { $0.id == result.commentId }) {
                    comments[i].likeCount = result.likeCount
                    comments[i].isLiked = result.isLiked
                }
            } catch {
                // 回滚
                if let i = comments.firstIndex(where: { $0.id == comment.id }) {
                    comments[i].isLiked = wasLiked
                    comments[i].likeCount = oldCount
                }
                commentErrorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Delete Comment

    /**
     * 请求删除评论（弹出确认）
     */
    func requestDelete(comment: Comment) {
        pendingDelete = comment
        showDeleteConfirm = true
    }

    /**
     * 执行撤回评论
     */
    func retract(comment: Comment) {
        Task {
            do {
                let result = try await commentRepository.deleteComment(commentId: comment.id)
                if let idx = comments.firstIndex(where: { $0.id == result.commentId }) {
                    comments[idx].isDeleted = true
                    comments[idx].deletedAt = Date().timeIntervalSince1970 * 1000
                    comments[idx].content = ""
                    comments[idx].likeCount = 0
                    comments[idx].isLiked = false
                }
                if let newCount = result.commentCount {
                    commentCount = newCount
                    onCommentCountChanged?(newCount)
                }
            } catch {
                commentErrorMessage = error.localizedDescription
            }
            pendingDelete = nil
        }
    }

    // MARK: - Copy

    /**
     * 复制评论内容
     */
    func copy(comment: Comment) {
        UIPasteboard.general.string = comment.isDeleted ? "该评论已删除" : comment.content
    }
}

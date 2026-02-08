/**
 * 社区视图模型
 * 处理帖子列表、发布等业务逻辑
 */
import Foundation
import Combine
import UIKit

/// 帖子排序方式
enum PostSortMode: String, CaseIterable {
    case latest = "latest"
    case hot = "hot"

    var title: String {
        switch self {
        case .latest: return "最新"
        case .hot: return "热度"
        }
    }
}

@MainActor
class CommunityViewModel: ObservableObject {
    /// 帖子列表
    @Published var posts: [Post] = []
    /// 当前排序方式
    @Published var sortMode: PostSortMode = .latest
    /// 是否正在加载
    @Published var isLoading: Bool = false
    /// 是否正在刷新
    @Published var isRefreshing: Bool = false
    /// 错误消息
    @Published var errorMessage: String?
    /// 是否显示发布页面
    @Published var showComposePage: Bool = false
    
    private let postRepository = PostRepository()
    private let pageSize = 20
    /// 游标分页：下一页游标值
    private var nextCursor: Double?
    /// 是否还有更多数据
    private var hasMore = true
    
    init() {
        loadPosts()
    }
    
    /**
     * 切换排序方式并重新加载
     *
     * @param mode 排序方式
     */
    func switchSort(_ mode: PostSortMode) {
        guard mode != sortMode else { return }
        sortMode = mode
        refresh()
    }

    /**
     * 加载帖子列表（游标分页）
     */
    func loadPosts() {
        guard !isLoading, hasMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 [CommunityViewModel] 加载帖子，cursor: \(String(describing: nextCursor)), sort: \(sortMode.rawValue)")
                let result = try await postRepository.getPosts(limit: pageSize, sortBy: sortMode.rawValue, cursor: nextCursor)
                
                print("✅ [CommunityViewModel] 成功获取 \(result.posts.count) 条帖子")
                
                if nextCursor == nil {
                    // 首页
                    posts = result.posts
                } else {
                    posts.append(contentsOf: result.posts)
                }
                
                nextCursor = result.nextCursor
                hasMore = result.posts.count >= pageSize && result.nextCursor != nil
            } catch {
                let errorMsg = error.localizedDescription
                print("❌ [CommunityViewModel] 加载帖子失败: \(errorMsg)")
                errorMessage = errorMsg
            }
            
            isLoading = false
        }
    }
    
    /**
     * 刷新列表
     */
    func refresh() {
        isRefreshing = true
        nextCursor = nil
        hasMore = true
        
        Task {
            do {
                let result = try await postRepository.getPosts(limit: pageSize, sortBy: sortMode.rawValue, cursor: nil)
                posts = result.posts
                nextCursor = result.nextCursor
                hasMore = result.posts.count >= pageSize && result.nextCursor != nil
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isRefreshing = false
        }
    }
    
    /**
     * 发布成功后刷新列表（由 ComposePostView 通过回调触发）
     */
    func onPostPublished() {
        showComposePage = false
        refresh()
    }
    
    /**
     * 更新指定帖子的评论数（由详情页回调触发）
     *
     * @param postId 帖子 ID
     * @param count 最新评论数
     */
    func updateCommentCount(postId: String, count: Int) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].commentCount = count
        }
    }

    /**
     * 删除帖子（需登录，仅本人）
     *
     * @param post 要删除的帖子
     */
    func deletePost(_ post: Post) {
        Task {
            do {
                try await postRepository.deletePost(postId: post.id)
                // 从列表中移除
                posts.removeAll { $0.id == post.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /**
     * 点赞 / 取消点赞（乐观更新 + 失败回滚）
     *
     * @param post 帖子；根据 post.isLiked 决定执行点赞或取消点赞
     */
    func likePost(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        // 乐观更新：立即反映到 UI
        let wasLiked = post.isLiked
        let oldCount = post.likeCount
        posts[index].isLiked = !wasLiked
        posts[index].likeCount = wasLiked ? max(0, oldCount - 1) : oldCount + 1

        Task {
            do {
                let result: (likeCount: Int, isLiked: Bool)
                if wasLiked {
                    result = try await postRepository.unlikePost(postId: post.id)
                } else {
                    result = try await postRepository.likePost(postId: post.id)
                }
                // 用服务器真实值覆盖
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].likeCount = result.likeCount
                    posts[idx].isLiked = result.isLiked
                }
            } catch {
                // 失败回滚
                if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[idx].isLiked = wasLiked
                    posts[idx].likeCount = oldCount
                }
                errorMessage = error.localizedDescription
            }
        }
    }
}

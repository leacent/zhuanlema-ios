/**
 * 社区视图模型
 * 处理帖子列表、发布等业务逻辑
 */
import Foundation
import Combine
import UIKit

@MainActor
class CommunityViewModel: ObservableObject {
    /// 帖子列表
    @Published var posts: [Post] = []
    /// 是否正在加载
    @Published var isLoading: Bool = false
    /// 是否正在刷新
    @Published var isRefreshing: Bool = false
    /// 错误消息
    @Published var errorMessage: String?
    /// 是否显示发布页面
    @Published var showComposePage: Bool = false
    
    private let postRepository = PostRepository()
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        loadPosts()
    }
    
    /**
     * 加载帖子列表
     */
    func loadPosts() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 [CommunityViewModel] 开始加载帖子，page: \(currentPage), limit: \(pageSize)")
                let newPosts = try await postRepository.getPosts(limit: pageSize, offset: currentPage * pageSize)
                
                print("✅ [CommunityViewModel] 成功获取 \(newPosts.count) 条帖子")
                
                if currentPage == 0 {
                    posts = newPosts
                } else {
                    posts.append(contentsOf: newPosts)
                }
                
                currentPage += 1
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
        currentPage = 0
        
        Task {
            do {
                posts = try await postRepository.getPosts(limit: pageSize, offset: 0)
                currentPage = 1
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isRefreshing = false
        }
    }
    
    /**
     * 发布帖子
     *
     * @param content 内容
     * @param images 图片列表
     * @param tags 标签列表
     */
    func publishPost(content: String, images: [UIImage], tags: [String]) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await postRepository.createPost(content: content, images: images, tags: tags)
                
                // 发布成功，刷新列表
                showComposePage = false
                refresh()
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    /**
     * 点赞 / 取消点赞（需登录）
     *
     * @param post 帖子；根据 post.isLiked 决定执行点赞或取消点赞
     */
    func likePost(_ post: Post) {
        Task {
            do {
                let result: (likeCount: Int, isLiked: Bool)
                if post.isLiked {
                    result = try await postRepository.unlikePost(postId: post.id)
                } else {
                    result = try await postRepository.likePost(postId: post.id)
                }
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index].likeCount = result.likeCount
                    posts[index].isLiked = result.isLiked
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

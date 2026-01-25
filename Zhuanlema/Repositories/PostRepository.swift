/**
 * 帖子数据仓库
 * 负责帖子相关的数据访问
 */
import Foundation
import UIKit

class PostRepository {
    private let databaseService = CloudBaseDatabaseService.shared
    private let storageService = CloudBaseStorageService.shared
    private let userRepository = UserRepository()
    
    /**
     * 获取帖子列表（已登录时会带上点赞状态）
     *
     * @param limit 每页数量
     * @param offset 偏移量
     * @returns 帖子列表
     */
    func getPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        let token = userRepository.getCurrentAccessToken()
        return try await databaseService.getPosts(limit: limit, offset: offset, accessToken: token)
    }
    
    /**
     * 发布帖子
     *
     * @param content 内容
     * @param images 图片数组
     * @param tags 标签列表
     * @returns 帖子ID
     */
    func createPost(content: String, images: [UIImage], tags: [String]) async throws -> String {
        guard let user = userRepository.getCurrentUser() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        // 上传图片
        let imageURLs = images.isEmpty ? [] : try await storageService.uploadImages(images)
        
        // 创建帖子
        return try await databaseService.createPost(
            userId: user.id,
            content: content,
            images: imageURLs,
            tags: tags
        )
    }
    
    /**
     * 点赞帖子（需登录）
     * @returns 更新后的 likeCount 与 isLiked
     */
    func likePost(postId: String) async throws -> (likeCount: Int, isLiked: Bool) {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.likePost(postId: postId, accessToken: token)
    }

    /**
     * 取消点赞（需登录）
     */
    func unlikePost(postId: String) async throws -> (likeCount: Int, isLiked: Bool) {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.unlikePost(postId: postId, accessToken: token)
    }
}

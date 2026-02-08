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
     * 获取帖子列表（游标分页，已登录时带上点赞状态）
     *
     * @param limit 每页数量
     * @param sortBy 排序方式："latest"（最新）或 "hot"（热度）
     * @param cursor 游标值；首页传 nil
     * @returns 帖子列表和下一页游标
     */
    func getPosts(limit: Int = 20, sortBy: String = "latest", cursor: Double? = nil) async throws -> (posts: [Post], nextCursor: Double?) {
        let token = userRepository.getCurrentAccessToken()
        return try await databaseService.getPosts(limit: limit, sortBy: sortBy, cursor: cursor, accessToken: token)
    }
    
    /**
     * 发布帖子（传入 UIImage，内部上传后创建）
     *
     * @param content 内容
     * @param images 图片数组
     * @param tags 标签列表
     * @returns 帖子ID
     */
    func createPost(content: String, images: [UIImage], tags: [String]) async throws -> String {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        // 上传图片
        let imageURLs = images.isEmpty ? [] : try await storageService.uploadImages(images)
        
        // 创建帖子
        return try await databaseService.createPost(
            content: content,
            images: imageURLs,
            tags: tags,
            accessToken: token
        )
    }

    /**
     * 发布帖子（传入已上传的图片 URL）
     *
     * @param content 内容
     * @param imageURLs 已上传的图片 URL 列表
     * @param tags 标签列表
     * @returns 帖子ID
     */
    func createPost(content: String, imageURLs: [String], tags: [String]) async throws -> String {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        return try await databaseService.createPost(
            content: content,
            images: imageURLs,
            tags: tags,
            accessToken: token
        )
    }
    
    /**
     * 删除帖子（需登录，仅本人）
     *
     * @param postId 帖子 ID
     */
    func deletePost(postId: String) async throws {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "PostRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        try await databaseService.deletePost(postId: postId, accessToken: token)
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

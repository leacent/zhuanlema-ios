/**
 * 评论数据仓库
 */
import Foundation
import Combine

class CommentRepository {
    private let databaseService = CloudBaseDatabaseService.shared
    private let userRepository = UserRepository()

    func getComments(postId: String, limit: Int = 20, offset: Int = 0, sortBy: String = "latest") async throws -> [Comment] {
        let token = userRepository.getCurrentAccessToken()
        return try await databaseService.getComments(postId: postId, limit: limit, offset: offset, sortBy: sortBy, accessToken: token)
    }

    func createComment(postId: String, content: String, parentId: String? = nil) async throws -> Int {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "CommentRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.createComment(postId: postId, content: content, parentId: parentId, accessToken: token)
    }

    func likeComment(commentId: String) async throws -> (commentId: String, likeCount: Int, isLiked: Bool) {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "CommentRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.likeComment(commentId: commentId, accessToken: token)
    }

    func unlikeComment(commentId: String) async throws -> (commentId: String, likeCount: Int, isLiked: Bool) {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "CommentRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.unlikeComment(commentId: commentId, accessToken: token)
    }

    func deleteComment(commentId: String) async throws -> (commentId: String, commentCount: Int?) {
        guard let token = userRepository.getCurrentAccessToken() else {
            throw NSError(domain: "CommentRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先登录"])
        }
        return try await databaseService.deleteComment(commentId: commentId, accessToken: token)
    }
}

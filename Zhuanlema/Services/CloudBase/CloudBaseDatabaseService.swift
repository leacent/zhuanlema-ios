/**
 * CloudBase 数据库服务
 * 封装数据库 CRUD 操作
 */
import Foundation

/// 云函数响应结构（通用）
struct CloudFunctionResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
}

class CloudBaseDatabaseService {
    static let shared = CloudBaseDatabaseService()
    
    private init() {}
    
    /**
     * 创建打卡记录
     *
     * @param userId 用户ID
     * @param result 打卡结果 ("yes" 或 "no")
     * @returns 打卡记录ID
     */
    func createCheckIn(userId: String, result: String) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let url = CloudBaseConfig.functionURL(name: "createCheckIn")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params: [String: Any] = [
            "userId": userId,
            "result": result,
            "date": today
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
        }
        
        // 我们只需要知道是否成功，云函数返回的是 CloudFunctionResponse 结构
        struct CreateCheckInResponse: Codable {
            let success: Bool
            let message: String?
        }
        
        let apiResult = try JSONDecoder().decode(CreateCheckInResponse.self, from: data)
        
        if apiResult.success {
            return "success"
        } else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResult.message ?? "打卡失败"])
        }
    }
    
    /**
     * 获取今日打卡统计
     *
     * @returns 打卡统计数据
     */
    func getTodayCheckInStats() async throws -> CheckInStats {
        let url = CloudBaseConfig.functionURL(name: "getTodayCheckInStats")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
        }
        
        let result = try JSONDecoder().decode(CloudFunctionResponse<CheckInStats>.self, from: data)
        
        guard result.success, let stats = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取统计失败"])
        }
        
        return stats
    }
    
    /**
     * 获取帖子列表（通过 HTTP API + Publishable Key）
     *
     * @param limit 每页数量
     * @param offset 偏移量
     * @returns 帖子列表
     */
    func getPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key（云开发控制台 → ApiKey 管理）"
            print("❌ [CloudBaseDatabaseService] \(msg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        struct PostsData: Codable {
            let posts: [Post]
        }

        let body: [String: Any] = ["limit": limit, "offset": offset]
        let result: CloudFunctionResponse<PostsData> = try await CloudBaseHTTPClient.call(name: "getPosts", body: body)

        guard result.success, let posts = result.data?.posts else {
            let errorMsg = result.message ?? "获取帖子列表失败"
            print("❌ [CloudBaseDatabaseService] getPosts 失败: \(errorMsg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        print("✅ [CloudBaseDatabaseService] getPosts 成功，获取到 \(posts.count) 条帖子")
        return posts
    }
    
    /**
     * 创建帖子
     *
     * @param userId 用户ID
     * @param content 内容
     * @param images 图片URL列表
     * @param tags 标签列表
     * @returns 帖子ID
     */
    func createPost(userId: String, content: String, images: [String], tags: [String]) async throws -> String {
        let url = CloudBaseConfig.functionURL(name: "createPost")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "content": content,
            "images": images,
            "tags": tags
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败"])
        }
        
        struct CreatePostData: Codable {
            let postId: String
        }
        
        let result = try JSONDecoder().decode(CloudFunctionResponse<CreatePostData>.self, from: data)
        
        guard result.success, let postData = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "发布失败"])
        }
        
        return postData.postId
    }
}

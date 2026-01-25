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
     * 创建打卡记录并持久化到 check_ins，与 user 绑定
     *
     * @param userId 用户ID
     * @param result 打卡结果 ("yes" 或 "no")
     * @param date 日期 yyyy-MM-dd，nil 表示当天
     * @returns 打卡记录ID
     */
    func createCheckIn(userId: String, result: String, date: String? = nil) async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = date ?? dateFormatter.string(from: Date())

        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key"
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        struct CreateCheckInResult: Codable {
            let success: Bool
            let message: String?
        }

        let params: [String: Any] = [
            "userId": userId,
            "result": result,
            "date": dateStr
        ]
        
        let apiResult: CreateCheckInResult = try await CloudBaseHTTPClient.call(name: "createCheckIn", body: params)
        
        if apiResult.success {
            return "success"
        } else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResult.message ?? "打卡失败"])
        }
    }
    
    /**
     * 获取今日打卡统计
     * 通过 CloudBase 网关调用云函数 getTodayCheckInStats（Publishable Key 鉴权）
     *
     * @returns 打卡统计数据
     */
    func getTodayCheckInStats() async throws -> CheckInStats {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let result: CloudFunctionResponse<CheckInStats> = try await CloudBaseHTTPClient.call(name: "getTodayCheckInStats", body: [:])
        guard result.success, let stats = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取统计失败"])
        }
        return stats
    }

    /**
     * 获取用户某月打卡记录（用于日历展示）
     * @param userId 用户ID
     * @param year 年
     * @param month 月（1-12）
     */
    func getCheckInHistory(userId: String, year: Int, month: Int) async throws -> [CheckIn] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let body: [String: Any] = ["userId": userId, "year": year, "month": month]
        let result: CloudFunctionResponse<[CheckIn]> = try await CloudBaseHTTPClient.call(name: "getCheckInHistory", body: body)
        guard result.success, let list = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取打卡记录失败"])
        }
        return list
    }
    
    /**
     * 获取用户资料统计（打卡数、帖子数、点赞总数）
     *
     * @param userId 用户ID
     * @returns UserProfileStats
     */
    func getUserStats(userId: String) async throws -> UserProfileStats {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key"
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let body: [String: Any] = ["userId": userId]
        let result: CloudFunctionResponse<UserProfileStats> = try await CloudBaseHTTPClient.call(name: "getUserStats", body: body)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取用户统计失败"])
        }
        return data
    }
    
    /**
     * 获取当前用户资料（需传 accessToken）
     * 使用 Publishable Key 鉴权 + body 内 access_token，避免网关 403
     * 需在控制台策略中允许 getProfile 被当前 Api Key 调用
     * @param phoneNumberForNewUser 可选，验证码注册后首次拉资料时传入，会写入 users 表
     */
    func getProfile(accessToken: String, phoneNumberForNewUser: String? = nil) async throws -> User {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key；编辑资料依赖 getProfile/updateProfile/uploadAvatar 云函数"])
        }
        struct GetProfileResult: Codable { let success: Bool; let message: String?; let data: GetProfileData? }
        var body: [String: Any] = [:]
        if let phone = phoneNumberForNewUser, !phone.isEmpty {
            body["phone_number"] = phone
        }
        let result: GetProfileResult = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "getProfile", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取资料失败"])
        }
        #if DEBUG
        let avatarPreview = data.avatar.isEmpty ? "(empty)" : String(data.avatar.prefix(60)) + (data.avatar.count > 60 ? "…" : "")
        print("[getProfile] 收到 avatar.len=\(data.avatar.count) avatar=\(avatarPreview)")
        #endif
        return data.toUser()
    }

    /**
     * 更新用户资料（云函数 updateProfile，需传 accessToken）
     * Body: nickname?, avatar?, phone_number?；access_token 由客户端放入 body
     * 需在控制台策略中允许 updateProfile 被当前 Api Key 调用
     * @param phoneNumber 可选，仅当老用户登录时补写手机号使用
     */
    func updateProfile(nickname: String?, avatar: String?, phoneNumber: String? = nil, accessToken: String) async throws {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key；编辑资料依赖 getProfile/updateProfile/uploadAvatar 云函数"])
        }
        var body: [String: Any] = [:]
        if let n = nickname, !n.isEmpty { body["nickname"] = n }
        if let a = avatar { body["avatar"] = a }
        if let p = phoneNumber, !p.isEmpty { body["phone_number"] = p }
        struct UpdateResult: Codable { let success: Bool; let message: String? }
        let result: UpdateResult = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "updateProfile", body: body, accessToken: accessToken)
        if !result.success {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "更新失败"])
        }
    }

    /**
     * 上传头像（云函数 uploadAvatar，需传 accessToken）
     * @param imageBase64 图片 base64，可选带 data:image/jpeg;base64, 前缀
     * @returns url 与 fileID；应把 fileID 传给 updateProfile(avatar: fileID)，以便 getProfile 时生成未过期链接
     * 需在控制台策略中允许 uploadAvatar 被当前 Api Key 调用
     */
    func uploadAvatar(accessToken: String, imageBase64: String) async throws -> (url: String, fileID: String) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key；编辑资料依赖 getProfile/updateProfile/uploadAvatar 云函数"])
        }
        struct RawResult: Codable {
            let success: Bool
            let url: String?
            let fileID: String?
            let message: String?
        }
        let body: [String: Any] = ["imageBase64": imageBase64]
        let result: RawResult = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "uploadAvatar", body: body, accessToken: accessToken)
        guard result.success else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "上传失败"])
        }
        guard let url = result.url, !url.isEmpty else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未返回头像链接"])
        }
        guard let fileID = result.fileID, !fileID.isEmpty else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未返回 fileID"])
        }
        return (url, fileID)
    }
    
    /**
     * 获取用户通知列表
     */
    func getNotifications(userId: String, limit: Int = 20, offset: Int = 0) async throws -> [NotificationItem] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        struct NotificationsData: Codable { let notifications: [NotificationItem] }
        let body: [String: Any] = ["userId": userId, "limit": limit, "offset": offset]
        let result: CloudFunctionResponse<NotificationsData> = try await CloudBaseHTTPClient.call(name: "getNotifications", body: body)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取通知失败"])
        }
        return data.notifications
    }
    
    /**
     * 标记通知已读
     */
    func markNotificationRead(notificationId: String, userId: String) async throws {
        let body: [String: Any] = ["notificationId": notificationId, "userId": userId]
        struct MarkReadResult: Codable { let success: Bool; let message: String? }
        let result: MarkReadResult = try await CloudBaseHTTPClient.call(name: "markNotificationRead", body: body)
        if !result.success {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "操作失败"])
        }
    }
    
    /**
     * 提交用户反馈
     */
    func submitFeedback(content: String, contact: String?) async throws {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        var body: [String: Any] = ["content": content]
        if let c = contact, !c.isEmpty { body["contact"] = c }
        struct SubmitResult: Codable { let success: Bool; let message: String? }
        let result: SubmitResult = try await CloudBaseHTTPClient.call(name: "submitFeedback", body: body)
        if !result.success {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "提交失败"])
        }
    }
    
    /**
     * 获取帖子列表（通过 HTTP API + Publishable Key）
     * 若传入 accessToken，云函数会返回 likedPostIds，并合并进 post.isLiked
     *
     * @param limit 每页数量
     * @param offset 偏移量
     * @param accessToken 可选；登录用户 token 用于拉取当前用户点赞状态
     * @returns 帖子列表
     */
    func getPosts(limit: Int = 20, offset: Int = 0, accessToken: String? = nil) async throws -> [Post] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key（云开发控制台 → ApiKey 管理）"
            print("❌ [CloudBaseDatabaseService] \(msg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }

        struct PostsData: Codable {
            let posts: [Post]
            let likedPostIds: [String]?
        }

        var body: [String: Any] = ["limit": limit, "offset": offset]
        if let token = accessToken, !token.isEmpty {
            body["access_token"] = token
        }
        let result: CloudFunctionResponse<PostsData> = try await CloudBaseHTTPClient.call(name: "getPosts", body: body)

        guard result.success, let data = result.data else {
            let errorMsg = result.message ?? "获取帖子列表失败"
            print("❌ [CloudBaseDatabaseService] getPosts 失败: \(errorMsg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        var posts = data.posts
        let likedSet = Set(data.likedPostIds ?? [])
        for i in posts.indices {
            posts[i].isLiked = likedSet.contains(posts[i].id)
        }
        print("✅ [CloudBaseDatabaseService] getPosts 成功，获取到 \(posts.count) 条帖子")
        return posts
    }
    
    /**
     * 创建帖子
     * 通过 CloudBase 网关调用云函数 createPost（Publishable Key 鉴权）
     *
     * @param userId 用户ID（云函数从运行态/网关解析，此处保留参数以兼容调用方）
     * @param content 内容
     * @param images 图片URL列表
     * @param tags 标签列表
     * @returns 帖子ID
     */
    func createPost(userId: String, content: String, images: [String], tags: [String]) async throws -> String {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        struct CreatePostData: Codable {
            let postId: String
        }
        let body: [String: Any] = [
            "content": content,
            "images": images,
            "tags": tags
        ]
        let result: CloudFunctionResponse<CreatePostData> = try await CloudBaseHTTPClient.call(name: "createPost", body: body)
        guard result.success, let postData = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "发布失败"])
        }
        return postData.postId
    }

    /// 点赞 / 取消点赞 云函数返回
    struct LikeResultData: Codable {
        let likeCount: Int
        let isLiked: Bool
    }

    /**
     * 点赞帖子（需登录）
     */
    func likePost(postId: String, accessToken: String) async throws -> (likeCount: Int, isLiked: Bool) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let body: [String: Any] = ["postId": postId]
        let result: CloudFunctionResponse<LikeResultData> = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "likePost", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "点赞失败"])
        }
        return (data.likeCount, data.isLiked)
    }

    /**
     * 取消点赞（需登录）
     */
    func unlikePost(postId: String, accessToken: String) async throws -> (likeCount: Int, isLiked: Bool) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let body: [String: Any] = ["postId": postId]
        let result: CloudFunctionResponse<LikeResultData> = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "unlikePost", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "取消点赞失败"])
        }
        return (data.likeCount, data.isLiked)
    }

    // MARK: - 评论

    /**
     * 获取帖子评论列表
     */
    func getComments(postId: String, limit: Int = 20, offset: Int = 0, accessToken: String? = nil) async throws -> [Comment] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        struct CommentsData: Codable {
            let comments: [Comment]
            let likedCommentIds: [String]?
        }
        var body: [String: Any] = ["postId": postId, "limit": limit, "offset": offset]
        if let token = accessToken, !token.isEmpty {
            body["access_token"] = token
        }
        let result: CloudFunctionResponse<CommentsData> = try await CloudBaseHTTPClient.call(name: "getComments", body: body)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "获取评论失败"])
        }
        var comments = data.comments
        let likedSet = Set(data.likedCommentIds ?? [])
        for i in comments.indices {
            comments[i].isLiked = likedSet.contains(comments[i].id)
        }
        return comments
    }

    /**
     * 发表评论（需登录）
     * @returns 更新后的评论数
     */
    func createComment(postId: String, content: String, parentId: String? = nil, accessToken: String) async throws -> Int {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        struct CreateCommentData: Codable {
            let commentCount: Int
        }
        var body: [String: Any] = ["postId": postId, "content": content]
        if let pid = parentId, !pid.isEmpty {
            body["parentId"] = pid
        }
        let result: CloudFunctionResponse<CreateCommentData> = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "createComment", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "发表评论失败"])
        }
        return data.commentCount
    }

    /// 评论点赞云函数返回
    struct CommentLikeResultData: Codable {
        let commentId: String
        let likeCount: Int
        let isLiked: Bool
    }

    /// 点赞评论（需登录）
    func likeComment(commentId: String, accessToken: String) async throws -> (commentId: String, likeCount: Int, isLiked: Bool) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let body: [String: Any] = ["commentId": commentId]
        let result: CloudFunctionResponse<CommentLikeResultData> = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "likeComment", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "点赞评论失败"])
        }
        return (data.commentId, data.likeCount, data.isLiked)
    }

    /// 取消点赞评论（需登录）
    func unlikeComment(commentId: String, accessToken: String) async throws -> (commentId: String, likeCount: Int, isLiked: Bool) {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "请在 CloudBaseConfig 中配置 Publishable Key"])
        }
        let body: [String: Any] = ["commentId": commentId]
        let result: CloudFunctionResponse<CommentLikeResultData> = try await CloudBaseHTTPClient.callWithUserTokenInBody(name: "unlikeComment", body: body, accessToken: accessToken)
        guard result.success, let data = result.data else {
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: result.message ?? "取消点赞评论失败"])
        }
        return (data.commentId, data.likeCount, data.isLiked)
    }

    // MARK: - 行情数据
    
    /**
     * 获取板块数据（行业板块/概念板块）
     * 通过云函数代理东方财富 API；仅 A 股有行业/概念板块，港股美股返回空
     *
     * @param type 板块类型
     * @param region 市场区域
     * @returns 板块数据列表
     */
    func getSectorData(type: SectorType, region: MarketRegion) async throws -> [SectorItem] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key"
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        /// 云函数返回的板块数据结构（港股等可能返回 changePercent: null、leadingStockChange: "-"）
        struct SectorAPIItem: Codable {
            let code: String
            let name: String
            let changePercent: Double?
            let leadingStock: String
            let leadingStockChange: DoubleOrDash?
            let volume: String?

            enum CodingKeys: String, CodingKey {
                case code, name, changePercent, leadingStock, volume
                case leadingStockChange = "leadingStockChange"
            }

            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                code = try c.decode(String.self, forKey: .code)
                name = try c.decode(String.self, forKey: .name)
                changePercent = try c.decodeIfPresent(Double.self, forKey: .changePercent)
                leadingStock = try c.decode(String.self, forKey: .leadingStock)
                leadingStockChange = try c.decodeIfPresent(DoubleOrDash.self, forKey: .leadingStockChange)
                volume = try c.decodeIfPresent(String.self, forKey: .volume)
            }

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(code, forKey: .code)
                try c.encode(name, forKey: .name)
                try c.encode(changePercent, forKey: .changePercent)
                try c.encode(leadingStock, forKey: .leadingStock)
                try c.encode(leadingStockChange, forKey: .leadingStockChange)
                try c.encode(volume, forKey: .volume)
            }
        }

        /// 云函数 leadingStockChange 可能为数字或 "-"
        struct DoubleOrDash: Codable {
            let value: Double?
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let d = try? container.decode(Double.self) { value = d; return }
                if let s = try? container.decode(String.self), s == "-" { value = nil; return }
                value = nil
            }
            func encode(to encoder: Encoder) throws {
                var c = encoder.singleValueContainer()
                if let v = value { try c.encode(v) } else { try c.encode("-") }
            }
        }
        
        let body: [String: Any] = ["type": type.rawValue, "region": region.rawValue]
        let result: CloudFunctionResponse<[SectorAPIItem]> = try await CloudBaseHTTPClient.call(name: "getSectorData", body: body)
        
        guard result.success, let items = result.data else {
            let errorMsg = result.message ?? "获取板块数据失败"
            print("❌ [CloudBaseDatabaseService] getSectorData 失败: \(errorMsg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        // 转换为 SectorItem（code -> id）；null changePercent 当作 0
        let sectors = items.map { item in
            SectorItem(
                id: item.code,
                name: item.name,
                changePercent: item.changePercent ?? 0,
                leadingStock: item.leadingStock,
                leadingStockChange: item.leadingStockChange?.value,
                volume: item.volume
            )
        }
        
        print("✅ [CloudBaseDatabaseService] getSectorData 成功，获取到 \(sectors.count) 个\(type.title)")
        return sectors
    }
    
    /**
     * 获取热门股票排行榜（涨幅榜/跌幅榜/活跃榜）
     * 通过云函数代理东方财富 API，支持 A股/港股/美股 全量排行
     *
     * @param type 榜单类型
     * @param region 市场区域
     * @returns 股票列表，可与 WatchlistItem 直接使用
     */
    func getHotStocks(type: HotStockType, region: MarketRegion) async throws -> [WatchlistItem] {
        guard CloudBaseHTTPClient.hasPublishableKey else {
            let msg = "请在 CloudBaseConfig 中配置 Publishable Key"
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        /// 云函数返回的排行榜项
        struct HotStockAPIItem: Codable {
            let code: String
            let name: String
            let price: Double?
            let changePercent: Double?
            let volume: Double?
        }
        
        let body: [String: Any] = ["type": type.rawValue, "region": region.rawValue]
        let result: CloudFunctionResponse<[HotStockAPIItem]> = try await CloudBaseHTTPClient.call(name: "getHotStocks", body: body)
        
        guard result.success, let items = result.data else {
            let errorMsg = result.message ?? "获取排行榜失败"
            print("❌ [CloudBaseDatabaseService] getHotStocks 失败: \(errorMsg)")
            throw NSError(domain: "CloudBaseDatabaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        let list = items.map { item in
            WatchlistItem(
                id: item.code,
                name: item.name,
                code: item.code,
                price: item.price,
                changePercent: item.changePercent,
                volume: item.volume.map { Int64($0) }
            )
        }
        print("✅ [CloudBaseDatabaseService] getHotStocks 成功，\(type.tabTitle) \(list.count) 条")
        return list
    }
}

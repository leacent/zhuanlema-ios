/**
 * CloudBase HTTP API 客户端
 * 使用 api.tcloudbasegateway.com + Publishable Key 调用云函数
 */
import Foundation

enum CloudBaseHTTPClient {
    /// 网关成功响应包装：{ result: 云函数返回值, requestId, timestamp }
    struct GatewayResponse<T: Codable>: Codable {
        let result: T?
        let requestId: String?
        let timestamp: Int64?
    }

    /// 检查 Publishable Key 是否已配置
    static var hasPublishableKey: Bool {
        let k = CloudBaseConfig.publishableKey
        return !k.isEmpty && k != "REPLACE_WITH_PUBLISHABLE_KEY"
    }

    /// 执行云函数请求，解析网关格式 { result, requestId, timestamp }，返回 result
    /// - Parameter dateDecodingStrategy: 日期解码策略（默认 .secondsSince1970，用于 User.createdAt 等）
    static func call<T: Codable>(name: String, body: [String: Any], dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .secondsSince1970) async throws -> T {
        let url = CloudBaseConfig.functionURL(name: name)
        var request = URLRequest(url: url)
        try CloudBaseConfig.configureRequest(&request, body: body)

        print("🔄 [CloudBaseHTTP] 调用云函数: \(name) URL=\(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let responseBody = String(data: data, encoding: .utf8) ?? ""

        if statusCode != 200 {
            print("❌ [CloudBaseHTTP] \(name) HTTP \(statusCode) body=\(responseBody.prefix(400))")
            
            var errorMessage = "请求失败 (HTTP \(statusCode))"
            
            // 解析错误信息
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let code = errorJson["code"] as? String,
                   let message = errorJson["message"] as? String {
                    errorMessage = "\(code): \(message)"
                } else if let message = errorJson["message"] as? String {
                    errorMessage = message
                }
            }
            
            // 针对 403 的特殊处理
            if statusCode == 403 {
                if responseBody.contains("ACTION_FORBIDDEN") {
                    errorMessage = "权限不足 (ACTION_FORBIDDEN)。请检查 API Key 配置或云函数 HTTP 访问权限。"
                }
            }

            throw NSError(
                domain: "CloudBaseHTTPClient",
                code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }

        // 创建 decoder，设置日期解码策略
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy

        // 网关格式：{ result: 云函数返回值 }；result 可能为对象或 JSON 字符串
        do {
            let wrapper = try decoder.decode(GatewayResponse<T>.self, from: data)
            if let r = wrapper.result { return r }
        } catch {}

        // 兼容：result 为 JSON 字符串
        if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resultVal = raw["result"] {
            if let obj = resultVal as? [String: Any],
               let json = try? JSONSerialization.data(withJSONObject: obj),
               let r = try? decoder.decode(T.self, from: json) {
                return r
            }
            if let str = resultVal as? String,
               let json = str.data(using: .utf8),
               let r = try? decoder.decode(T.self, from: json) {
                return r
            }
        }

        // 兼容：直接返回云函数结果，无 result 包装
        if let direct = try? decoder.decode(T.self, from: data) {
            return direct
        }

        print("❌ [CloudBaseHTTP] \(name) 解析失败 raw=\(responseBody.prefix(300))")
        throw NSError(domain: "CloudBaseHTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应解析失败"])
    }

    /// 使用 Publishable Key 鉴权 + body 内传 access_token 调用云函数（需登录接口，避免网关对用户 Token 返回 403）
    static func callWithUserTokenInBody<T: Codable>(name: String, body: [String: Any], accessToken: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .secondsSince1970) async throws -> T {
        let url = CloudBaseConfig.functionURL(name: name)
        var request = URLRequest(url: url)
        try CloudBaseConfig.configureRequestWithUserTokenInBody(&request, body: body, accessToken: accessToken)

        print("🔄 [CloudBaseHTTP] 调用云函数(用户 Token 在 body): \(name)")

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let responseBody = String(data: data, encoding: .utf8) ?? ""

        if statusCode != 200 {
            print("❌ [CloudBaseHTTP] \(name) HTTP \(statusCode) body=\(responseBody.prefix(400))")
            var errorMessage = "请求失败 (HTTP \(statusCode))"
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let code = errorJson["code"] as? String,
                   let message = errorJson["message"] as? String {
                    errorMessage = "\(code): \(message)"
                } else if let message = errorJson["message"] as? String {
                    errorMessage = message
                }
            }
            if statusCode == 403, responseBody.contains("ACTION_FORBIDDEN") {
                errorMessage = "权限不足 (ACTION_FORBIDDEN)，请检查 API Key 或控制台策略；若为登录后操作可尝试重新登录。"
            }
            throw NSError(domain: "CloudBaseHTTPClient", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        do {
            let wrapper = try decoder.decode(GatewayResponse<T>.self, from: data)
            if let r = wrapper.result { return r }
        } catch {}
        if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resultVal = raw["result"] {
            if let obj = resultVal as? [String: Any],
               let json = try? JSONSerialization.data(withJSONObject: obj),
               let r = try? decoder.decode(T.self, from: json) { return r }
            if let str = resultVal as? String,
               let json = str.data(using: .utf8),
               let r = try? decoder.decode(T.self, from: json) { return r }
        }
        if let direct = try? decoder.decode(T.self, from: data) { return direct }
        throw NSError(domain: "CloudBaseHTTPClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应解析失败"])
    }
}

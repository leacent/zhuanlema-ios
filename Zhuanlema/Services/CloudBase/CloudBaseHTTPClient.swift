/**
 * CloudBase HTTP API 客户端
 * 使用 api.tcloudbasegateway.com + Publishable Key 调用云函数
 */
import Foundation

enum CloudBaseHTTPClient {
    struct GatewayResponse<T: Codable>: Codable {
        let result: T?
        let requestId: String?
        let timestamp: Int64?
    }

    static var hasPublishableKey: Bool {
        let k = CloudBaseConfig.publishableKey
        return !k.isEmpty && k != "REPLACE_WITH_PUBLISHABLE_KEY"
    }

    // MARK: - 公开调用入口

    static func call<T: Codable>(
        name: String,
        body: [String: Any],
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .secondsSince1970
    ) async throws -> T {
        let url = CloudBaseConfig.functionURL(name: name)
        var request = URLRequest(url: url)
        try CloudBaseConfig.configureRequest(&request, body: body)

        print("🔄 [CloudBaseHTTP] \(name)")
        return try await executeAndDecode(name: name, request: request, dateDecodingStrategy: dateDecodingStrategy)
    }

    static func callWithUserTokenInBody<T: Codable>(
        name: String,
        body: [String: Any],
        accessToken: String,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .secondsSince1970
    ) async throws -> T {
        let url = CloudBaseConfig.functionURL(name: name)
        var request = URLRequest(url: url)
        try CloudBaseConfig.configureRequestWithUserTokenInBody(&request, body: body, accessToken: accessToken)

        print("🔄 [CloudBaseHTTP] \(name) (withToken)")
        return try await executeAndDecode(name: name, request: request, dateDecodingStrategy: dateDecodingStrategy)
    }

    // MARK: - 统一执行 + 解码（消除重复）

    private static func executeAndDecode<T: Codable>(
        name: String,
        request: URLRequest,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    ) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let responseBody = String(data: data, encoding: .utf8) ?? "<binary>"

        if statusCode != 200 {
            throw buildHTTPError(name: name, statusCode: statusCode, data: data, responseBody: responseBody)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy

        #if DEBUG
        print("📦 [CloudBaseHTTP] \(name) 响应(\(data.count)B): \(responseBody.prefix(800))")
        #endif

        // 第 1 层（主路径）：tcloudbasegateway 直接返回云函数原始 JSON
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("⚠️ [CloudBaseHTTP] \(name) 直接解码失败: \(error)")
            #endif
        }

        // 第 2 层：Web SDK / 旧格式 { result: T }
        do {
            let wrapper = try decoder.decode(GatewayResponse<T>.self, from: data)
            if let r = wrapper.result { return r }
        } catch { }

        // 第 3 层：result 为嵌套对象或 JSON 字符串（response_data 等场景）
        if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let resultVal = raw["result"] ?? raw["data"] {

            if let obj = resultVal as? [String: Any] {
                if let responseData = obj["response_data"] as? String,
                   let json = responseData.data(using: .utf8) {
                    do { return try decoder.decode(T.self, from: json) } catch { }
                }
                do {
                    let json = try JSONSerialization.data(withJSONObject: obj)
                    return try decoder.decode(T.self, from: json)
                } catch { }
            }

            if let str = resultVal as? String, let json = str.data(using: .utf8) {
                do { return try decoder.decode(T.self, from: json) } catch { }
            }
        }

        // 全部失败
        print("❌ [CloudBaseHTTP] \(name) 所有解码路径均失败，目标类型=\(T.self)，响应前 500 字符=\(responseBody.prefix(500))")
        throw NSError(
            domain: "CloudBaseHTTPClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "[\(name)] 响应解析失败，请检查云函数返回格式"]
        )
    }

    // MARK: - HTTP 错误构建

    private static func buildHTTPError(name: String, statusCode: Int, data: Data, responseBody: String) -> NSError {
        print("❌ [CloudBaseHTTP] \(name) HTTP \(statusCode) body=\(responseBody.prefix(400))")

        var errorMessage = "请求失败 (HTTP \(statusCode))"

        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let code = errorJson["code"] as? String, let message = errorJson["message"] as? String {
                errorMessage = "\(code): \(message)"
            } else if let message = errorJson["message"] as? String {
                errorMessage = message
            }
        }

        if statusCode == 403, responseBody.contains("ACTION_FORBIDDEN") {
            errorMessage = "权限不足 (ACTION_FORBIDDEN)，请检查 API Key 或云函数权限。"
        }

        return NSError(
            domain: "CloudBaseHTTPClient",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
    }
}

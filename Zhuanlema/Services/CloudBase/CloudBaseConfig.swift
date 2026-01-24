/**
 * CloudBase 配置
 *
 * 云函数通过 HTTP API 调用：https://docs.cloudbase.net/http-api/basic/guide
 * - 基础地址：api.tcloudbasegateway.com（无需开通 HTTP 访问服务）
 * - 认证：Authorization: Bearer {Publishable Key}
 *
 * 请将 Publishable Key 填入下方；在 云开发控制台 → ApiKey 管理 获取。
 */
import Foundation

struct CloudBaseConfig {
    /// 环境ID
    static let envId = "prod-1-3g3ukjzod3d5e3a1"

    /// HTTP API 基础地址（网关，不依赖 HTTP 访问服务）
    static let baseURL = "https://\(envId).api.tcloudbasegateway.com"

    /// 云函数 HTTP 调用地址：POST /v1/functions/{name}
    static func functionURL(name: String) -> URL {
        return URL(string: "\(baseURL)/v1/functions/\(name)")!
    }

    /// Publishable Key（客户端可暴露，用于匿名访问公开资源）
    /// 在 云开发控制台 → ApiKey 管理 创建并复制，替换此占位符。
    static var publishableKey: String {
        // 可改为从 Info.plist、xcconfig 等读取，避免写死在代码里
        return _publishableKey
    }

    /// 占位符：请替换为实际的 Publishable Key
    private static let _publishableKey = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjlkMWRjMzFlLWI0ZDAtNDQ4Yi1hNzZmLWIwY2M2M2Q4MTQ5OCJ9.eyJhdWQiOiJwcm9kLTEtM2czdWtqem9kM2Q1ZTNhMSIsImV4cCI6MjUzNDAyMzAwNzk5LCJpYXQiOjE3NjkyNzk1NjMsImF0X2hhc2giOiJJVFJwdFhQOVM2eTNPMVlPanVkZUdnIiwicHJvamVjdF9pZCI6InByb2QtMS0zZzN1a2p6b2QzZDVlM2ExIiwibWV0YSI6eyJwbGF0Zm9ybSI6IkFwaUtleSJ9LCJhZG1pbmlzdHJhdG9yX2lkIjoiMjAxMzQyNjMyODQ3OTc4MDg2NSIsInVzZXJfdHlwZSI6IiIsImNsaWVudF90eXBlIjoiY2xpZW50X3NlcnZlciIsImlzX3N5c3RlbV9hZG1pbiI6dHJ1ZX0.ZXKd0XT64TgG9oqJW1xvGKFOxldGnoJmk_QV1-1CtT9lrx_9M08v6n_DXvsdUdS3CJ4N4QwOUabXGWzI9FUBI80pv9XuGSAMP_4d7wSNBJu2nnbT7IjEsE8Avi9n3JJOyoYHH2Wn-Y_pwFHpAhTlDU6yEpS7s30HBG_VVGH3wwCNimX3_Kvbs6_s3qsOFiNZXNeGhI1ciO7YAfvGNQxE0NtX3Oc1oXWPeDFl4-qQeHB9b97sUECHbS5V_vQXQOqNzHgOFm7sxw9UGcZ0jrCYNDqtuWk2bIZTwIUNwTEeDsT1e-WmXaSIwX1mwBepk-lCHub4I68KNUsMrDUl2Y9qKQ"

    /// 为 URLRequest 添加 CloudBase 所需头与 body（JSON）
    static func configureRequest(_ request: inout URLRequest, body: [String: Any]) throws {
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !publishableKey.isEmpty && publishableKey != "REPLACE_WITH_PUBLISHABLE_KEY" {
            request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
}

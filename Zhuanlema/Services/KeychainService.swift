/**
 * Keychain 安全存储服务
 * 用于安全存储敏感信息（如 access token）
 * 替代 UserDefaults 以防止明文泄露
 */
import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    /// Keychain 使用的 service 标识
    private let service = Bundle.main.bundleIdentifier ?? "com.zhuanlema.app"

    private init() {}

    // MARK: - Public API

    /**
     * 保存字符串到 Keychain
     *
     * @param value 要保存的字符串
     * @param key 存储键名
     */
    func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        // 先尝试删除旧值
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ [KeychainService] 写入失败 key=\(key), status=\(status)")
        }
    }

    /**
     * 从 Keychain 读取字符串
     *
     * @param key 存储键名
     * @returns 存储的字符串，不存在时返回 nil
     */
    func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /**
     * 从 Keychain 删除指定键
     *
     * @param key 存储键名
     */
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Migration

    /**
     * 从 UserDefaults 迁移 token 到 Keychain（一次性操作）
     * 启动时调用，迁移完成后清除 UserDefaults 中的旧值
     */
    func migrateTokenFromUserDefaults() {
        let key = "userAccessToken"
        // 如果 Keychain 已有值，跳过
        if get(forKey: key) != nil { return }
        // 从 UserDefaults 读取旧值
        if let oldToken = UserDefaults.standard.string(forKey: key), !oldToken.isEmpty {
            set(oldToken, forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
            print("✅ [KeychainService] Token 已从 UserDefaults 迁移到 Keychain")
        }
    }
}

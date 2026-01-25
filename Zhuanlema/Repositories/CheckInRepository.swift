/**
 * 打卡数据仓库
 * 负责打卡相关的数据访问
 */
import Foundation

class CheckInRepository {
    private let databaseService = CloudBaseDatabaseService.shared
    private let userRepository = UserRepository()
    
    /**
     * 提交打卡
     *
     * @param result 打卡结果 ("yes" 或 "no")
     * @returns 打卡记录ID
     */
    func submitCheckIn(result: String) async throws -> String {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        
        if let user = userRepository.getCurrentUser() {
            // 已登录：同步到云端
            return try await databaseService.createCheckIn(userId: user.id, result: result)
        } else {
            // 未登录：仅保存在本地
            saveCheckInLocally(result: result, date: today)
            return "local_success"
        }
    }
    
    /**
     * 仅保存到本地（云端失败时由调用方使用）
     */
    func saveCheckInLocallyOnly(result: String) {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        saveCheckInLocally(result: result, date: today)
    }

    /**
     * 将打卡记录保存到本地
     */
    private func saveCheckInLocally(result: String, date: String) {
        let record: [String: String] = [
            "date": date,
            "result": result,
            "timestamp": String(Date().timeIntervalSince1970)
        ]
        
        var history = UserDefaults.standard.array(forKey: "local_check_in_history") as? [[String: String]] ?? []
        history.append(record)
        UserDefaults.standard.set(history, forKey: "local_check_in_history")
    }
    
    /**
     * 获取今日打卡统计
     *
     * @returns 打卡统计数据
     */
    func getTodayStats() async throws -> CheckInStats {
        return try await databaseService.getTodayCheckInStats()
    }

    /**
     * 获取当前用户某月打卡记录（用于日历）
     * 云端记录与当月本地记录按日期合并，同一天以云端为准。
     * 约定：users 表的 _id = check_ins 表的 _openid，此处传入的 userId 即当前用户的 id（users._id），云函数按 _openid 查询。
     * @param year 年
     * @param month 月（1-12）
     */
    func getCheckInHistory(year: Int, month: Int) async throws -> [CheckIn] {
        var byDate: [String: CheckIn] = [:]

        // 先填本地当月记录
        for local in getLocalCheckInHistory(year: year, month: month) {
            byDate[local.date] = local
        }

        // 再以云端记录覆盖同一天；若请求失败仍返回当前已有的本地合并结果（需确保云函数 getCheckInHistory 已部署）
        if let userId = userRepository.getCurrentUser()?.id {
            do {
                let list = try await databaseService.getCheckInHistory(userId: userId, year: year, month: month)
                for record in list {
                    byDate[record.date] = record
                }
            } catch {
                // 仅保留本地已合并的数据，让日历至少能展示本地打卡
            }
        }

        return byDate.values.sorted { $0.date < $1.date }
    }

    /**
     * 读取某月本地打卡记录（UserDefaults），仅用于与云端合并展示
     */
    private func getLocalCheckInHistory(year: Int, month: Int) -> [CheckIn] {
        let raw = UserDefaults.standard.array(forKey: "local_check_in_history") as? [[String: String]] ?? []
        let monthPrefix = String(format: "%04d-%02d", year, month)

        return raw.compactMap { item -> CheckIn? in
            guard let date = item["date"], date.hasPrefix(monthPrefix),
                  let result = item["result"], result == "yes" || result == "no" else {
                return nil
            }
            let ts = Double(item["timestamp"] ?? "0") ?? 0
            return CheckIn(
                id: "local-\(date)-\(item["timestamp"] ?? "")",
                userId: "",
                date: date,
                result: result,
                createdAt: Date(timeIntervalSince1970: ts)
            )
        }
    }
    
    /**
     * 检查今日是否已打卡
     *
     * @returns 是否已打卡
     */
    func hasCheckedInToday() -> Bool {
        // 注意：这里简化处理，实际应该查询数据库
        // 暂时使用 UserDefaults 存储
        let lastCheckInDate = UserDefaults.standard.string(forKey: "lastCheckInDate")
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        return lastCheckInDate == today
    }
    
    /**
     * 标记今日已打卡
     */
    func markCheckedInToday() {
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        UserDefaults.standard.set(today, forKey: "lastCheckInDate")
    }
    
    /**
     * 登录后将本地打卡记录同步到云端，与当前用户绑定并持久化到数据库。
     * 仅上传云端尚未存在的日期；同步成功后清除本地记录。
     */
    func syncLocalCheckInsToCloud() async {
        guard let userId = userRepository.getCurrentUser()?.id else { return }
        let raw = UserDefaults.standard.array(forKey: "local_check_in_history") as? [[String: String]] ?? []
        guard !raw.isEmpty else { return }

        let valid: [(date: String, result: String)] = raw.compactMap { item in
            guard let date = item["date"], let result = item["result"], result == "yes" || result == "no" else { return nil }
            return (date, result)
        }
        guard !valid.isEmpty else {
            UserDefaults.standard.set([], forKey: "local_check_in_history")
            return
        }

        var cloudDates: Set<String> = []
        let yearMonthPrefixes: Set<String> = Set(valid.compactMap { item -> String? in
            let parts = item.date.split(separator: "-")
            guard parts.count >= 2, Int(parts[0]) != nil, Int(parts[1]) != nil else { return nil }
            return String(item.date.prefix(7))
        })
        for prefix in yearMonthPrefixes {
            let parts = prefix.split(separator: "-")
            guard parts.count == 2, let y = Int(parts[0]), let m = Int(parts[1]) else { continue }
            if let list = try? await databaseService.getCheckInHistory(userId: userId, year: y, month: m) {
                list.forEach { cloudDates.insert($0.date) }
            }
        }

        for item in valid where !cloudDates.contains(item.date) {
            _ = try? await databaseService.createCheckIn(userId: userId, result: item.result, date: item.date)
        }
        UserDefaults.standard.set([], forKey: "local_check_in_history")
    }

    /**
     * 清除本地打卡缓存（用于开发调试或用户重置）
     * 包括：
     * - 最后打卡日期标记
     * - 本地打卡历史记录
     */
    func clearLocalCheckInCache() {
        UserDefaults.standard.removeObject(forKey: "lastCheckInDate")
        UserDefaults.standard.removeObject(forKey: "local_check_in_history")
        print("✅ 已清除本地打卡缓存")
    }
}


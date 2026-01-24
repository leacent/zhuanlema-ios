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


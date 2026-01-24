/**
 * DateFormatter 扩展
 * 常用日期格式化工具
 */
import Foundation

extension DateFormatter {
    /// 年-月-日 格式
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    /// 完整日期时间格式
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    /// 时间格式
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

extension Date {
    /**
     * 转换为 yyyy-MM-dd 格式字符串
     */
    func toDateString() -> String {
        return DateFormatter.yyyyMMdd.string(from: self)
    }
    
    /**
     * 转换为完整日期时间字符串
     */
    func toFullDateTimeString() -> String {
        return DateFormatter.fullDateTime.string(from: self)
    }
    
    /**
     * 判断是否是今天
     */
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /**
     * 判断是否是昨天
     */
    func isYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(self)
    }
}

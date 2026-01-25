/**
 * 触觉反馈封装：仅在真机执行，避免模拟器上出现
 * CHHapticPattern / hapticpatternlibrary.plist 找不到的日志。
 * 若需在按钮等处加触觉，请使用此处方法而非直接 UIImpactFeedbackGenerator。
 */
import UIKit

enum HapticHelper {
    /// 是否应在当前环境触发触觉（模拟器无 haptic 库，跳过可避免控制台报错）
    static var shouldTrigger: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    /// 轻冲击（按钮点击等）
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard shouldTrigger else { return }
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }

    /// 选择变化（Picker、Tab 等）
    static func selection() {
        guard shouldTrigger else { return }
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }

    /// 通知类型（成功/警告/错误）
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard shouldTrigger else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(type)
    }
}

import UIKit

/// 转了吗App颜色调色板
/// 基于中国红喜庆风格的现代化设计系统
enum ColorPalette {
    
    // MARK: - Brand Colors (品牌色)
    
    /// 主品牌色 - 中国红
    /// Light: 鲜艳的中国红 #DC143C
    /// Dark: 稍微柔和的红色 #FF4444
    static let brandPrimary = UIColor(named: "BrandPrimary")!
    
    /// 次品牌色 - 深红色
    /// Light: 深沉的红色 #B22222
    /// Dark: 稍亮的深红 #CC3333
    static let brandSecondary = UIColor(named: "BrandSecondary")!
    
    /// 强调色 - 金色
    /// Light: 中国金 #D4AF37
    /// Dark: 柔和金 #FFD700
    static let brandAccent = UIColor(named: "BrandAccent")!
    
    /// 品牌浅色 - 浅红背景
    /// Light: 极淡的粉红 #FFF5F5
    /// Dark: 深色下的红色调背景 #2A1A1A
    static let brandLight = UIColor(named: "BrandLight")!
    
    // MARK: - Trading Colors (交易功能色)
    
    /// 涨/买入色 - 红色
    /// 中国市场习惯:红涨绿跌
    static let tradingUp = brandPrimary
    
    /// 跌/卖出色 - 绿色
    /// Light: 偏暗的绿色 #34A853
    /// Dark: 柔和的绿色 #5CB85C
    static let tradingDown = UIColor(named: "TradingDown")!
    
    // MARK: - Semantic Colors (语义色)
    
    /// 成功状态
    /// Light: 舒适的绿色 #52C41A
    /// Dark: 明亮的绿色 #73D13D
    static let success = UIColor(named: "Success")!
    
    /// 警告状态
    /// Light: 橙黄色 #FA8C16
    /// Dark: 明亮橙色 #FFA940
    static let warning = UIColor(named: "Warning")!
    
    /// 错误状态
    /// Light: 红色 #F5222D
    /// Dark: 亮红色 #FF4D4F
    static let error = UIColor(named: "Error")!
    
    /// 信息提示
    /// Light: 蓝色 #1890FF
    /// Dark: 亮蓝色 #40A9FF
    static let info = UIColor(named: "Info")!
    
    // MARK: - Text Colors (文字颜色)
    
    /// 主要文本 - 使用系统自适应颜色
    static let textPrimary = UIColor.label
    
    /// 次要文本
    static let textSecondary = UIColor.secondaryLabel
    
    /// 辅助文本
    static let textTertiary = UIColor.tertiaryLabel
    
    /// 禁用文本
    static let textDisabled = UIColor.quaternaryLabel
    
    /// 反色文本 - 用于深色背景上的白色文字
    /// Light: 纯白 #FFFFFF
    /// Dark: 浅灰白 #F5F5F5
    static let textInverse = UIColor(named: "TextInverse")!
    
    // MARK: - Background Colors (背景色)
    
    /// 主背景色
    static let bgPrimary = UIColor.systemBackground
    
    /// 次级背景色 - 卡片、容器
    static let bgSecondary = UIColor.secondarySystemBackground
    
    /// 三级背景色 - 内嵌容器
    static let bgTertiary = UIColor.tertiarySystemBackground
    
    /// 强调背景 - 带品牌色调的背景
    /// Light: 极淡红色 #FFF8F8
    /// Dark: 深红色调 #1A1414
    static let bgAccent = UIColor(named: "BgAccent")!
    
    // MARK: - Surface Colors (表面色)
    
    /// 浅色填充
    static let surfaceLight = UIColor.systemFill
    
    /// 中等填充
    static let surfaceMedium = UIColor.secondarySystemFill
    
    /// 深色填充
    static let surfaceDark = UIColor.tertiarySystemFill
    
    // MARK: - Border & Divider (边框与分隔线)
    
    /// 边框色
    static let border = UIColor.separator
    
    /// 分隔线
    static let divider = UIColor.opaqueSeparator
    
    /// 强调边框 - 品牌色边框
    static let borderAccent = brandPrimary
    
    // MARK: - Overlay Colors (遮罩层)
    
    /// 遮罩层 - 半透明黑色
    /// Light & Dark: rgba(0, 0, 0, 0.5)
    static let overlay = UIColor(named: "Overlay")!
    
    /// 轻度遮罩
    /// Light & Dark: rgba(0, 0, 0, 0.2)
    static let overlayLight = UIColor(named: "OverlayLight")!
}

// MARK: - Color Extension Helper

extension UIColor {
    /// 从十六进制字符串创建颜色
    /// - Parameters:
    ///   - hex: 十六进制颜色值,如 "#DC143C"
    ///   - alpha: 透明度,默认1.0
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        guard hexString.count == 6 else {
            self.init(white: 0, alpha: alpha)
            return
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

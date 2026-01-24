import UIKit

/// 语义化颜色定义
/// 提供更具体的使用场景命名,便于开发使用
enum SemanticColors {
    
    // MARK: - Button Colors
    
    /// 主要按钮背景色
    static let buttonPrimary = ColorPalette.brandPrimary
    
    /// 主要按钮文字色
    static let buttonPrimaryText = ColorPalette.textInverse
    
    /// 次要按钮背景色
    static let buttonSecondary = ColorPalette.bgSecondary
    
    /// 次要按钮文字色
    static let buttonSecondaryText = ColorPalette.textPrimary
    
    /// 禁用按钮背景色
    static let buttonDisabled = ColorPalette.surfaceLight
    
    /// 禁用按钮文字色
    static let buttonDisabledText = ColorPalette.textDisabled
    
    // MARK: - Card Colors
    
    /// 卡片背景色
    static let cardBackground = ColorPalette.bgSecondary
    
    /// 卡片边框色
    static let cardBorder = ColorPalette.border
    
    /// 高亮卡片背景(如推荐、置顶)
    static let cardHighlight = ColorPalette.bgAccent
    
    // MARK: - Input Colors
    
    /// 输入框背景色
    static let inputBackground = ColorPalette.bgTertiary
    
    /// 输入框边框色
    static let inputBorder = ColorPalette.border
    
    /// 输入框聚焦边框色
    static let inputBorderFocused = ColorPalette.brandPrimary
    
    /// 输入框占位符文字色
    static let inputPlaceholder = ColorPalette.textTertiary
    
    /// 输入框错误边框色
    static let inputBorderError = ColorPalette.error
    
    // MARK: - Navigation Colors
    
    /// 导航栏背景色
    static let navBackground = ColorPalette.bgPrimary
    
    /// 导航栏标题色
    static let navTitle = ColorPalette.textPrimary
    
    /// 导航栏按钮色
    static let navButton = ColorPalette.brandPrimary
    
    // MARK: - Tab Bar Colors
    
    /// 标签栏背景色
    static let tabBackground = ColorPalette.bgPrimary
    
    /// 标签栏选中色
    static let tabSelected = ColorPalette.brandPrimary
    
    /// 标签栏未选中色
    static let tabUnselected = ColorPalette.textSecondary
    
    // MARK: - Badge Colors
    
    /// 徽章背景色 - 红点提醒
    static let badgeBackground = ColorPalette.brandPrimary
    
    /// 徽章文字色
    static let badgeText = ColorPalette.textInverse
    
    /// 金色徽章 - VIP、认证等
    static let badgeGold = ColorPalette.brandAccent
    
    // MARK: - Status Colors
    
    /// 在线状态
    static let statusOnline = ColorPalette.success
    
    /// 离线状态
    static let statusOffline = ColorPalette.textTertiary
    
    /// 忙碌状态
    static let statusBusy = ColorPalette.warning
    
    // MARK: - Trading Specific Colors
    
    /// 价格上涨背景色
    static let priceUpBackground = UIColor(named: "PriceUpBackground")!
    
    /// 价格下跌背景色
    static let priceDownBackground = UIColor(named: "PriceDownBackground")!
    
    /// 买入按钮色
    static let actionBuy = ColorPalette.tradingUp
    
    /// 卖出按钮色
    static let actionSell = ColorPalette.tradingDown
    
    /// 持仓盈利色
    static let profitPositive = ColorPalette.tradingUp
    
    /// 持仓亏损色
    static let profitNegative = ColorPalette.tradingDown
    
    // MARK: - Social Colors
    
    /// 点赞按钮色
    static let actionLike = ColorPalette.brandPrimary
    
    /// 评论按钮色
    static let actionComment = ColorPalette.textSecondary
    
    /// 分享按钮色
    static let actionShare = ColorPalette.info
    
    /// 收藏按钮色
    static let actionFavorite = ColorPalette.brandAccent
    
    // MARK: - Alert Colors
    
    /// 成功提示背景色
    static let alertSuccessBackground = UIColor(named: "AlertSuccessBackground")!
    
    /// 警告提示背景色
    static let alertWarningBackground = UIColor(named: "AlertWarningBackground")!
    
    /// 错误提示背景色
    static let alertErrorBackground = UIColor(named: "AlertErrorBackground")!
    
    /// 信息提示背景色
    static let alertInfoBackground = UIColor(named: "AlertInfoBackground")!
}

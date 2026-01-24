import UIKit

/// 快速开始示例
/// 展示如何在实际开发中使用颜色系统
class QuickStartExample {
    
    // MARK: - 示例1: 创建主要按钮
    
    static func createPrimaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        
        // 使用语义化颜色
        button.backgroundColor = SemanticColors.buttonPrimary
        button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)
        
        // 样式
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // 可访问性
        button.accessibilityLabel = title
        button.accessibilityTraits = .button
        
        return button
    }
    
    // MARK: - 示例2: 创建卡片视图
    
    static func createCard(title: String, subtitle: String) -> UIView {
        let card = UIView()
        card.backgroundColor = SemanticColors.cardBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = SemanticColors.cardBorder.cgColor
        
        // 阴影效果
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 4
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = ColorPalette.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorPalette.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    // MARK: - 示例3: 创建价格显示标签
    
    static func createPriceLabel(price: Double, changePercent: Double) -> UILabel {
        let label = UILabel()
        let isPriceUp = changePercent >= 0
        
        // 格式化文本
        let arrow = isPriceUp ? "↑" : "↓"
        let sign = isPriceUp ? "+" : ""
        label.text = "\(arrow) \(sign)\(String(format: "%.2f", changePercent))%"
        
        // 使用交易颜色
        label.textColor = isPriceUp ? ColorPalette.tradingUp : ColorPalette.tradingDown
        label.backgroundColor = isPriceUp ? SemanticColors.priceUpBackground : SemanticColors.priceDownBackground
        
        // 样式
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        
        return label
    }
    
    // MARK: - 示例4: 创建输入框
    
    static func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 16)
        
        // 使用语义化颜色
        textField.backgroundColor = SemanticColors.inputBackground
        textField.textColor = ColorPalette.textPrimary
        
        // 占位符颜色
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: SemanticColors.inputPlaceholder]
        )
        
        // 边框样式
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = SemanticColors.inputBorder.cgColor
        
        // 内边距
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.rightViewMode = .always
        
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return textField
    }
    
    // MARK: - 示例5: 创建提示横幅
    
    enum AlertBannerType {
        case success, warning, error, info
    }
    
    static func createAlertBanner(message: String, type: AlertBannerType) -> UIView {
        let banner = UIView()
        banner.layer.cornerRadius = 8
        
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // 根据类型设置颜色
        switch type {
        case .success:
            banner.backgroundColor = SemanticColors.alertSuccessBackground
            label.textColor = ColorPalette.success
        case .warning:
            banner.backgroundColor = SemanticColors.alertWarningBackground
            label.textColor = ColorPalette.warning
        case .error:
            banner.backgroundColor = SemanticColors.alertErrorBackground
            label.textColor = ColorPalette.error
        case .info:
            banner.backgroundColor = SemanticColors.alertInfoBackground
            label.textColor = ColorPalette.info
        }
        
        banner.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -12)
        ])
        
        return banner
    }
    
    // MARK: - 示例6: 创建徽章
    
    static func createBadge(text: String, isGold: Bool = false) -> UIView {
        let badge = UIView()
        badge.backgroundColor = isGold ? SemanticColors.badgeGold : SemanticColors.badgeBackground
        badge.layer.cornerRadius = 10
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = SemanticColors.badgeText
        label.translatesAutoresizingMaskIntoConstraints = false
        
        badge.addSubview(label)
        
        NSLayoutConstraint.activate([
            badge.heightAnchor.constraint(equalToConstant: 20),
            
            label.topAnchor.constraint(equalTo: badge.topAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -2)
        ])
        
        return badge
    }
    
    // MARK: - 示例7: 配置导航栏
    
    static func configureNavigationBar(_ navigationController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = SemanticColors.navBackground
        appearance.titleTextAttributes = [
            .foregroundColor: SemanticColors.navTitle,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = SemanticColors.navButton
    }
    
    // MARK: - 示例8: 配置标签栏
    
    static func configureTabBar(_ tabBarController: UITabBarController) {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = SemanticColors.tabBackground
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.tintColor = SemanticColors.tabSelected
        tabBarController.tabBar.unselectedItemTintColor = SemanticColors.tabUnselected
    }
    
    // MARK: - 示例9: 创建分隔线
    
    static func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = ColorPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return divider
    }
    
    // MARK: - 示例10: 创建社交互动按钮
    
    enum SocialActionType {
        case like, comment, share, favorite
    }
    
    static func createSocialButton(type: SocialActionType, count: Int = 0) -> UIButton {
        let button = UIButton(type: .system)
        
        let iconName: String
        let color: UIColor
        
        switch type {
        case .like:
            iconName = "heart"
            color = SemanticColors.actionLike
        case .comment:
            iconName = "bubble.left"
            color = SemanticColors.actionComment
        case .share:
            iconName = "square.and.arrow.up"
            color = SemanticColors.actionShare
        case .favorite:
            iconName = "star"
            color = SemanticColors.actionFavorite
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let icon = UIImage(systemName: iconName, withConfiguration: config)
        
        button.setImage(icon, for: .normal)
        button.setTitle(count > 0 ? "\(count)" : nil, for: .normal)
        button.tintColor = color
        button.titleLabel?.font = .systemFont(ofSize: 14)
        
        return button
    }
}

// MARK: - 完整页面示例

/// 使用颜色系统的完整页面示例
class SampleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置背景色
        view.backgroundColor = ColorPalette.bgPrimary
        
        // 配置导航栏
        title = "示例页面"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "更多",
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
        
        // 创建滚动视图
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        
        // 添加各种组件
        contentStack.addArrangedSubview(QuickStartExample.createCard(
            title: "欢迎使用转了吗",
            subtitle: "这是使用颜色系统的示例页面"
        ))
        
        contentStack.addArrangedSubview(QuickStartExample.createPriceLabel(
            price: 100.0,
            changePercent: 5.67
        ))
        
        contentStack.addArrangedSubview(QuickStartExample.createTextField(
            placeholder: "请输入内容"
        ))
        
        contentStack.addArrangedSubview(QuickStartExample.createPrimaryButton(
            title: "提交"
        ))
        
        contentStack.addArrangedSubview(QuickStartExample.createAlertBanner(
            message: "这是一条成功提示",
            type: .success
        ))
        
        // 约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    @objc private func moreButtonTapped() {
        // 按钮操作
    }
}

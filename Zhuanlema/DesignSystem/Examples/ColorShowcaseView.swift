import UIKit

/// 颜色系统展示页面
/// 用于演示和测试所有颜色在Light/Dark Mode下的效果
class ColorShowcaseView: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        buildColorShowcase()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "颜色系统"
        view.backgroundColor = ColorPalette.bgPrimary
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
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
    
    private func buildColorShowcase() {
        // 品牌色
        addSection(title: "品牌色 (Brand Colors)", colors: [
            ("主品牌色", "BrandPrimary", ColorPalette.brandPrimary),
            ("次品牌色", "BrandSecondary", ColorPalette.brandSecondary),
            ("强调色(金色)", "BrandAccent", ColorPalette.brandAccent),
            ("品牌浅色", "BrandLight", ColorPalette.brandLight)
        ])
        
        // 交易色
        addSection(title: "交易功能色 (Trading Colors)", colors: [
            ("涨/买入", "TradingUp", ColorPalette.tradingUp),
            ("跌/卖出", "TradingDown", ColorPalette.tradingDown)
        ])
        
        // 语义色
        addSection(title: "语义色 (Semantic Colors)", colors: [
            ("成功", "Success", ColorPalette.success),
            ("警告", "Warning", ColorPalette.warning),
            ("错误", "Error", ColorPalette.error),
            ("信息", "Info", ColorPalette.info)
        ])
        
        // 文本色
        addSection(title: "文本颜色 (Text Colors)", colors: [
            ("主要文本", "textPrimary", ColorPalette.textPrimary),
            ("次要文本", "textSecondary", ColorPalette.textSecondary),
            ("辅助文本", "textTertiary", ColorPalette.textTertiary),
            ("禁用文本", "textDisabled", ColorPalette.textDisabled),
            ("反色文本", "textInverse", ColorPalette.textInverse)
        ])
        
        // 背景色
        addSection(title: "背景颜色 (Background Colors)", colors: [
            ("主背景", "bgPrimary", ColorPalette.bgPrimary),
            ("次级背景", "bgSecondary", ColorPalette.bgSecondary),
            ("三级背景", "bgTertiary", ColorPalette.bgTertiary),
            ("强调背景", "bgAccent", ColorPalette.bgAccent)
        ])
        
        // 示例组件
        addComponentExamples()
    }
    
    // MARK: - Helper Methods
    
    /// 添加颜色区块
    private func addSection(title: String, colors: [(name: String, id: String, color: UIColor)]) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ColorPalette.textPrimary
        contentStack.addArrangedSubview(titleLabel)
        
        for colorInfo in colors {
            let colorRow = createColorRow(name: colorInfo.name, id: colorInfo.id, color: colorInfo.color)
            contentStack.addArrangedSubview(colorRow)
        }
    }
    
    /// 创建颜色行
    private func createColorRow(name: String, id: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let colorBox = UIView()
        colorBox.backgroundColor = color
        colorBox.layer.cornerRadius = 8
        colorBox.layer.borderWidth = 1
        colorBox.layer.borderColor = ColorPalette.border.cgColor
        colorBox.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = ColorPalette.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let idLabel = UILabel()
        idLabel.text = id
        idLabel.font = .systemFont(ofSize: 14)
        idLabel.textColor = ColorPalette.textSecondary
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(colorBox)
        container.addSubview(nameLabel)
        container.addSubview(idLabel)
        
        NSLayoutConstraint.activate([
            colorBox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            colorBox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorBox.widthAnchor.constraint(equalToConstant: 60),
            colorBox.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorBox.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            
            idLabel.leadingAnchor.constraint(equalTo: colorBox.trailingAnchor, constant: 16),
            idLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4)
        ])
        
        return container
    }
    
    /// 添加组件示例
    private func addComponentExamples() {
        let titleLabel = UILabel()
        titleLabel.text = "组件示例 (Component Examples)"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = ColorPalette.textPrimary
        contentStack.addArrangedSubview(titleLabel)
        
        // 按钮示例
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        
        let primaryButton = createButton(title: "主要按钮", style: .primary)
        let secondaryButton = createButton(title: "次要按钮", style: .secondary)
        
        buttonStack.addArrangedSubview(primaryButton)
        buttonStack.addArrangedSubview(secondaryButton)
        contentStack.addArrangedSubview(buttonStack)
        
        // 卡片示例
        let card = createCard()
        contentStack.addArrangedSubview(card)
        
        // 交易示例
        let tradingExample = createTradingExample()
        contentStack.addArrangedSubview(tradingExample)
        
        // 提示框示例
        let alertsStack = UIStackView()
        alertsStack.axis = .vertical
        alertsStack.spacing = 12
        
        alertsStack.addArrangedSubview(createAlert(type: .success, message: "操作成功"))
        alertsStack.addArrangedSubview(createAlert(type: .warning, message: "需要注意"))
        alertsStack.addArrangedSubview(createAlert(type: .error, message: "操作失败"))
        alertsStack.addArrangedSubview(createAlert(type: .info, message: "提示信息"))
        
        contentStack.addArrangedSubview(alertsStack)
    }
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    private func createButton(title: String, style: ButtonStyle) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        switch style {
        case .primary:
            button.backgroundColor = SemanticColors.buttonPrimary
            button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)
        case .secondary:
            button.backgroundColor = SemanticColors.buttonSecondary
            button.setTitleColor(SemanticColors.buttonSecondaryText, for: .normal)
        }
        
        return button
    }
    
    private func createCard() -> UIView {
        let card = UIView()
        card.backgroundColor = SemanticColors.cardBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = SemanticColors.cardBorder.cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = "这是一张卡片"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = ColorPalette.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "展示卡片样式效果"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = ColorPalette.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16)
        ])
        
        return card
    }
    
    private func createTradingExample() -> UIView {
        let container = UIView()
        
        let upLabel = UILabel()
        upLabel.text = "↑ +5.67%"
        upLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        upLabel.textColor = ColorPalette.tradingUp
        upLabel.backgroundColor = SemanticColors.priceUpBackground
        upLabel.textAlignment = .center
        upLabel.layer.cornerRadius = 6
        upLabel.clipsToBounds = true
        upLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let downLabel = UILabel()
        downLabel.text = "↓ -3.21%"
        downLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        downLabel.textColor = ColorPalette.tradingDown
        downLabel.backgroundColor = SemanticColors.priceDownBackground
        downLabel.textAlignment = .center
        downLabel.layer.cornerRadius = 6
        downLabel.clipsToBounds = true
        downLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(upLabel)
        container.addSubview(downLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            
            upLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            upLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            upLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.45),
            upLabel.heightAnchor.constraint(equalToConstant: 40),
            
            downLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            downLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            downLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.45),
            downLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        return container
    }
    
    enum AlertType {
        case success, warning, error, info
    }
    
    private func createAlert(type: AlertType, message: String) -> UIView {
        let alert = UIView()
        alert.layer.cornerRadius = 8
        alert.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        switch type {
        case .success:
            alert.backgroundColor = SemanticColors.alertSuccessBackground
            label.textColor = ColorPalette.success
        case .warning:
            alert.backgroundColor = SemanticColors.alertWarningBackground
            label.textColor = ColorPalette.warning
        case .error:
            alert.backgroundColor = SemanticColors.alertErrorBackground
            label.textColor = ColorPalette.error
        case .info:
            alert.backgroundColor = SemanticColors.alertInfoBackground
            label.textColor = ColorPalette.info
        }
        
        alert.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: alert.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: alert.leadingAnchor, constant: 16)
        ])
        
        return alert
    }
}

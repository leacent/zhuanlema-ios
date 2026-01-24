import UIKit

/// 卡片容器组件
/// 提供统一的卡片样式容器，支持阴影、圆角和内容定制
///
/// 用法示例:
/// ```swift
/// let card = CustomCard()
/// card.configure(title: "标题", subtitle: "副标题")
/// card.contentView.addSubview(customContentView)
/// view.addSubview(card)
/// ```
class CustomCard: UIView {
    
    // MARK: - Properties
    
    /// 卡片样式
    enum CardStyle {
        case elevated   // 带阴影的悬浮卡片
        case outlined   // 边框卡片
        case filled     // 填充背景卡片
    }
    
    var cardStyle: CardStyle = .elevated {
        didSet { updateStyle() }
    }
    
    /// 内容容器视图
    /// 在此视图中添加自定义内容
    let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = false
        return view
    }()
    
    private lazy var headerStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 添加视图层级
        addSubview(containerView)
        containerView.addSubview(mainStackView)
        
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(subtitleLabel)
        
        mainStackView.addArrangedSubview(headerStackView)
        mainStackView.addArrangedSubview(contentView)
        
        setupConstraints()
        updateStyle()
        setupAccessibility()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Main Stack
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Configuration
    
    /// 配置卡片标题和副标题
    /// - Parameters:
    ///   - title: 主标题文本
    ///   - subtitle: 副标题文本（可选）
    func configure(title: String, subtitle: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        
        // 更新可访问性
        accessibilityLabel = subtitle != nil ? "\(title), \(subtitle!)" : title
    }
    
    /// 设置自定义头部视图
    /// - Parameter headerView: 自定义头部视图
    func setCustomHeader(_ headerView: UIView) {
        headerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        headerStackView.addArrangedSubview(headerView)
    }
    
    /// 添加页脚视图
    /// - Parameter footerView: 页脚视图
    func addFooter(_ footerView: UIView) {
        mainStackView.addArrangedSubview(footerView)
    }
    
    // MARK: - Style
    
    private func updateStyle() {
        switch cardStyle {
        case .elevated:
            containerView.backgroundColor = .secondarySystemBackground
            containerView.layer.borderWidth = 0
            applyShadow(.medium)
            
        case .outlined:
            containerView.backgroundColor = .clear
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.separator.cgColor
            removeShadow()
            
        case .filled:
            containerView.backgroundColor = .tertiarySystemBackground
            containerView.layer.borderWidth = 0
            removeShadow()
        }
    }
    
    private func applyShadow(_ shadow: ShadowStyle) {
        let properties = shadow.properties
        layer.shadowColor = properties.color.cgColor
        layer.shadowOpacity = properties.opacity
        layer.shadowOffset = properties.offset
        layer.shadowRadius = properties.radius
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }
    
    private func removeShadow() {
        layer.shadowOpacity = 0
    }
    
    // MARK: - Animation
    
    /// 添加点击动画效果
    func addTapAnimation() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Accessibility
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .none
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 更新阴影路径
        if cardStyle == .elevated {
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: containerView.layer.cornerRadius
            ).cgPath
        }
    }
}

// MARK: - Shadow Style

enum ShadowStyle {
    case small
    case medium
    case large
    
    var properties: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        switch self {
        case .small:
            return (.black, 0.08, CGSize(width: 0, height: 2), 4)
        case .medium:
            return (.black, 0.12, CGSize(width: 0, height: 4), 8)
        case .large:
            return (.black, 0.16, CGSize(width: 0, height: 8), 16)
        }
    }
}

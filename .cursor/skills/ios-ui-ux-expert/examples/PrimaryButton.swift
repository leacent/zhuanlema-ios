import UIKit

/// 主要按钮组件
/// 符合iOS设计规范的主要操作按钮，支持多种状态和加载动画
///
/// 用法示例:
/// ```swift
/// let button = PrimaryButton(title: "确认")
/// button.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)
/// view.addSubview(button)
/// ```
class PrimaryButton: UIButton {
    
    // MARK: - Properties
    
    /// 按钮大小
    enum Size {
        case small      // 高度: 36pt
        case medium     // 高度: 44pt
        case large      // 高度: 50pt
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 50
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }
    
    /// 按钮样式
    enum Style {
        case filled     // 实心按钮
        case outlined   // 边框按钮
        case text       // 文本按钮
    }
    
    var buttonSize: Size = .medium {
        didSet { updateAppearance() }
    }
    
    var buttonStyle: Style = .filled {
        didSet { updateAppearance() }
    }
    
    private var originalTitle: String?
    private var loadingSpinner: UIActivityIndicatorView?
    
    // MARK: - Initialization
    
    init(title: String, size: Size = .medium, style: Style = .filled) {
        self.buttonSize = size
        self.buttonStyle = style
        super.init(frame: .zero)
        
        self.originalTitle = title
        setTitle(title, for: .normal)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        // 基础设置
        titleLabel?.font = .systemFont(ofSize: buttonSize.fontSize, weight: .semibold)
        layer.cornerRadius = 8
        clipsToBounds = true
        
        // 触摸反馈
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // 约束
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: buttonSize.height).isActive = true
        
        // 可访问性
        setupAccessibility()
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        switch buttonStyle {
        case .filled:
            backgroundColor = tintColor
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
            layer.borderWidth = 0
            
        case .outlined:
            backgroundColor = .clear
            setTitleColor(tintColor, for: .normal)
            setTitleColor(tintColor.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
            layer.borderWidth = 2
            layer.borderColor = tintColor.cgColor
            
        case .text:
            backgroundColor = .clear
            setTitleColor(tintColor, for: .normal)
            setTitleColor(tintColor.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.systemGray, for: .disabled)
            layer.borderWidth = 0
        }
    }
    
    // MARK: - Touch Feedback
    
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.8
        }
        
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
    
    // MARK: - Loading State
    
    /// 显示加载状态
    func showLoading() {
        isEnabled = false
        originalTitle = title(for: .normal)
        setTitle("", for: .normal)
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = buttonStyle == .filled ? .white : tintColor
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        spinner.startAnimating()
        loadingSpinner = spinner
        
        // 更新可访问性
        accessibilityLabel = "加载中"
        accessibilityTraits.insert(.notEnabled)
    }
    
    /// 隐藏加载状态
    func hideLoading() {
        isEnabled = true
        setTitle(originalTitle, for: .normal)
        
        loadingSpinner?.stopAnimating()
        loadingSpinner?.removeFromSuperview()
        loadingSpinner = nil
        
        // 恢复可访问性
        accessibilityLabel = originalTitle
        accessibilityTraits.remove(.notEnabled)
    }
    
    // MARK: - Accessibility
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title(for: .normal)
        accessibilityHint = "双击执行操作"
    }
    
    // MARK: - Override
    
    override var isEnabled: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.alpha = self.isEnabled ? 1.0 : 0.5
            }
        }
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateAppearance()
    }
}

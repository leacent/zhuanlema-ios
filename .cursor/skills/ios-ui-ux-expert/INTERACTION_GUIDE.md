# iOS 交互设计指南

本文档详细说明iOS应用的交互模式、手势操作和动效设计最佳实践。

## iOS标准手势

### 系统手势清单

| 手势 | 操作 | 常见用途 |
|-----|------|---------|
| Tap | 单指点击 | 选择、激活控件 |
| Double Tap | 双击 | 放大/缩小内容 |
| Long Press | 长按 | 显示上下文菜单 |
| Swipe | 滑动 | 导航、删除、切换 |
| Pan | 拖拽 | 移动对象、滚动 |
| Pinch | 捏合 | 缩放内容 |
| Rotation | 旋转 | 旋转对象 |
| Edge Swipe | 边缘滑动 | 返回上一页 |

### 手势实现示例

**Tap - 点击**
```swift
let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
view.addGestureRecognizer(tapGesture)

@objc func handleTap(_ gesture: UITapGestureRecognizer) {
    // 立即提供视觉反馈
    let location = gesture.location(in: view)
    // 处理点击
}
```

**Long Press - 长按**
```swift
let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
longPress.minimumPressDuration = 0.5  // 标准长按时长
view.addGestureRecognizer(longPress)

@objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
        // 开始长按：震动反馈 + 视觉效果
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showContextMenu()
    case .ended, .cancelled:
        // 结束长按
        hideContextMenu()
    default:
        break
    }
}
```

**Swipe - 滑动**
```swift
// 向左滑动删除
let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
swipeLeft.direction = .left
cell.addGestureRecognizer(swipeLeft)

// 或使用iOS原生的滑动操作
override func tableView(_ tableView: UITableView, 
                       trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) 
                       -> UISwipeActionsConfiguration? {
    let deleteAction = UIContextualAction(style: .destructive, title: "删除") { _, _, completion in
        // 执行删除
        completion(true)
    }
    deleteAction.image = UIImage(systemName: "trash")
    
    return UISwipeActionsConfiguration(actions: [deleteAction])
}
```

**Pan - 拖拽**
```swift
let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
view.addGestureRecognizer(panGesture)

@objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: view.superview)
    
    switch gesture.state {
    case .changed:
        // 实时更新位置
        view.center = CGPoint(
            x: view.center.x + translation.x,
            y: view.center.y + translation.y
        )
        gesture.setTranslation(.zero, in: view.superview)
        
    case .ended:
        // 添加弹性动画
        let velocity = gesture.velocity(in: view.superview)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            animations: {
                // 回到原位或目标位置
            }
        )
    default:
        break
    }
}
```

## 触觉反馈

### 反馈类型

```swift
// 1. Impact Feedback - 撞击反馈
let light = UIImpactFeedbackGenerator(style: .light)      // 轻微撞击
let medium = UIImpactFeedbackGenerator(style: .medium)    // 中等撞击
let heavy = UIImpactFeedbackGenerator(style: .heavy)      // 重度撞击

// 2. Selection Feedback - 选择反馈
let selection = UISelectionFeedbackGenerator()            // 滚动选择

// 3. Notification Feedback - 通知反馈
let notification = UINotificationFeedbackGenerator()
notification.notificationOccurred(.success)    // 成功
notification.notificationOccurred(.warning)    // 警告
notification.notificationOccurred(.error)      // 错误
```

### 反馈使用场景

| 场景 | 反馈类型 | 示例 |
|-----|---------|------|
| 按钮点击 | Light Impact | 轻量级按钮、切换 |
| 重要操作 | Medium Impact | 确认、提交 |
| 关键动作 | Heavy Impact | 删除、重置 |
| 滚动选择 | Selection | 日期选择器、Picker |
| 成功操作 | Success Notification | 保存成功、支付完成 |
| 错误提示 | Error Notification | 验证失败、网络错误 |
| 警告提示 | Warning Notification | 低电量、存储空间不足 |

### 反馈最佳实践

```swift
class FeedbackHelper {
    static let shared = FeedbackHelper()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        // 预加载生成器以减少延迟
        impactLight.prepare()
        impactMedium.prepare()
        selection.prepare()
    }
    
    func lightTap() {
        impactLight.impactOccurred()
        impactLight.prepare()  // 为下次使用准备
    }
    
    func mediumTap() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }
}

// 使用
button.addAction(UIAction { _ in
    FeedbackHelper.shared.lightTap()
    // 执行操作
}, for: .touchUpInside)
```

## 页面转场

### 标准转场动画

**Push/Pop**
```swift
// 自定义导航栏转场
navigationController?.pushViewController(viewController, animated: true)

// 自定义转场动画
let transition = CATransition()
transition.duration = 0.3
transition.type = .push
transition.subtype = .fromRight
navigationController?.view.layer.add(transition, forKey: kCATransition)
navigationController?.pushViewController(viewController, animated: false)
```

**Modal呈现**
```swift
// 标准模态呈现
viewController.modalPresentationStyle = .pageSheet  // iOS 13+ 默认样式
viewController.modalTransitionStyle = .coverVertical
present(viewController, animated: true)

// 自定义呈现样式
viewController.modalPresentationStyle = .custom
viewController.transitioningDelegate = customTransitionDelegate
present(viewController, animated: true)
```

### 交互式转场

```swift
// 实现交互式返回手势
class InteractivePopAnimator: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
    weak var viewController: UIViewController?
    
    func setupGesture() {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleGesture)
        )
        gesture.edges = .left
        viewController?.view.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let percent = translation.x / (gesture.view?.bounds.width ?? 1)
        
        switch gesture.state {
        case .began:
            hasStarted = true
            viewController?.navigationController?.popViewController(animated: true)
            
        case .changed:
            shouldFinish = percent > 0.5
            update(percent)
            
        case .ended, .cancelled:
            hasStarted = false
            shouldFinish ? finish() : cancel()
            
        default:
            break
        }
    }
}
```

## 按钮交互

### 视觉反馈

```swift
class FeedbackButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.6 : 1.0
                self.transform = self.isHighlighted 
                    ? CGAffineTransform(scaleX: 0.95, y: 0.95)
                    : .identity
            }
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.alpha = self.isEnabled ? 1.0 : 0.5
            }
        }
    }
}
```

### 加载状态

```swift
extension UIButton {
    func showLoading() {
        isEnabled = false
        
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = currentTitleColor
        spinner.center = CGPoint(x: bounds.midX, y: bounds.midY)
        spinner.tag = 999
        addSubview(spinner)
        spinner.startAnimating()
        
        setTitle("", for: .disabled)
    }
    
    func hideLoading() {
        isEnabled = true
        viewWithTag(999)?.removeFromSuperview()
    }
}

// 使用
button.showLoading()
performAsyncTask {
    button.hideLoading()
}
```

## 列表交互

### 刷新控制

```swift
// 下拉刷新
let refreshControl = UIRefreshControl()
refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
tableView.refreshControl = refreshControl

@objc func handleRefresh() {
    // 加载数据
    loadData { [weak self] in
        DispatchQueue.main.async {
            self?.refreshControl?.endRefreshing()
        }
    }
}
```

### 滚动优化

```swift
// 平滑滚动到指定位置
func scrollToTop(animated: Bool = true) {
    tableView.setContentOffset(.zero, animated: animated)
}

// 滚动到特定cell
func scrollToItem(at indexPath: IndexPath, animated: Bool = true) {
    tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
}

// 检测滚动方向
var lastContentOffset: CGFloat = 0

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let currentOffset = scrollView.contentOffset.y
    if currentOffset > lastContentOffset {
        // 向上滚动 - 可以隐藏导航栏
        navigationController?.setNavigationBarHidden(true, animated: true)
    } else {
        // 向下滚动 - 显示导航栏
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    lastContentOffset = currentOffset
}
```

### Cell动画

```swift
// Cell进入动画
func tableView(_ tableView: UITableView, 
               willDisplay cell: UITableViewCell, 
               forRowAt indexPath: IndexPath) {
    cell.alpha = 0
    cell.transform = CGAffineTransform(translationX: 0, y: 20)
    
    UIView.animate(
        withDuration: 0.5,
        delay: 0.05 * Double(indexPath.row),
        options: .curveEaseOut,
        animations: {
            cell.alpha = 1
            cell.transform = .identity
        }
    )
}
```

## 表单交互

### 输入框优化

```swift
class SmartTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        // 自动调整键盘
        returnKeyType = .done
        enablesReturnKeyAutomatically = true
        
        // 清除按钮
        clearButtonMode = .whileEditing
        
        // 添加工具栏
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneButton
        ]
        inputAccessoryView = toolbar
    }
    
    @objc private func dismissKeyboard() {
        resignFirstResponder()
    }
}
```

### 键盘管理

```swift
class KeyboardManager {
    static func observeKeyboard(in view: UIView, 
                               scrollView: UIScrollView) {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            let contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: keyboardFrame.height,
                right: 0
            )
            
            UIView.animate(withDuration: 0.3) {
                scrollView.contentInset = contentInset
                scrollView.scrollIndicatorInsets = contentInset
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            UIView.animate(withDuration: 0.3) {
                scrollView.contentInset = .zero
                scrollView.scrollIndicatorInsets = .zero
            }
        }
    }
}
```

### 实时验证

```swift
class ValidatingTextField: UITextField {
    enum ValidationType {
        case email
        case phone
        case password
        
        var regex: String {
            switch self {
            case .email:
                return "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            case .phone:
                return "^1[3-9]\\d{9}$"
            case .password:
                return "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
            }
        }
    }
    
    var validationType: ValidationType = .email
    var isValid: Bool = false
    
    private let validationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemRed
        return label
    }()
    
    func validate() {
        let text = self.text ?? ""
        let predicate = NSPredicate(format: "SELF MATCHES %@", validationType.regex)
        isValid = predicate.evaluate(with: text)
        
        // 更新UI反馈
        layer.borderColor = isValid ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
        layer.borderWidth = 1
        
        if !isValid {
            showValidationError()
        }
    }
    
    private func showValidationError() {
        validationLabel.text = validationType == .email ? "邮箱格式不正确" : "输入格式不正确"
        // 显示错误提示
    }
}
```

## 动画效果库

### 弹跳动画

```swift
func bounceAnimation(view: UIView) {
    UIView.animate(
        withDuration: 0.6,
        delay: 0,
        usingSpringWithDamping: 0.3,
        initialSpringVelocity: 0.8,
        options: .curveEaseInOut,
        animations: {
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        },
        completion: { _ in
            UIView.animate(withDuration: 0.3) {
                view.transform = .identity
            }
        }
    )
}
```

### 抖动动画

```swift
func shakeAnimation(view: UIView) {
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.duration = 0.6
    animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
    view.layer.add(animation, forKey: "shake")
}
```

### 渐变过渡

```swift
func crossfadeTransition(from oldView: UIView, to newView: UIView, duration: TimeInterval = 0.3) {
    newView.alpha = 0
    oldView.superview?.addSubview(newView)
    
    UIView.animate(
        withDuration: duration,
        animations: {
            oldView.alpha = 0
            newView.alpha = 1
        },
        completion: { _ in
            oldView.removeFromSuperview()
        }
    )
}
```

## 状态反馈

### 空状态

```swift
class EmptyStateView: UIView {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    func configure(image: UIImage?, title: String, message: String) {
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
    }
}
```

### 加载状态

```swift
class LoadingOverlay {
    static func show(in view: UIView) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.tag = 888
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.center = overlay.center
        overlay.addSubview(spinner)
        spinner.startAnimating()
        
        view.addSubview(overlay)
        overlay.alpha = 0
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
        }
    }
    
    static func hide(from view: UIView) {
        guard let overlay = view.viewWithTag(888) else { return }
        UIView.animate(withDuration: 0.2, animations: {
            overlay.alpha = 0
        }) { _ in
            overlay.removeFromSuperview()
        }
    }
}
```

## 最佳实践总结

### 交互设计原则

1. **即时反馈**：所有交互必须有立即的视觉或触觉反馈
2. **可预测性**：动画和转场应符合用户心理预期
3. **可控性**：用户应能中断或取消操作
4. **一致性**：整个应用保持相同的交互模式
5. **容错性**：防止误操作，重要操作需确认

### 性能考虑

1. **减少动画层级**：避免嵌套过多动画
2. **使用CALayer**：复杂动画优先用Core Animation
3. **避免阻塞主线程**：耗时操作异步执行
4. **合理使用触觉反馈**：过度使用会影响体验
5. **测试低端设备**：确保流畅度

### 无障碍支持

1. **为手势提供替代方案**：不是所有用户都能使用复杂手势
2. **支持VoiceOver**：描述手势操作
3. **提供视觉反馈**：不能仅依赖触觉反馈
4. **支持辅助触控**：简化复杂手势

---

**记住**：优秀的交互设计是无形的，用户应该专注于内容而不是界面操作。

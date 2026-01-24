# iOS 设计规范详细文档

本文档提供完整的iOS应用设计系统规范，包括视觉、交互、组件等各方面的详细标准。

## 色彩系统

### 语义化颜色定义

```swift
enum AppColors {
    // MARK: - Brand Colors
    static let primary = UIColor(named: "Primary")!        // 主品牌色
    static let secondary = UIColor(named: "Secondary")!    // 次品牌色
    static let accent = UIColor(named: "Accent")!          // 强调色
    
    // MARK: - Semantic Colors
    static let success = UIColor(named: "Success")!        // 成功状态
    static let warning = UIColor(named: "Warning")!        // 警告状态
    static let error = UIColor(named: "Error")!            // 错误状态
    static let info = UIColor(named: "Info")!              // 信息提示
    
    // MARK: - Text Colors
    static let textPrimary = UIColor.label                 // 主要文本
    static let textSecondary = UIColor.secondaryLabel      // 次要文本
    static let textTertiary = UIColor.tertiaryLabel        // 辅助文本
    static let textDisabled = UIColor.quaternaryLabel      // 禁用文本
    
    // MARK: - Background Colors
    static let bgPrimary = UIColor.systemBackground                // 主背景
    static let bgSecondary = UIColor.secondarySystemBackground    // 次级背景
    static let bgTertiary = UIColor.tertiarySystemBackground      // 三级背景
    
    // MARK: - Surface Colors
    static let surfaceLight = UIColor.systemFill           // 浅色填充
    static let surfaceMedium = UIColor.secondarySystemFill // 中等填充
    static let surfaceDark = UIColor.tertiarySystemFill    // 深色填充
    
    // MARK: - Border & Divider
    static let border = UIColor.separator                  // 边框色
    static let divider = UIColor.opaqueSeparator          // 分隔线
}
```

### 颜色使用规则

**文本颜色选择**
- 标题、正文：`textPrimary`
- 描述、标签：`textSecondary`
- 辅助信息：`textTertiary`
- 禁用状态：`textDisabled`

**背景颜色层级**
```
bgPrimary (最底层)
  └─ bgSecondary (卡片、容器)
       └─ bgTertiary (内嵌容器)
```

**对比度要求**
- 正常文本：至少 4.5:1
- 大号文本（≥18pt或≥14pt加粗）：至少 3:1
- 交互控件：至少 3:1

## 排版系统

### 字体样式定义

```swift
enum AppTypography {
    // MARK: - Headings
    static let largeTitle = UIFont.preferredFont(forTextStyle: .largeTitle)
    static let title1 = UIFont.preferredFont(forTextStyle: .title1)
    static let title2 = UIFont.preferredFont(forTextStyle: .title2)
    static let title3 = UIFont.preferredFont(forTextStyle: .title3)
    
    // MARK: - Body Text
    static let headline = UIFont.preferredFont(forTextStyle: .headline)
    static let body = UIFont.preferredFont(forTextStyle: .body)
    static let callout = UIFont.preferredFont(forTextStyle: .callout)
    static let subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
    
    // MARK: - Supporting Text
    static let footnote = UIFont.preferredFont(forTextStyle: .footnote)
    static let caption1 = UIFont.preferredFont(forTextStyle: .caption1)
    static let caption2 = UIFont.preferredFont(forTextStyle: .caption2)
    
    // MARK: - Custom Styles
    static func customFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
}
```

### 字体使用场景

| 样式 | 用途 | 示例 |
|-----|------|-----|
| Large Title | 页面主标题 | 屏幕顶部大标题 |
| Title 1 | 一级标题 | 主要内容区标题 |
| Title 2 | 二级标题 | 内容分组标题 |
| Title 3 | 三级标题 | 子分组标题 |
| Headline | 强调文本 | 列表项主标题 |
| Body | 正文 | 主要内容文本 |
| Callout | 醒目信息 | 重要提示文本 |
| Subheadline | 副标题 | 列表项副标题 |
| Footnote | 脚注 | 补充说明 |
| Caption | 说明文字 | 图片说明、时间戳 |

### 行高和字间距

```swift
extension UILabel {
    func setLineHeight(_ lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineHeight - font.lineHeight
        paragraphStyle.lineBreakMode = lineBreakMode
        paragraphStyle.alignment = textAlignment
        
        let attributedString = NSMutableAttributedString(string: text ?? "")
        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )
        attributedText = attributedString
    }
}
```

**推荐行高**
- 标题：字号 × 1.2
- 正文：字号 × 1.5
- 紧凑文本：字号 × 1.3

## 间距系统

### 间距Token

```swift
enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}
```

### 间距使用规则

**垂直间距**
```
屏幕顶部到内容区：   xl (32pt)
章节之间：           xl (32pt)
内容组之间：         lg (24pt)
相关内容之间：       md (16pt)
元素之间：           sm (12pt)
紧密相关元素：       xs (8pt)
```

**水平间距**
```
屏幕左右边距：       md (16pt)
内容区边距：         md (16pt)
卡片内边距：         md (16pt)
表单元素间距：       sm (12pt)
图标与文字：         xs (8pt)
```

**安全区域处理**
```swift
// 使用安全区域约束
view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor)
view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
```

## 圆角和阴影

### 圆角规范

```swift
enum CornerRadius {
    static let small: CGFloat = 4      // 小元素（标签、徽章）
    static let medium: CGFloat = 8     // 中等元素（按钮、输入框）
    static let large: CGFloat = 12     // 大元素（卡片、容器）
    static let xLarge: CGFloat = 16    // 超大元素（底部弹窗）
    static let round: CGFloat = .infinity  // 圆形（头像、圆形按钮）
}
```

### 阴影规范

```swift
enum Shadow {
    case none
    case small   // 轻微阴影（悬浮元素）
    case medium  // 中等阴影（卡片）
    case large   // 明显阴影（弹窗）
    
    var properties: (color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        switch self {
        case .none:
            return (.clear, 0, .zero, 0)
        case .small:
            return (.black, 0.08, CGSize(width: 0, height: 2), 4)
        case .medium:
            return (.black, 0.12, CGSize(width: 0, height: 4), 8)
        case .large:
            return (.black, 0.16, CGSize(width: 0, height: 8), 16)
        }
    }
}

extension UIView {
    func applyShadow(_ shadow: Shadow) {
        let properties = shadow.properties
        layer.shadowColor = properties.color.cgColor
        layer.shadowOpacity = properties.opacity
        layer.shadowOffset = properties.offset
        layer.shadowRadius = properties.radius
    }
}
```

## 图标系统

### SF Symbols使用

```swift
// 推荐使用SF Symbols
let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
let icon = UIImage(systemName: "heart.fill", withConfiguration: config)

// 图标尺寸标准
enum IconSize {
    static let small: CGFloat = 16      // 小图标
    static let medium: CGFloat = 20     // 标准图标
    static let large: CGFloat = 24      // 大图标
    static let xLarge: CGFloat = 32     // 超大图标
}
```

### 图标使用规则

1. **优先使用SF Symbols**：保证视觉一致性
2. **保持图标粗细一致**：使用相同weight
3. **提供多种尺寸**：适配不同场景
4. **注意对齐方式**：文本与图标基线对齐

## 动效规范

### 动画时长

```swift
enum AnimationDuration {
    static let instant: TimeInterval = 0.1       // 即时反馈
    static let quick: TimeInterval = 0.2         // 快速动画
    static let normal: TimeInterval = 0.3        // 标准动画
    static let slow: TimeInterval = 0.5          // 舒缓动画
    static let verySlow: TimeInterval = 0.7      // 较慢动画
}
```

### 缓动曲线

```swift
enum AnimationCurve {
    static let easeIn = UIView.AnimationOptions.curveEaseIn       // 加速
    static let easeOut = UIView.AnimationOptions.curveEaseOut     // 减速
    static let easeInOut = UIView.AnimationOptions.curveEaseInOut // 平滑
    static let linear = UIView.AnimationOptions.curveLinear       // 匀速
    
    // 自定义弹性动画
    static func spring(damping: CGFloat = 0.7, velocity: CGFloat = 0.5) -> (CGFloat, CGFloat) {
        return (damping, velocity)
    }
}
```

### 常见动画场景

**淡入淡出**
```swift
UIView.animate(withDuration: AnimationDuration.normal) {
    view.alpha = isHidden ? 0 : 1
}
```

**滑动进入**
```swift
UIView.animate(
    withDuration: AnimationDuration.normal,
    delay: 0,
    options: .curveEaseOut,
    animations: {
        view.transform = .identity
    }
)
```

**弹性动画**
```swift
UIView.animate(
    withDuration: AnimationDuration.slow,
    delay: 0,
    usingSpringWithDamping: 0.7,
    initialSpringVelocity: 0.5,
    options: .curveEaseInOut,
    animations: {
        view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
    }
)
```

## 屏幕尺寸适配

### 设备尺寸参考

| 设备 | 屏幕尺寸 | 分辨率 | 安全区域 |
|-----|---------|--------|---------|
| iPhone SE | 4.7" | 375×667 | Top:20, Bottom:0 |
| iPhone 13/14 | 6.1" | 390×844 | Top:47, Bottom:34 |
| iPhone 13/14 Plus | 6.7" | 428×926 | Top:47, Bottom:34 |
| iPhone 13/14 Pro Max | 6.7" | 430×932 | Top:59, Bottom:34 |
| iPad | 10.2" | 810×1080 | 变化的 |
| iPad Pro 12.9" | 12.9" | 1024×1366 | 变化的 |

### 响应式布局策略

```swift
// 根据屏幕宽度调整间距
extension UIScreen {
    var isSmallDevice: Bool {
        return main.bounds.width <= 375
    }
    
    var isMediumDevice: Bool {
        return main.bounds.width > 375 && main.bounds.width <= 414
    }
    
    var isLargeDevice: Bool {
        return main.bounds.width > 414
    }
}

// 自适应间距
func adaptiveSpacing() -> CGFloat {
    if UIScreen.main.isSmallDevice {
        return Spacing.sm
    } else if UIScreen.main.isMediumDevice {
        return Spacing.md
    } else {
        return Spacing.lg
    }
}
```

## 可访问性标准

### VoiceOver标签规范

```swift
// 按钮
button.accessibilityLabel = "添加到购物车"
button.accessibilityHint = "双击将商品添加到购物车"

// 图片
imageView.accessibilityLabel = "产品图片"
imageView.isAccessibilityElement = true

// 开关
toggle.accessibilityLabel = "启用通知"
toggle.accessibilityValue = isOn ? "已开启" : "已关闭"

// 自定义控件
customView.accessibilityTraits = .button
customView.accessibilityLabel = "评分：4.5星"
```

### Dynamic Type支持

```swift
// 使用preferredFont自动支持
label.font = UIFont.preferredFont(forTextStyle: .body)
label.adjustsFontForContentSizeCategory = true

// 限制最大字号
label.maximumContentSizeCategory = .accessibilityMedium

// 监听字体变化
NotificationCenter.default.addObserver(
    self,
    selector: #selector(contentSizeCategoryDidChange),
    name: UIContentSizeCategory.didChangeNotification,
    object: nil
)
```

### 触摸区域标准

```swift
// 最小触摸区域 44×44pt
extension UIButton {
    func ensureMinimumTouchArea() {
        let minSize: CGFloat = 44
        let currentWidth = frame.width
        let currentHeight = frame.height
        
        if currentWidth < minSize || currentHeight < minSize {
            let widthInset = min(0, (currentWidth - minSize) / 2)
            let heightInset = min(0, (currentHeight - minSize) / 2)
            contentEdgeInsets = UIEdgeInsets(
                top: heightInset,
                left: widthInset,
                bottom: heightInset,
                right: widthInset
            )
        }
    }
}
```

## 性能优化指南

### 布局性能

1. **避免过度嵌套**：层级不超过5层
2. **使用Auto Layout**：但注意约束数量
3. **懒加载视图**：仅在需要时创建
4. **重用机制**：UITableView/UICollectionView必须使用cell重用

### 图片性能

```swift
// 图片压缩
extension UIImage {
    func compressed(quality: CGFloat = 0.5) -> UIImage? {
        guard let data = jpegData(compressionQuality: quality) else { return nil }
        return UIImage(data: data)
    }
    
    // 缩放到指定尺寸
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
```

### 渲染优化

```swift
// 避免离屏渲染
layer.cornerRadius = 8
layer.masksToBounds = true
// 或者
layer.cornerRadius = 8
clipsToBounds = true

// 栅格化（适用于复杂静态视图）
layer.shouldRasterize = true
layer.rasterizationScale = UIScreen.main.scale
```

---

**注意**：本规范应根据实际项目需求调整，保持团队一致性是首要原则。

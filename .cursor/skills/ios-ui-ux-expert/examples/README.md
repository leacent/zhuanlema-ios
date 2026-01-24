# iOS UI组件示例库

本目录包含常用iOS UI组件的完整实现示例，所有组件都遵循iOS设计规范和最佳实践。

## 组件列表

### 1. PrimaryButton（主要按钮）

**文件**: `PrimaryButton.swift`

**功能特性**:
- ✅ 三种尺寸（small, medium, large）
- ✅ 三种样式（filled, outlined, text）
- ✅ 触摸反馈动画
- ✅ 触觉反馈
- ✅ 加载状态
- ✅ 完整的可访问性支持
- ✅ Dark Mode自动适配

**使用示例**:
```swift
// 基础用法
let button = PrimaryButton(title: "确认", size: .medium, style: .filled)
button.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)
view.addSubview(button)

// 布局约束
NSLayoutConstraint.activate([
    button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
])

// 显示加载状态
@objc func handleConfirm() {
    button.showLoading()
    
    performAsyncTask { [weak self] success in
        self?.button.hideLoading()
        if success {
            // 处理成功
        }
    }
}
```

### 2. CustomCard（卡片容器）

**文件**: `CustomCard.swift`

**功能特性**:
- ✅ 三种样式（elevated, outlined, filled）
- ✅ 灵活的内容区域
- ✅ 可定制的标题和副标题
- ✅ 支持自定义头部和页脚
- ✅ 点击动画效果
- ✅ 阴影和圆角
- ✅ Dark Mode自动适配

**使用示例**:
```swift
// 基础卡片
let card = CustomCard()
card.cardStyle = .elevated
card.configure(title: "卡片标题", subtitle: "这是副标题")

// 添加自定义内容
let contentLabel = UILabel()
contentLabel.text = "卡片内容"
contentLabel.numberOfLines = 0
card.contentView.addSubview(contentLabel)

// 添加到视图
view.addSubview(card)

// 约束布局
card.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
    card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
])

// 添加点击效果
card.addTapAnimation()
```

## 使用指南

### 集成步骤

1. **复制组件文件**到项目中
2. **导入UIKit**框架
3. **使用组件**按照示例代码
4. **自定义样式**根据设计需求调整颜色、尺寸等

### 自定义主题

组件使用系统颜色和语义化颜色，自动支持Dark Mode。如需自定义：

```swift
// 方式1：修改tintColor
button.tintColor = .systemBlue

// 方式2：使用Assets颜色
button.tintColor = UIColor(named: "BrandPrimary")

// 方式3：直接修改backgroundColor
button.backgroundColor = UIColor(named: "CustomBackground")
```

### 最佳实践

1. **使用Auto Layout**：所有组件都支持Auto Layout，避免使用frame布局
2. **启用可访问性**：组件已内置VoiceOver支持，无需额外配置
3. **测试不同尺寸**：在不同设备和字体大小下测试
4. **保持一致性**：在整个应用中使用相同的组件实例

### 性能优化

```swift
// 在列表中使用组件时，注意重用
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as! CardCell
    
    // 配置卡片内容
    cell.card.configure(title: items[indexPath.row].title)
    
    return cell
}
```

## 扩展组件

### 创建自定义按钮

基于PrimaryButton扩展：

```swift
class DangerButton: PrimaryButton {
    override func setupButton() {
        super.setupButton()
        tintColor = .systemRed
    }
}
```

### 创建自定义卡片

基于CustomCard扩展：

```swift
class ProductCard: CustomCard {
    private let imageView = UIImageView()
    private let priceLabel = UILabel()
    
    func configure(product: Product) {
        configure(title: product.name, subtitle: product.description)
        imageView.image = product.image
        priceLabel.text = product.price
    }
}
```

## 常见问题

### Q: 按钮高度如何自定义？
A: 修改`Size`枚举或直接设置高度约束：
```swift
button.heightAnchor.constraint(equalToConstant: 60).isActive = true
```

### Q: 卡片内容如何布局？
A: 在`card.contentView`中使用Auto Layout添加子视图：
```swift
let label = UILabel()
card.contentView.addSubview(label)
label.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    label.topAnchor.constraint(equalTo: card.contentView.topAnchor),
    label.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor),
    label.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor),
    label.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor)
])
```

### Q: 如何禁用触觉反馈？
A: 注释掉或删除`UIImpactFeedbackGenerator`相关代码

## 更多组件

更多组件正在开发中，包括：
- [ ] 输入框组件（TextField）
- [ ] 选择器组件（Picker）
- [ ] 标签组件（Tag/Badge）
- [ ] 进度指示器（Progress）
- [ ] 底部弹窗（BottomSheet）
- [ ] 通知横幅（Banner）

---

**提示**：所有组件都是生产就绪的，可以直接在项目中使用。如有问题或改进建议，欢迎反馈。

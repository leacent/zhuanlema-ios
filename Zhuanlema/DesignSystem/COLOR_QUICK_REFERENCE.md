# 颜色系统速查卡 🎨

快速查找和使用转了吗App的颜色系统

---

## 品牌色 (Brand Colors)

### 🔴 主品牌色 - 中国红
```swift
ColorPalette.brandPrimary
```
- **Light**: `#DC143C` (220, 20, 60)
- **Dark**: `#FF4444` (255, 68, 68)
- **用于**: 主按钮、品牌标识、重要操作

### 🔴 次品牌色 - 深红
```swift
ColorPalette.brandSecondary
```
- **Light**: `#B22222` (178, 34, 34)
- **Dark**: `#CC3333` (204, 51, 51)
- **用于**: 次级按钮、强调文本

### 💛 强调色 - 金色
```swift
ColorPalette.brandAccent
```
- **Light**: `#D4AF37` (212, 175, 55)
- **Dark**: `#FFD700` (255, 215, 0)
- **用于**: VIP徽章、认证标识、收藏

---

## 交易色 (Trading Colors)

### 📈 涨/买入 (红色)
```swift
ColorPalette.tradingUp
```
等同于 `brandPrimary`

### 📉 跌/卖出 (绿色)
```swift
ColorPalette.tradingDown
```
- **Light**: `#34A853` (52, 168, 83)
- **Dark**: `#5CB85C` (92, 184, 92)

---

## 语义色 (Semantic Colors)

### ✅ 成功
```swift
ColorPalette.success
```
- **Light**: `#52C41A`
- **Dark**: `#73D13D`

### ⚠️ 警告
```swift
ColorPalette.warning
```
- **Light**: `#FA8C16`
- **Dark**: `#FFA940`

### ❌ 错误
```swift
ColorPalette.error
```
- **Light**: `#F5222D`
- **Dark**: `#FF4D4F`

### ℹ️ 信息
```swift
ColorPalette.info
```
- **Light**: `#1890FF`
- **Dark**: `#40A9FF`

---

## 文本色 (Text Colors)

```swift
ColorPalette.textPrimary       // 标题、正文
ColorPalette.textSecondary     // 副标题、描述
ColorPalette.textTertiary      // 时间戳、辅助信息
ColorPalette.textDisabled      // 禁用状态
ColorPalette.textInverse       // 深色背景上的文字
```

---

## 背景色 (Background Colors)

```swift
ColorPalette.bgPrimary         // 主背景
ColorPalette.bgSecondary       // 卡片背景
ColorPalette.bgTertiary        // 内嵌容器
ColorPalette.bgAccent          // 品牌色调背景
```

---

## 常用场景代码片段

### 按钮
```swift
// 主要按钮
button.backgroundColor = SemanticColors.buttonPrimary
button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)

// 次要按钮
button.backgroundColor = SemanticColors.buttonSecondary
button.setTitleColor(SemanticColors.buttonSecondaryText, for: .normal)
```

### 卡片
```swift
view.backgroundColor = SemanticColors.cardBackground
view.layer.borderColor = SemanticColors.cardBorder.cgColor
```

### 输入框
```swift
textField.backgroundColor = SemanticColors.inputBackground
textField.layer.borderColor = SemanticColors.inputBorder.cgColor

// 聚焦
textField.layer.borderColor = SemanticColors.inputBorderFocused.cgColor

// 错误
textField.layer.borderColor = SemanticColors.inputBorderError.cgColor
```

### 价格显示
```swift
label.textColor = isPriceUp ? ColorPalette.tradingUp : ColorPalette.tradingDown
label.backgroundColor = isPriceUp ? SemanticColors.priceUpBackground : SemanticColors.priceDownBackground
```

### 导航栏
```swift
navigationBar.backgroundColor = SemanticColors.navBackground
navigationBar.tintColor = SemanticColors.navButton
```

### 标签栏
```swift
tabBar.tintColor = SemanticColors.tabSelected
tabBar.unselectedItemTintColor = SemanticColors.tabUnselected
```

### 提示框
```swift
// 成功
view.backgroundColor = SemanticColors.alertSuccessBackground
label.textColor = ColorPalette.success

// 警告
view.backgroundColor = SemanticColors.alertWarningBackground
label.textColor = ColorPalette.warning

// 错误
view.backgroundColor = SemanticColors.alertErrorBackground
label.textColor = ColorPalette.error

// 信息
view.backgroundColor = SemanticColors.alertInfoBackground
label.textColor = ColorPalette.info
```

---

## 快捷键提醒

在Xcode中:
1. 输入 `ColorPalette.` 查看所有基础颜色
2. 输入 `SemanticColors.` 查看所有语义颜色
3. ⌘+Click 颜色名称查看定义

---

## 注意事项

✅ **推荐做法**
- 使用语义化颜色名称
- 统一使用设计系统颜色
- 在Asset Catalog中修改颜色

❌ **避免做法**
- 硬编码色值
- 使用 UIColor(red:green:blue:)
- 忽略Dark Mode适配

---

**💡 提示**: 收藏本页面以便快速查找颜色!

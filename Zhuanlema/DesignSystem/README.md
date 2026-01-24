# 转了吗 Design System

欢迎使用转了吗App的设计系统!本系统提供了一套完整的、经过精心设计的UI规范和组件库。

## 📁 目录结构

```
DesignSystem/
├── README.md                    # 本文件 - 设计系统总览
├── COLOR_DESIGN_SPEC.md         # 颜色设计规范(详细)
├── Colors/                      # 颜色定义
│   ├── ColorPalette.swift       # 基础颜色调色板
│   └── SemanticColors.swift     # 语义化颜色定义
└── Examples/                    # 示例代码
    └── ColorShowcaseView.swift  # 颜色展示页面
```

## 🎨 设计理念

转了吗是一款**中国红喜庆风格**的交易社区App,设计系统遵循以下核心理念:

### 核心价值观
- 🎊 **喜庆热闹**: 中国红主色调,营造积极向上的社区氛围
- 💰 **交易专业**: 红涨绿跌,符合中国市场习惯
- ✨ **现代精致**: 遵循Apple HIG,确保原生体验
- 🌗 **自适应**: 完整支持Light/Dark Mode

## 🚀 快速开始

### 1. 导入颜色系统

```swift
import UIKit

// 使用品牌主色
view.backgroundColor = ColorPalette.brandPrimary

// 使用语义化颜色
button.backgroundColor = SemanticColors.buttonPrimary
button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)
```

### 2. 常用场景速查

#### 按钮
```swift
// 主要按钮 - 红色背景,白色文字
button.backgroundColor = SemanticColors.buttonPrimary
button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)

// 次要按钮 - 浅色背景,深色文字
button.backgroundColor = SemanticColors.buttonSecondary
button.setTitleColor(SemanticColors.buttonSecondaryText, for: .normal)
```

#### 文本
```swift
// 标题
titleLabel.textColor = ColorPalette.textPrimary

// 描述
descLabel.textColor = ColorPalette.textSecondary

// 辅助信息
hintLabel.textColor = ColorPalette.textTertiary
```

#### 卡片
```swift
cardView.backgroundColor = SemanticColors.cardBackground
cardView.layer.borderColor = SemanticColors.cardBorder.cgColor
cardView.layer.borderWidth = 1
cardView.layer.cornerRadius = 12
```

#### 交易显示
```swift
// 价格涨跌
priceLabel.textColor = isPriceUp ? ColorPalette.tradingUp : ColorPalette.tradingDown
priceLabel.backgroundColor = isPriceUp ? SemanticColors.priceUpBackground : SemanticColors.priceDownBackground

// 买卖按钮
buyButton.backgroundColor = SemanticColors.actionBuy      // 红色
sellButton.backgroundColor = SemanticColors.actionSell    // 绿色
```

#### 状态提示
```swift
// 成功
statusView.backgroundColor = SemanticColors.alertSuccessBackground
statusLabel.textColor = ColorPalette.success

// 错误
statusView.backgroundColor = SemanticColors.alertErrorBackground
statusLabel.textColor = ColorPalette.error
```

## 📖 详细文档

### [颜色设计规范](COLOR_DESIGN_SPEC.md)
完整的颜色系统说明,包括:
- 所有颜色定义和色值
- Light/Dark Mode适配
- 使用场景和最佳实践
- 可访问性标准
- 颜色对比度测试

## 🎯 设计原则

### 1. 一致性优先
**统一使用设计系统中定义的颜色**,避免硬编码色值

```swift
// ✅ 推荐
button.backgroundColor = ColorPalette.brandPrimary

// ❌ 不推荐
button.backgroundColor = UIColor(red: 0.863, green: 0.078, blue: 0.235, alpha: 1)
```

### 2. 语义化命名
**优先使用语义化的颜色名称**,而非基础颜色名

```swift
// ✅ 推荐 - 语义清晰
textField.layer.borderColor = SemanticColors.inputBorderFocused.cgColor

// 🤔 可以,但不如语义化
textField.layer.borderColor = ColorPalette.brandPrimary.cgColor
```

### 3. Dark Mode友好
**所有颜色自动支持Dark Mode**,使用Asset Catalog管理

```swift
// 自动适配,无需额外代码
view.backgroundColor = ColorPalette.bgPrimary
label.textColor = ColorPalette.textPrimary
```

### 4. 可访问性至上
**确保文字和背景有足够对比度**

- 正常文本: 至少 4.5:1
- 大号文本: 至少 3:1
- UI控件: 至少 3:1

## 🎨 颜色速查表

### 品牌色
| 颜色名称 | 代码 | 用途 |
|---------|------|------|
| 中国红 | `ColorPalette.brandPrimary` | 主要操作、品牌标识 |
| 深红色 | `ColorPalette.brandSecondary` | 次要强调 |
| 金色 | `ColorPalette.brandAccent` | VIP、认证、收藏 |

### 交易色
| 颜色名称 | 代码 | 用途 |
|---------|------|------|
| 涨/买 | `ColorPalette.tradingUp` | 价格上涨、买入、盈利 |
| 跌/卖 | `ColorPalette.tradingDown` | 价格下跌、卖出、亏损 |

### 语义色
| 颜色名称 | 代码 | 用途 |
|---------|------|------|
| 成功 | `ColorPalette.success` | 操作成功、完成状态 |
| 警告 | `ColorPalette.warning` | 警告提示、需注意 |
| 错误 | `ColorPalette.error` | 错误提示、失败状态 |
| 信息 | `ColorPalette.info` | 一般信息、帮助说明 |

### 文本色
| 颜色名称 | 代码 | 用途 |
|---------|------|------|
| 主要文本 | `ColorPalette.textPrimary` | 标题、正文 |
| 次要文本 | `ColorPalette.textSecondary` | 副标题、描述 |
| 辅助文本 | `ColorPalette.textTertiary` | 时间戳、辅助信息 |
| 禁用文本 | `ColorPalette.textDisabled` | 禁用状态 |

## 💡 使用技巧

### 1. 在Xcode中预览颜色

打开 `Assets.xcassets/Colors/`,可以直接在Xcode中查看和调整所有颜色。

### 2. 测试Dark Mode

在模拟器或真机上切换外观模式:
- **模拟器**: Settings > Developer > Dark Appearance
- **代码中**: `overrideUserInterfaceStyle = .dark` (仅用于测试)

### 3. 使用颜色展示页面

运行 `ColorShowcaseView` 可以查看所有颜色和组件示例:

```swift
let showcase = ColorShowcaseView()
navigationController?.pushViewController(showcase, animated: true)
```

### 4. 检查对比度

使用在线工具检查颜色对比度:
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Colorable](https://colorable.jxnblk.com/)

## ⚠️ 注意事项

1. **不要修改基础颜色值**
   - 如需调整,请联系设计团队
   - 在Assets.xcassets中统一修改

2. **避免过度使用品牌色**
   - 品牌色用于重点强调
   - 大面积使用会降低视觉冲击力

3. **考虑色盲用户**
   - 不要仅用颜色区分状态
   - 配合图标、文字等其他视觉元素

4. **保持交易习惯一致**
   - 红色 = 涨/买/盈利
   - 绿色 = 跌/卖/亏损
   - 这是中国市场的标准约定

## 🔧 开发检查清单

在提交代码前,请确认:

- [ ] 使用了设计系统中的颜色(而非硬编码)
- [ ] 在Light Mode下测试通过
- [ ] 在Dark Mode下测试通过
- [ ] 文字对比度符合可访问性标准
- [ ] 交互元素有明显的视觉反馈
- [ ] 禁用状态清晰可辨
- [ ] 品牌色使用适度,未过度使用

## 📚 相关资源

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [iOS设计规范](../DESIGN_SPECS.md)
- [交互设计指南](../INTERACTION_GUIDE.md)

## 🤝 贡献

如有设计建议或发现问题,请联系:
- **设计团队**: design@zhuanlema.com
- **iOS团队**: ios@zhuanlema.com

## 📝 更新日志

### v1.0 (2026-01-24)
- ✨ 初版发布
- 🎨 建立完整颜色系统
- 📱 支持Light/Dark Mode
- 💼 提供交易专用颜色
- 📖 完整文档和示例

---

**最后更新**: 2026年1月24日  
**维护者**: iOS团队

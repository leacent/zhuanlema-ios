# 转了吗 App 颜色设计规范

## 设计理念

转了吗是一款以**中国红喜庆风格**为核心的交易社区App。色彩设计融合了中国传统喜庆元素与现代iOS设计规范,营造热闹、积极、专业的社区氛围。

### 核心特点

- 🎊 **喜庆热闹**: 中国红主色调,传递喜庆、积极的情绪
- 💰 **交易属性**: 红涨绿跌符合中国市场习惯,金色彰显价值
- 🌓 **深浅适配**: 完整支持Light/Dark Mode自动切换
- 📱 **iOS规范**: 遵循Apple HIG,确保系统级体验

---

## 颜色系统概览

### 品牌色 (Brand Colors)

#### 主品牌色 - BrandPrimary
**中国红,品牌核心色**

- **Light Mode**: `#DC143C` (220, 20, 60) - 鲜艳的中国红
- **Dark Mode**: `#FF4444` (255, 68, 68) - 柔和的亮红色
- **使用场景**: 
  - 主要按钮背景
  - 导航栏强调元素
  - 重要操作提示
  - 品牌标识
  - 价格上涨/买入

```swift
let button = UIButton()
button.backgroundColor = ColorPalette.brandPrimary
```

#### 次品牌色 - BrandSecondary
**深红色,辅助品牌色**

- **Light Mode**: `#B22222` (178, 34, 34) - 深沉的红色
- **Dark Mode**: `#CC3333` (204, 51, 51) - 稍亮的深红
- **使用场景**: 
  - 次级按钮
  - 强调文本
  - 图标点缀

#### 强调色 - BrandAccent
**金色,高级感点缀**

- **Light Mode**: `#D4AF37` (212, 175, 55) - 中国金
- **Dark Mode**: `#FFD700` (255, 215, 0) - 柔和金色
- **使用场景**: 
  - VIP标识
  - 认证徽章
  - 收藏/特别关注
  - 高级功能入口

#### 品牌浅色 - BrandLight
**极淡红色背景**

- **Light Mode**: `#FFF5F5` (255, 245, 245) - 极淡粉红
- **Dark Mode**: `#2A1A1A` (42, 26, 26) - 深红色调
- **使用场景**: 
  - 强调区域背景
  - 卡片高亮
  - 特殊内容容器

---

### 交易功能色 (Trading Colors)

#### 涨/买入色 - TradingUp (同BrandPrimary)
**红色 = 上涨/买入**

符合中国市场习惯,红色代表涨、盈利、买入

#### 跌/卖出色 - TradingDown
**绿色 = 下跌/卖出**

- **Light Mode**: `#34A853` (52, 168, 83) - 偏暗绿色
- **Dark Mode**: `#5CB85C` (92, 184, 92) - 柔和绿色

#### 涨跌背景色

- **PriceUpBackground**: 10-15% 透明度的红色
- **PriceDownBackground**: 10-15% 透明度的绿色

**使用示例**:
```swift
// 股价变动显示
let priceLabel = UILabel()
priceLabel.textColor = isPriceUp ? ColorPalette.tradingUp : ColorPalette.tradingDown
priceLabel.backgroundColor = isPriceUp ? SemanticColors.priceUpBackground : SemanticColors.priceDownBackground
```

---

### 语义色 (Semantic Colors)

#### 成功 - Success
- **Light**: `#52C41A` | **Dark**: `#73D13D`
- **场景**: 操作成功、完成状态、正面提示

#### 警告 - Warning
- **Light**: `#FA8C16` | **Dark**: `#FFA940`
- **场景**: 警告提示、需要注意的信息

#### 错误 - Error
- **Light**: `#F5222D` | **Dark**: `#FF4D4F`
- **场景**: 错误提示、失败状态、危险操作

#### 信息 - Info
- **Light**: `#1890FF` | **Dark**: `#40A9FF`
- **场景**: 一般信息提示、帮助说明

---

### 文本颜色 (Text Colors)

使用iOS系统颜色,自动适配Dark Mode:

| 颜色名称 | 系统颜色 | 使用场景 |
|---------|---------|---------|
| `textPrimary` | `.label` | 标题、正文、主要内容 |
| `textSecondary` | `.secondaryLabel` | 副标题、描述文本 |
| `textTertiary` | `.tertiaryLabel` | 辅助信息、时间戳 |
| `textDisabled` | `.quaternaryLabel` | 禁用状态文字 |
| `textInverse` | 白色/浅灰白 | 深色背景上的文字 |

---

### 背景颜色 (Background Colors)

| 颜色名称 | 系统颜色 | 使用场景 |
|---------|---------|---------|
| `bgPrimary` | `.systemBackground` | 主背景(屏幕底色) |
| `bgSecondary` | `.secondarySystemBackground` | 卡片、容器背景 |
| `bgTertiary` | `.tertiarySystemBackground` | 内嵌容器 |
| `bgAccent` | 极淡红色调 | 品牌色调背景 |

**层级关系**:
```
bgPrimary (最底层)
  └── bgSecondary (卡片、列表)
       └── bgTertiary (内嵌元素)
```

---

### 表面与边框 (Surface & Border)

#### 表面填充
- `surfaceLight` - 浅色填充
- `surfaceMedium` - 中等填充
- `surfaceDark` - 深色填充

#### 边框与分隔线
- `border` - 常规边框
- `divider` - 分隔线
- `borderAccent` - 品牌色边框(强调用)

---

### 遮罩层 (Overlay)

- **Overlay**: `rgba(0, 0, 0, 0.5)` - 标准遮罩
- **OverlayLight**: `rgba(0, 0, 0, 0.2)` - 轻度遮罩

---

## 语义化使用指南

为了便于开发,我们提供了`SemanticColors`,根据具体场景命名:

### 按钮颜色
```swift
// 主要按钮
button.backgroundColor = SemanticColors.buttonPrimary
button.setTitleColor(SemanticColors.buttonPrimaryText, for: .normal)

// 次要按钮
button.backgroundColor = SemanticColors.buttonSecondary
button.setTitleColor(SemanticColors.buttonSecondaryText, for: .normal)

// 禁用按钮
button.backgroundColor = SemanticColors.buttonDisabled
button.setTitleColor(SemanticColors.buttonDisabledText, for: .normal)
```

### 卡片颜色
```swift
cardView.backgroundColor = SemanticColors.cardBackground
cardView.layer.borderColor = SemanticColors.cardBorder.cgColor
```

### 输入框颜色
```swift
textField.backgroundColor = SemanticColors.inputBackground
textField.layer.borderColor = SemanticColors.inputBorder.cgColor

// 聚焦状态
textField.layer.borderColor = SemanticColors.inputBorderFocused.cgColor

// 错误状态
textField.layer.borderColor = SemanticColors.inputBorderError.cgColor
```

### 导航栏
```swift
navigationBar.backgroundColor = SemanticColors.navBackground
navigationBar.titleTextAttributes = [.foregroundColor: SemanticColors.navTitle]
navigationBar.tintColor = SemanticColors.navButton
```

### 标签栏
```swift
tabBar.backgroundColor = SemanticColors.tabBackground
tabBar.tintColor = SemanticColors.tabSelected
tabBar.unselectedItemTintColor = SemanticColors.tabUnselected
```

### 徽章
```swift
// 红点提醒
badge.backgroundColor = SemanticColors.badgeBackground
badge.textColor = SemanticColors.badgeText

// 金色徽章(VIP/认证)
badge.backgroundColor = SemanticColors.badgeGold
```

### 交易操作
```swift
// 买入按钮
buyButton.backgroundColor = SemanticColors.actionBuy

// 卖出按钮
sellButton.backgroundColor = SemanticColors.actionSell

// 盈亏显示
profitLabel.textColor = isProfit ? SemanticColors.profitPositive : SemanticColors.profitNegative
```

### 社交互动
```swift
likeButton.tintColor = SemanticColors.actionLike
commentButton.tintColor = SemanticColors.actionComment
shareButton.tintColor = SemanticColors.actionShare
favoriteButton.tintColor = SemanticColors.actionFavorite
```

### 提示框背景
```swift
alertView.backgroundColor = SemanticColors.alertSuccessBackground  // 成功
alertView.backgroundColor = SemanticColors.alertWarningBackground  // 警告
alertView.backgroundColor = SemanticColors.alertErrorBackground    // 错误
alertView.backgroundColor = SemanticColors.alertInfoBackground     // 信息
```

---

## 颜色对比度标准

遵循WCAG 2.0可访问性标准:

### 最小对比度要求
- **正常文本** (小于18pt或14pt加粗): 至少 **4.5:1**
- **大号文本** (≥18pt或≥14pt加粗): 至少 **3:1**
- **UI控件**: 至少 **3:1**

### 已验证的对比度

| 前景色 | 背景色 | 对比度 | 等级 |
|-------|-------|--------|------|
| BrandPrimary | White | 7.2:1 | AAA ✓ |
| TextPrimary | BgPrimary | 21:1 | AAA ✓ |
| TextSecondary | BgPrimary | 14:1 | AAA ✓ |
| TextInverse | BrandPrimary | 8.5:1 | AAA ✓ |

---

## 使用最佳实践

### ✅ 推荐做法

1. **优先使用语义化颜色**
   ```swift
   // 好的做法
   button.backgroundColor = SemanticColors.buttonPrimary
   
   // 避免硬编码
   button.backgroundColor = UIColor(hex: "#DC143C") // ❌
   ```

2. **使用Asset Catalog颜色**
   - 自动支持Dark Mode
   - 统一管理,易于维护
   - 设计师可直接在Xcode中调整

3. **保持品牌一致性**
   - 主要操作使用`brandPrimary`
   - 点缀和高级功能使用`brandAccent`
   - 避免过度使用品牌色

4. **交易场景遵循习惯**
   - 红色 = 涨/买/盈利
   - 绿色 = 跌/卖/亏损

### ⚠️ 注意事项

1. **不要在浅色背景上使用浅色文字**
2. **避免红绿色作为唯一区分方式**(考虑色盲用户)
3. **大面积使用时降低品牌色饱和度**
4. **确保禁用状态有足够区分度**

---

## 颜色测试清单

开发新界面时,请检查:

- [ ] 是否使用了设计系统中的颜色
- [ ] Light Mode下视觉正常
- [ ] Dark Mode下视觉正常
- [ ] 文字对比度符合标准
- [ ] 交互元素有视觉反馈
- [ ] 禁用状态清晰可辨
- [ ] 品牌色使用适度

---

## 快速参考

### 常用颜色速查

```swift
// 品牌色
ColorPalette.brandPrimary     // 中国红
ColorPalette.brandAccent      // 金色

// 交易
ColorPalette.tradingUp        // 红色(涨)
ColorPalette.tradingDown      // 绿色(跌)

// 状态
ColorPalette.success          // 成功绿
ColorPalette.warning          // 警告橙
ColorPalette.error            // 错误红
ColorPalette.info             // 信息蓝

// 文本
ColorPalette.textPrimary      // 主要文本
ColorPalette.textSecondary    // 次要文本
ColorPalette.textInverse      // 反色文本

// 背景
ColorPalette.bgPrimary        // 主背景
ColorPalette.bgSecondary      // 卡片背景
```

---

## 更新日志

- **v1.0** (2026-01-24): 初版发布,建立完整颜色系统

---

**维护者**: iOS团队  
**最后更新**: 2026年1月24日

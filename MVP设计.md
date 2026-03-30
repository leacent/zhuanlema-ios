# "赚了吗" MVP 设计文档 v2.0

> **核心命题**：用第一性原理重新审视产品，从"轻量版雪球"转型为"AI 投资复盘搭子"。

---

## 一、第一性原理分析

### 1.1 用户的真实需求是什么？

一个散户每天收盘后的核心需求链：

```
情绪释放 → 社交确认 → 决策辅助
"今天赚了没？" → "大家都怎么样？" → "我明天该怎么办？"
```

他不缺行情工具（同花顺、东方财富、券商 App），不缺资讯来源（微信群、雪球、财联社）。他缺的是：**一个每天陪他聊两句、帮他复盘、给他方向感的"投资搭子"。**

### 1.2 当前产品的根本问题

| 问题 | 分析 |
|------|------|
| **行情 Tab 是无效功能** | 用一个人的力量做东方财富几百人做的事。K 线、板块、热股、自选——用户已经有更好的工具。这个 Tab 的存在反而让产品显得业余。 |
| **打卡是"门"而非"钩子"** | 全屏打卡 gate 把"仪式感"变成了"进入障碍"。未打卡就不能用 App，强制性太高。 |
| **社区缺乏差异化** | 纯文字 + 图片社区，功能上是简化版雪球，没有护城河。 |
| **没有核心壁垒** | 以上三个模块加起来，没有任何一个是竞品做不到的。 |

### 1.3 战略结论

**AI 是唯一的差异化壁垒。**

- 没有 AI → 简化版雪球 → 无护城河 → 没有用户留存理由
- 有 AI → "每天帮你复盘的智能投资搭子" → 独特价值 → 用户无法在别处获得

**行情功能必须砍掉。**

- 你的战场不在"信息展示"，而在"信息解读"
- 用户不缺数据，缺的是有人帮他看懂数据

**打卡必须从"门"变为"钩子"。**

- 从强制全屏 gate → 首页顶部卡片
- 降低进入门槛，提高自愿性和趣味性

---

## 二、产品重新定位

### 2.1 新定位

> **"赚了吗"——你的 AI 投资复盘搭子**

不是社区，不是行情软件。是一个**每天陪你复盘的 AI + 散户情绪社区**。

### 2.2 目标用户

| 维度 | 描述 |
|------|------|
| 画像 | A 股散户，20-45 岁，日均看盘 1-3 次 |
| 痛点 | 收盘后没人聊、不知道今天做得对不对、明天该怎么操作 |
| 场景 | 下午 3 点收盘后、晚上复盘时打开 App |
| 替代品 | 微信股票群（太吵）、雪球（太重）、券商 App（没社交） |

### 2.3 一句话价值

**"每天收盘后打开赚了吗，30 秒打卡，1 分钟看 AI 复盘，5 分钟刷社区。"**

---

## 三、信息架构重设计

### 3.1 Tab 结构

```
旧：社区 | 行情 | 我的
新：首页 | AI 复盘 | 我的
```

| Tab | 核心功能 | 不可删除的理由 |
|-----|----------|----------------|
| **首页** | 打卡卡片 + AI 一句话摘要 + 社区信息流 | 日活入口，情绪释放 + 社交确认 |
| **AI 复盘** | 每日大盘分析 + 个人持仓复盘 + 追问对话 | **核心壁垒**，竞品没有的功能 |
| **我的** | 打卡日历 + 个人主页 + 设置 | 成长记录，留存抓手 |

### 3.2 首页布局（一屏三段）

```
┌─────────────────────────────┐
│  [打卡卡片]  1/5 屏          │
│  "今天赚了吗？" / 已打卡统计  │
├─────────────────────────────┤
│  [AI 一句话复盘]  1/5 屏     │
│  "大盘震荡收跌，科技板块领涨" │
│  点击展开 → 跳转 AI Tab      │
├─────────────────────────────┤
│  [社区信息流]  3/5 屏        │
│  排序切换（最新/热度）        │
│  帖子卡片列表               │
│  ...                        │
└─────────────────────────────┘
```

**打卡卡片的两种状态：**
- 未打卡：醒目的"赚了/亏了"选择按钮
- 已打卡：收缩为一行统计条（"今天 65% 的人赚了，你呢？赚了 ✓"）

### 3.3 用户旅程

```
打开 App
  → 首页：看到打卡卡片 → 打卡（30 秒）
  → 首页：看到 AI 摘要 → 感兴趣就点进去（1 分钟）
  → 首页：刷社区信息流 → 点赞、评论（5 分钟）
  → AI Tab：深度复盘、追问（可选）
  → 关闭 App
```

---

## 四、AI 复盘模块设计（核心）

### 4.1 三层架构

#### 第一层：每日自动复盘（零操作，所有用户可见）

| 模块 | 内容 | 数据来源 |
|------|------|----------|
| 大盘总结 | 三大指数表现、涨跌家数、成交额 | 定时云函数抓取行情 API |
| 板块分析 | 今日领涨/领跌板块 TOP5 | 东方财富/腾讯板块 API |
| 情绪指标 | "今天 X% 的赚了吗用户赚了" | 社区打卡数据聚合 |
| AI 点评 | 一段话总结 + 明日展望 | 大模型基于以上数据生成 |

**触发方式：** 每个交易日 15:30 定时云函数自动生成，缓存到数据库，客户端直接拉取。

#### 第二层：个人持仓复盘（用户输入持仓后解锁）

| 模块 | 内容 |
|------|------|
| 持仓表现 | 今日各股涨跌、盈亏计算 |
| 个股分析 | 所在板块联动、资金流向、技术面 |
| AI 建议 | 基于持仓给出个性化操作建议 |

**用户输入方式：** 简单的股票代码 + 持仓数量输入（不需要对接券商）。

#### 第三层：追问对话（深度交互）

- 支持自由提问："帮我分析一下贵州茅台"、"我应该止损吗？"
- 上下文感知：AI 知道你的持仓、打卡记录、近期盈亏状态
- 流式输出：逐字显示，体验流畅

### 4.2 技术方案

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  定时云函数   │ ──→ │  行情 API    │     │  大模型 API  │
│  (每日15:30) │     │  (腾讯/东财) │     │  (DeepSeek)  │
└──────┬───────┘     └──────────────┘     └──────┬───────┘
       │                                         │
       │  抓取数据 → 组装 Prompt → 调用大模型 → 存储结果
       │                                         │
       ▼                                         ▼
┌──────────────┐                          ┌──────────────┐
│  CloudBase   │                          │  ai_reports  │
│  数据库      │  ←──────────────────────  │  集合        │
└──────┬───────┘                          └──────────────┘
       │
       │  客户端拉取
       ▼
┌──────────────┐
│  iOS App     │
│  AI Tab      │
└──────────────┘
```

**大模型选择建议：**
- **首选 DeepSeek API**：性价比最高，中文能力强，适合财经场景
- 备选：通义千问、GPT-4o-mini
- Prompt 设计：角色设定为"资深投资分析师"，语气亲和、专业、有观点

### 4.3 数据模型

```json
// ai_reports 集合
{
  "_id": "report_20260207",
  "date": "2026-02-07",
  "type": "daily",
  "marketSummary": "三大指数今日震荡...",
  "sectorAnalysis": "科技板块领涨...",
  "sentimentData": { "yesPercent": 65, "totalCheckIns": 1280 },
  "aiComment": "AI 生成的一段话复盘...",
  "aiOutlook": "明日展望...",
  "createdAt": 1738886400000
}

// ai_conversations 集合
{
  "_id": "conv_xxx",
  "userId": "user_xxx",
  "messages": [
    { "role": "user", "content": "帮我分析贵州茅台" },
    { "role": "assistant", "content": "贵州茅台今日..." }
  ],
  "createdAt": 1738886400000
}

// user_portfolios 集合
{
  "_id": "portfolio_xxx",
  "userId": "user_xxx",
  "stocks": [
    { "code": "600519", "name": "贵州茅台", "shares": 100, "costPrice": 1800 }
  ],
  "updatedAt": 1738886400000
}
```

---

## 五、现有功能评估

### 5.1 保留（已完善，不需要改动）

| 功能 | 文件 | 说明 |
|------|------|------|
| SMS 登录注册 | `LoginView` / `LoginViewModel` / 云函数 | 完善，无需改动 |
| 社区信息流 | `CommunityView` / `CommunityViewModel` | 游标分页、热度排序、骨架屏，已完善 |
| 发帖 | `ComposePostView` / `ComposePostViewModel` | 并发上传、草稿、进度，已完善 |
| 帖子详情 + 评论 | `PostDetailView` / `PostDetailViewModel` | 两级评论、排序、软删除，已完善 |
| 帖子互动 | `PostCard` + ViewModel 方法 | 乐观点赞、原子计数，已完善 |
| 个人中心 | `ProfileView` / `EditProfileView` | 头像、昵称、统计，已完善 |
| 通知 | `NotificationsView` | 列表 + 标记已读，已完善 |
| 设置 / 反馈 | `SettingsView` / `HelpAndFeedbackView` | 基础功能，已完善 |
| 打卡日历 | `CheckInCalendarView` | 月度日历展示，已完善 |

### 5.2 修改（需要调整）

| 功能 | 当前实现 | 改为 |
|------|----------|------|
| 打卡入口 | 全屏 gate（`DailyCheckInView`） | 首页顶部卡片组件 |
| Tab 结构 | 社区 / 行情 / 我的 | 首页 / AI 复盘 / 我的 |
| 首页 | 纯社区列表 | 打卡卡片 + AI 摘要 + 社区列表 |

### 5.3 删除（不需要的功能）

| 功能 | 涉及文件 | 删除理由 |
|------|----------|----------|
| 行情 Tab 全套 | `MarketView` / `MarketViewModel` / `MarketTabSelector` / `MarketRegionTabSelector` / `MarketOverviewCard` / `QuickActionsView` / `TrendingTopicsView` / `SectorGridView` / `SectorListView` / `HotStocksView` / `WatchlistTabView` / `WatchlistRowView` / `StockSearchView` / `StockDetailView` | 做不到比专业行情软件更好，反而拉低产品质感 |
| 行情数据模型 | `WatchlistItem` / `MarketIndex` / `SectorItem` / `SectorType` / `MarketStats` / `MarketTab` / `MarketRegion` / `HotStockType` | 随行情功能一起删除 |
| 行情服务 | `MarketDataService` / `MarketDataCache` | 不再需要 |
| 行情云函数 | `getSectorData` / `getHotStocks` | 不再需要（但行情抓取逻辑可复用于 AI 复盘） |

### 5.4 新增

| 功能 | 说明 |
|------|------|
| AI 复盘 Tab | 全新页面：每日复盘 + 持仓分析 + 追问对话 |
| AI 摘要卡片 | 首页的 AI 一句话复盘组件 |
| 打卡卡片 | 首页内嵌的打卡组件（替代全屏 gate） |
| 每日复盘云函数 | 定时抓取行情 + 调用大模型生成报告 |
| AI 对话云函数 | 处理用户追问、管理对话上下文 |
| 持仓管理 | 用户输入/编辑自己的持仓 |

---

## 六、分期执行计划

### Phase 0：砍减聚焦（预计 1 天）

**目标：** 删除行情模块，修改 Tab 结构，让 App 瘦身聚焦。

| # | 任务 | 涉及文件 | 工时 |
|---|------|----------|------|
| 0.1 | 删除行情 View 目录（13 个文件） | `Zhuanlema/Views/Market/` 整个目录（含 `MarketView.swift` `StockSearchView.swift` `StockDetailView.swift` `SectorListView.swift` `WatchlistTabView.swift` `WatchlistRowView.swift` + `Components/` 下 7 个） | 15 min |
| 0.2 | 删除行情 ViewModel | `Zhuanlema/ViewModels/MarketViewModel.swift` | 5 min |
| 0.3 | 删除行情数据模型（7 个文件） | `Zhuanlema/Models/WatchlistItem.swift` `MarketIndex.swift` `SectorItem.swift` `MarketStats.swift` `MarketTab.swift` `MarketRegion.swift` `HotStockType.swift` | 10 min |
| 0.4 | 删除行情服务（2 个文件） | `Zhuanlema/Services/Market/MarketDataService.swift` `Zhuanlema/Services/Market/MarketDataCache.swift` | 5 min |
| 0.5 | 清理 `CloudBaseDatabaseService` 中行情方法 | `Zhuanlema/Services/CloudBase/CloudBaseDatabaseService.swift` 中的 `getSectorData()` 和 `getHotStocks()` 方法及相关结构体 | 10 min |
| 0.6 | 修改 `MainTabView`：行情 Tab → AI 复盘 Tab（先放占位页） | `Zhuanlema/Views/MainTabView.swift` | 15 min |
| 0.7 | 修改 `AppState`：移除行情相关状态和跳转逻辑 | `Zhuanlema/ZhuanlemaApp.swift` | 10 min |
| 0.8 | 编译验证，修复所有引用错误 | 全局 | 30 min |

### Phase 1：首页重组（预计 2-3 天）

**目标：** 首页从纯社区列表变为"打卡 + AI 摘要 + 社区"三段式。

| # | 任务 | 涉及文件 | 工时 |
|---|------|----------|------|
| 1.1 | 创建 `CheckInCardView`：首页内嵌打卡卡片（未打卡/已打卡两种状态） | 新建 `Views/CheckIn/CheckInCardView.swift` | 3 h |
| 1.2 | 创建 `AISummaryCardView`：AI 一句话摘要卡片（点击跳转 AI Tab） | 新建 `Views/AI/AISummaryCardView.swift` | 2 h |
| 1.3 | 重构 `CommunityView` 为 `HomeView`：整合打卡卡片 + AI 摘要 + 社区信息流 | 重命名/重构 `Views/Community/CommunityView.swift` → `Views/Home/HomeView.swift` | 3 h |
| 1.4 | 修改 `AppState` 打卡逻辑：从全屏 gate 改为首页卡片内打卡 | `ZhuanlemaApp.swift` `AppState` | 2 h |
| 1.5 | 保留 `DailyCheckInView` 作为新用户首次引导（可选） | `DailyCheckInView.swift` | 1 h |
| 1.6 | 创建 `HomeViewModel`：统一管理首页三个模块的状态 | 新建 `ViewModels/HomeViewModel.swift` | 2 h |
| 1.7 | 联调测试 | 全局 | 2 h |

### Phase 2：AI 复盘核心（预计 3-5 天）

**目标：** AI Tab 从占位页变为可用的每日复盘 + 对话功能。

| # | 任务 | 涉及文件 | 工时 |
|---|------|----------|------|
| **后端** | | | |
| 2.1 | 创建 `generateDailyReport` 云函数：定时抓取行情数据 + 打卡统计 + 调用大模型生成复盘 | 新建 `cloudfunctions/generateDailyReport/` | 4 h |
| 2.2 | 创建 `getDailyReport` 云函数：客户端获取每日复盘报告 | 新建 `cloudfunctions/getDailyReport/` | 1 h |
| 2.3 | 创建 `aiChat` 云函数：处理用户追问，管理上下文，调用大模型 | 新建 `cloudfunctions/aiChat/` | 3 h |
| 2.4 | CloudBase 定时触发器配置：每个交易日 15:30 执行 `generateDailyReport` | `cloudbaserc.json` | 30 min |
| 2.5 | 创建数据库集合：`ai_reports` `ai_conversations` | CloudBase 控制台 | 15 min |
| **前端** | | | |
| 2.6 | 创建 `AIReportView`：每日复盘展示页（大盘总结 + 板块 + 情绪 + AI 点评） | 新建 `Views/AI/AIReportView.swift` | 4 h |
| 2.7 | 创建 `AIChatView`：追问对话界面（气泡布局 + 流式输出） | 新建 `Views/AI/AIChatView.swift` | 4 h |
| 2.8 | 创建 `AITabView`：AI Tab 主页面（顶部报告 + 底部对话入口） | 新建 `Views/AI/AITabView.swift` | 2 h |
| 2.9 | 创建 `AIViewModel`：管理报告加载、对话状态、消息发送 | 新建 `ViewModels/AIViewModel.swift` | 3 h |
| 2.10 | 创建 `AIRepository` / `AIService`：封装云函数调用 | 新建 `Repositories/AIRepository.swift` `Services/AIService.swift` | 2 h |
| 2.11 | 创建 `AIReport` / `AIConversation` 数据模型 | 新建 `Models/AIReport.swift` `Models/AIConversation.swift` | 1 h |
| 2.12 | 更新 `AISummaryCardView`：首页摘要卡片接入真实数据 | `Views/AI/AISummaryCardView.swift` | 1 h |
| 2.13 | 联调测试 | 全局 | 3 h |

### Phase 3：个性化增强（后续迭代）

**目标：** 从"通用复盘"进化为"个人专属复盘"。

| # | 任务 | 说明 |
|---|------|------|
| 3.1 | 持仓管理页面 | 用户输入持有的股票代码和数量 |
| 3.2 | 个人持仓复盘 | AI 结合持仓数据做个性化分析 |
| 3.3 | 打卡趋势分析 | AI 结合打卡历史给建议（"连续 5 天亏损，建议减仓"） |
| 3.4 | 社区帖子 AI 摘要 | 热帖自动生成摘要，降低信息过载 |
| 3.5 | AI 选股助手 | 根据用户风格推荐关注标的 |
| 3.6 | 推送通知 | 盘中异动提醒、收盘自动推送复盘 |

---

## 七、关键决策记录

| 决策 | 理由 |
|------|------|
| 砍掉行情 Tab | 一个人做不过东方财富，且用户已有替代品 |
| AI 作为核心 Tab | 唯一差异化壁垒，竞品不具备 |
| 打卡从 gate 改为卡片 | 降低进入门槛，提高自愿性 |
| 选择 DeepSeek 作为首选大模型 | 性价比最高，中文财经能力强 |
| 每日复盘定时生成而非实时 | 降低成本，收盘后一次性生成即可 |
| 保留现有社区功能不动 | 已经足够完善，不需要再投入 |

---

## 八、成功指标

| 指标 | 目标 | 衡量方式 |
|------|------|----------|
| 日活打卡率 | > 60% | 每日打卡用户 / DAU |
| AI 复盘查看率 | > 40% | 每日查看报告用户 / DAU |
| AI 对话使用率 | > 20% | 每日发起对话用户 / DAU |
| 次日留存率 | > 35% | 标准次日留存 |
| 7 日留存率 | > 15% | 标准 7 日留存 |

---

**文档作者**：leacent song
**文档版本**：v2.0
**创建日期**：2026-02-07
**基于**：第一性原理产品分析

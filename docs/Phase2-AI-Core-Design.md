> AI GENERATED: 该文档由 AI 生成或修改。

# Phase 2：AI 复盘核心 — 架构设计文档

> 基于第一性原理重新审视"AI 复盘"功能的本质，结合 CloudBase + DeepSeek 技术验证结果。

---

## 一、第一性原理：从本质出发

### 1.1 回到最基本的问题

马斯克的第一性原理方法论：**剥离所有假设，回到基本事实，从零构建。**

**问题：散户收盘后到底需要什么？**

不要假设他们需要"行情"、"K 线"、"技术分析"。那些是已有工具做的事。回到根本：

```
基本事实 1：散户的最大敌人不是缺少信息，而是缺少情绪觉察力。
基本事实 2：没有人帮散户做"情绪-决策"的因果回溯。
基本事实 3：散户重复犯同样的错误，因为他们没有系统性的复盘框架。
基本事实 4：我们独有的数据资产是"打卡情绪数据"——这是任何行情软件都没有的。
```

### 1.2 推导出核心差异化

| 维度 | 同花顺/东方财富 | 雪球 | **赚了吗** |
|------|----------------|------|-----------|
| 数据 | 海量行情 | 社区 UGC | **情绪数据 + 社区情绪** |
| AI 定位 | 数据分析工具 | 无 | **情绪投资教练** |
| 核心价值 | 看得到 | 听得到（别人说） | **看得清自己** |

**结论：我们的 AI 不应该做"市场分析师"（那是红海），而是做"情绪投资教练"——帮散户看清自己。**

### 1.3 推导出三层产品架构

```
第一性原理推导链：

情绪是最大敌人
  → 需要一面"情绪镜子" → Layer 1：每日情绪脉搏（被动接收）
  
散户不会自我复盘
  → 需要一个"复盘框架" → Layer 2：结构化复盘（引导式）
  
每个人的问题不一样
  → 需要一个"随时问的教练" → Layer 3：追问对话（主动探索）
```

---

## 二、产品设计

### 2.1 Layer 1：每日情绪脉搏（Daily Pulse）

**设计理念：** 零操作，打开就看到。不是冰冷的数据报告，而是一个"懂你"的朋友在说话。

**包含内容：**

| 模块 | 内容 | 数据来源 | 展示形式 |
|------|------|----------|----------|
| 社区情绪 | "今天 65% 的赚友赚了" | check_ins 聚合 | 环形进度条 + 一句话 |
| 大盘心跳 | 三大指数 + 成交额 + 涨跌家数 | 行情 API 抓取 | 简洁三列数字 |
| AI 一句话 | 今日市场总结（口语化、有观点） | DeepSeek 生成 | 加粗文本 |
| AI 洞察 | 结合情绪与行情的关联分析 | DeepSeek 生成 | 卡片气泡 |

**关键设计原则：**
- **不做同花顺的缩小版**——不展示 K 线，不做技术分析图
- **口语化**——"今天大盘又震荡了，但创业板小哥们很争气" 而不是 "沪指跌 0.3%"
- **有观点**——"没必要恐慌，缩量回调是好事" 而不是中性的数据罗列
- **情绪优先**——社区情绪放第一位，行情数据是配角

**触发方式：** 每个交易日 15:30 定时云函数自动生成，缓存到 `ai_reports` 集合。

### 2.2 Layer 2：情绪复盘（Emotional Review）

**设计理念：** 用数据帮用户看清自己的情绪模式。这是竞品做不到的功能。

**包含内容：**

| 模块 | 内容 | 触发条件 |
|------|------|----------|
| 本周情绪曲线 | 连续 5 天的赚/亏打卡趋势 | 打卡 ≥ 3 天 |
| 情绪-大盘对比 | 你的情绪 vs 大盘走势的对比图 | 打卡 ≥ 5 天 |
| AI 行为洞察 | "你连续 3 天觉得亏了，但大盘其实涨了——可能是持仓问题，不是大势问题" | 数据足够时 |
| 本周小结 | 一段话总结你的投资情绪状态 | 每周五生成 |

**关键设计原则：**
- **渐进解锁**——打卡越多，AI 越懂你，展示越丰富
- **不做诊断，做镜子**——"你的情绪跟大盘反着走" 而不是 "你应该买/卖"
- **引导正反馈**——"你已经连续打卡 7 天了，你的自我觉察力在提升"

### 2.3 Layer 3：追问对话（AI Chat）

**设计理念：** 一个知道你情绪历史、打卡记录的投资搭子，随时可以聊。

**对话上下文包含：**

```
系统 Prompt = 角色设定 + 用户画像 + 今日市场数据

用户画像 = {
  近期打卡记录（最近 7 天的赚/亏/未打卡）,
  打卡连续天数,
  情绪趋势（连续亏 or 连续赚 or 波动）,
  持仓信息（如果用户配置了）
}
```

**对话场景示例：**
- "今天该不该割肉？" → AI 结合你的情绪历史 + 市场数据给建议
- "帮我分析一下 XX 股票" → 结合公开信息给分析
- "我最近心态不好怎么办" → 结合打卡数据给情绪管理建议
- "帮我复盘这周的操作" → 结合一周打卡数据生成复盘报告

**关键设计原则：**
- **不做荐股机器人**——法规风险，且不是我们的价值
- **情绪感知优先**——先安抚情绪，再给分析
- **流式输出**——逐字显示，提升交互体验
- **对话历史持久化**——用户可以回看之前的对话

---

## 三、技术调研结论

### 3.1 DeepSeek on CloudBase — 验证通过

**测试结果（2026-03-30 实测）：**

| 指标 | 结果 |
|------|------|
| 模型 | `deepseek-v3.2`（CloudBase 内置） |
| Provider | `deepseek` |
| SDK | `@cloudbase/node-sdk` ≥ 3.16.0 |
| 响应时间 | 3.3 秒（单句摘要） |
| Token 消耗 | 48 prompt + 38 completion = 86 total |
| 内存占用 | ~27 MB |
| 额外配置 | **无需 API Key**，CloudBase 内置集成 |
| 质量 | 中文财经场景表现优秀，语言自然，观点鲜明 |

**核心代码验证：**

```javascript
const tcb = require('@cloudbase/node-sdk');
const app = tcb.init({ env: 'prod-1-3g3ukjzod3d5e3a1' });

const ai = app.ai();
const model = ai.createModel('deepseek');

const result = await model.generateText({
  model: 'deepseek-v3.2',
  messages: [
    { role: 'system', content: '你是一位专业的A股投资分析师' },
    { role: 'user', content: '用一句话总结今日A股走势...' }
  ]
});

// result.text → "今日A股呈现沪弱深强格局，上证指数微跌0.3%而创业板指涨0.5%..."
// result.usage → { prompt_tokens: 48, completion_tokens: 38, total_tokens: 86 }
```

**结论：DeepSeek v3.2 通过 CloudBase 原生 SDK 即可调用，无需任何外部 API Key，是最优选择。**

### 3.2 可用模型对比

| Provider | 模型 | 推荐场景 | 备注 |
|----------|------|----------|------|
| `deepseek` | `deepseek-v3.2` | **日常复盘、对话**（首选） | 性价比最高，中文强 |
| `deepseek` | `deepseek-r1-0528` | 深度推理（复杂分析） | 速度较慢，token 消耗大 |
| `hunyuan-exp` | `hunyuan-2.0-instruct-20251111` | 备选 | 腾讯自研，兜底用 |

**策略：日常复盘和对话统一使用 `deepseek-v3.2`；仅在需要深度推理时考虑 `deepseek-r1-0528`。**

---

## 四、技术架构设计

### 4.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    iOS App (SwiftUI)                     │
├──────────┬──────────────────────┬───────────────────────┤
│ HomeView │     AITabView        │     ProfileView       │
│ (摘要卡片)│ ┌──────────────────┐ │                       │
│          │ │ AIReportView     │ │                       │
│          │ │ (每日情绪脉搏)    │ │                       │
│          │ ├──────────────────┤ │                       │
│          │ │ AIChatView       │ │                       │
│          │ │ (追问对话)        │ │                       │
│          │ └──────────────────┘ │                       │
├──────────┴──────────────────────┴───────────────────────┤
│                CloudBase Service Layer                   │
│     CloudBaseDatabaseService / CloudBaseHTTPClient       │
└────────────┬───────────────────────────┬────────────────┘
             │ callFunction              │ callFunction
             ▼                           ▼
┌────────────────────────┐  ┌────────────────────────────┐
│ generateDailyReport    │  │        aiChat              │
│ (定时云函数 15:30)      │  │   (用户触发云函数)          │
│                        │  │                            │
│ 1. 抓取行情数据         │  │ 1. 加载用户上下文           │
│ 2. 聚合打卡统计         │  │    (打卡、情绪、持仓)       │
│ 3. 组装 Prompt         │  │ 2. 组装 System Prompt      │
│ 4. 调 DeepSeek 生成    │  │ 3. 调 DeepSeek 生成        │
│ 5. 存入 ai_reports     │  │ 4. 存入 ai_conversations   │
└────────────┬───────────┘  └──────────┬─────────────────┘
             │                         │
             ▼                         ▼
┌──────────────────────────────────────────────────────────┐
│                  CloudBase Database                       │
│  ┌──────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │ai_reports│  │ai_conversations│  │  check_ins       │ │
│  └──────────┘  └────────────────┘  └──────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 4.2 数据模型设计

#### ai_reports 集合（每日复盘报告）

```json
{
  "_id": "report_20260330",
  "date": "2026-03-30",
  "type": "daily",

  "marketData": {
    "shIndex": { "close": 3250.12, "change": -0.32, "volume": "1.2万亿" },
    "szIndex": { "close": 10856.78, "change": 0.15 },
    "cyIndex": { "close": 2180.45, "change": 0.52 },
    "advancers": 2856,
    "decliners": 2134,
    "limitUp": 45,
    "limitDown": 12
  },

  "sentimentData": {
    "totalCheckIns": 1280,
    "yesCount": 832,
    "noCount": 448,
    "yesPercent": 65
  },

  "aiContent": {
    "oneLiner": "沪弱深强，创业板小哥们挺争气",
    "summary": "今天大盘震荡收跌，但创业板逆势上涨...(200字左右)",
    "insight": "65%的赚友今天赚了，跟创业板走势吻合。如果你今天亏了，大概率是蓝筹拖累的，别焦虑。",
    "outlook": "缩量震荡格局短期难改，但情绪面不差，明天看能不能站上3260。"
  },

  "createdAt": 1743321000000,
  "model": "deepseek-v3.2"
}
```

#### ai_conversations 集合（对话历史）

```json
{
  "_id": "conv_xxx",
  "userId": "user_xxx",
  "title": "关于今天的操作",
  "messages": [
    { "role": "user", "content": "今天该不该割肉？", "timestamp": 1743321000000 },
    { "role": "assistant", "content": "我看了你最近7天的打卡记录...", "timestamp": 1743321003000 }
  ],
  "context": {
    "recentCheckIns": ["yes", "no", "no", "yes", "no", "no", "no"],
    "emotionTrend": "连续亏损",
    "streakDays": 12
  },
  "createdAt": 1743321000000,
  "updatedAt": 1743321003000
}
```

### 4.3 云函数设计

#### 4.3.1 generateDailyReport（定时生成每日复盘）

```
触发方式: 定时触发器，每个交易日 15:30
超时设置: 120 秒
```

**执行流程：**

```
1. 判断今天是否为交易日（排除周末、节假日）
2. 抓取行情数据（调用公开行情 API）
3. 聚合今日打卡统计（查询 check_ins 集合）
4. 组装 Prompt：
   - System: 你是"赚了吗"App 的 AI 投资教练，语言口语化、有观点、不废话
   - User: [行情数据] + [社区情绪数据] + 请生成每日复盘
5. 调用 DeepSeek v3.2 generateText
6. 解析结果，存入 ai_reports 集合
7. 返回执行状态
```

**Prompt 设计（关键）：**

```
你是"赚了吗"App 的 AI 投资教练"赚哥"。你的特点：
- 说人话，不说废话，像朋友聊天一样
- 有自己的观点，不做两头讨好的分析
- 关注散户的情绪，而不只是数据
- 适当幽默，但不轻浮

今日市场数据：
- 上证指数：{shClose}，涨跌幅 {shChange}%
- 深证成指：{szClose}，涨跌幅 {szChange}%
- 创业板指：{cyClose}，涨跌幅 {cyChange}%
- 上涨 {advancers} 家，下跌 {decliners} 家
- 成交额：{volume}

社区情绪数据：
- 今天 {totalCheckIns} 人打卡，{yesPercent}% 赚了

请生成以下内容（JSON 格式）：
1. oneLiner: 一句话总结（15字以内，像朋友圈标题）
2. summary: 今日复盘（150-200字，口语化，有观点）
3. insight: 情绪洞察（结合社区情绪数据和行情，50-80字）
4. outlook: 明日展望（50-80字，给方向感但不荐股）
```

#### 4.3.2 getDailyReport（获取每日复盘）

```
触发方式: 客户端调用
超时设置: 20 秒
```

**逻辑简单：** 从 `ai_reports` 查询指定日期的报告。如果没有，返回最近一个交易日的报告。

#### 4.3.3 aiChat（AI 对话）

```
触发方式: 客户端调用
超时设置: 120 秒
```

**执行流程：**

```
1. 接收参数: { userId, conversationId?, message }
2. 加载用户上下文:
   a. 查询最近 7 天打卡记录
   b. 计算情绪趋势（连赚/连亏/波动）
   c. 查询连续打卡天数
   d. 加载今日复盘报告
   e. 加载历史对话（如果 conversationId 存在）
3. 组装 System Prompt（含用户画像）
4. 调用 DeepSeek v3.2 generateText
5. 存储对话到 ai_conversations
6. 返回 AI 回复
```

**System Prompt 设计：**

```
你是"赚了吗"App 的 AI 投资教练"赚哥"。

关于你：
- 你是一个懂投资、更懂散户心理的朋友
- 你说人话，有观点，不打官腔
- 你的第一反应是关注用户的情绪状态，其次才是给分析
- 你绝对不荐股，不给具体买卖建议，但会帮用户理清思路
- 当用户情绪激动时，先共情再分析

关于这位用户：
- 最近 7 天打卡: {recentCheckIns}（yes=赚了, no=亏了）
- 情绪趋势: {emotionTrend}
- 已连续打卡 {streakDays} 天
- 今日市场: {todayMarketSummary}

请基于以上信息回复用户的问题。如果用户问与投资无关的问题，
友善地引导回投资复盘话题。
```

### 4.4 前端架构设计（iOS / SwiftUI）

#### 文件结构

```
Zhuanlema/
├── Models/
│   ├── AIReport.swift              # 每日复盘数据模型
│   └── AIConversation.swift        # 对话数据模型
├── ViewModels/
│   └── AIViewModel.swift           # AI 模块状态管理
├── Views/AI/
│   ├── AITabView.swift             # AI Tab 主页面
│   ├── AIReportView.swift          # 每日情绪脉搏
│   ├── AIChatView.swift            # 追问对话
│   ├── AISummaryCardView.swift     # 首页摘要卡片（已有）
│   └── Components/
│       ├── SentimentRingView.swift  # 情绪环形图
│       ├── MarketPulseView.swift    # 大盘心跳卡片
│       └── ChatBubbleView.swift     # 对话气泡
└── Services/
    └── AIService.swift              # AI 云函数调用封装
```

#### 核心 ViewModel

```swift
@MainActor
class AIViewModel: ObservableObject {
    // 每日报告
    @Published var dailyReport: AIReport?
    @Published var isLoadingReport = false

    // 对话
    @Published var conversations: [AIConversation] = []
    @Published var currentMessages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var inputText = ""

    // 加载今日报告
    func loadDailyReport()

    // 发送消息
    func sendMessage(_ text: String)

    // 创建新对话
    func startNewConversation()
}
```

#### AI Tab 页面结构

```
AITabView
├── NavigationStack
│   ├── ScrollView
│   │   ├── AIReportView (每日情绪脉搏)
│   │   │   ├── SentimentRingView (社区情绪环形图)
│   │   │   ├── MarketPulseView (大盘三列数字)
│   │   │   ├── AI 一句话总结 (加粗文本)
│   │   │   ├── AI 详细复盘 (可展开的卡片)
│   │   │   └── AI 情绪洞察 (渐变底色卡片)
│   │   │
│   │   └── "向赚哥提问" (入口按钮)
│   │
│   └── NavigationLink → AIChatView
│       ├── 历史消息列表 (气泡布局)
│       ├── AI 正在输入指示器
│       └── 输入框 + 发送按钮
```

### 4.5 行情数据获取方案

由于已删除行情模块，AI 复盘需要一个轻量的行情数据来源。

**方案：云函数内调用免费行情 API**

```javascript
// 腾讯财经免费 API（无需 Key）
const MARKET_API = {
  shIndex: 'https://qt.gtimg.cn/q=sh000001',  // 上证指数
  szIndex: 'https://qt.gtimg.cn/q=sz399001',  // 深证成指
  cyIndex: 'https://qt.gtimg.cn/q=sz399006',  // 创业板指
};
```

**这与之前删除的行情模块的区别：**
- 之前：前端直接展示行情（做了完整的 K 线、板块、热股） → 做不好
- 现在：后端抓取行情数据仅作为 AI Prompt 的输入 → 数据是配料，AI 解读才是菜

---

## 五、实施计划（修订版）

### Phase 2.1：后端基础（2 天）

| # | 任务 | 工时 |
|---|------|------|
| 2.1.1 | 创建 `ai_reports` / `ai_conversations` 集合 | 15 min |
| 2.1.2 | 开发 `generateDailyReport` 云函数 | 4 h |
| 2.1.3 | 开发 `getDailyReport` 云函数 | 1 h |
| 2.1.4 | 开发 `aiChat` 云函数 | 3 h |
| 2.1.5 | 配置定时触发器（每交易日 15:30） | 30 min |
| 2.1.6 | 手动触发一次，验证完整链路 | 1 h |

### Phase 2.2：前端 AI Tab（2-3 天）

| # | 任务 | 工时 |
|---|------|------|
| 2.2.1 | 创建数据模型 `AIReport.swift` / `AIConversation.swift` | 1 h |
| 2.2.2 | 创建 `AIService.swift` 封装云函数调用 | 1 h |
| 2.2.3 | 创建 `AIViewModel.swift` | 2 h |
| 2.2.4 | 创建 `AIReportView.swift`（情绪脉搏页） | 4 h |
| 2.2.5 | 创建 `AIChatView.swift`（对话页） | 4 h |
| 2.2.6 | 创建 `AITabView.swift`（替换占位页） | 2 h |
| 2.2.7 | 更新 `AISummaryCardView` 接入真实数据 | 1 h |
| 2.2.8 | 联调测试 | 2 h |

### Phase 2.3：打磨体验（1 天）

| # | 任务 | 工时 |
|---|------|------|
| 2.3.1 | Prompt 调优（多轮测试 AI 输出质量） | 2 h |
| 2.3.2 | 加载态、空态、错误态设计 | 2 h |
| 2.3.3 | 对话体验优化（键盘处理、自动滚动等） | 2 h |

---

## 六、风险与决策

| 风险 | 缓解措施 |
|------|----------|
| DeepSeek 响应慢 | 每日报告预生成缓存；对话设 120s 超时 |
| 行情 API 不稳定 | 腾讯财经 API 作为主要源；失败时报告标注"行情数据暂不可用" |
| AI 输出质量不稳定 | 严格 Prompt 工程 + JSON 格式约束 + 输出校验 |
| 法规风险（荐股） | Prompt 明确禁止荐股；输出后检查是否含具体买卖建议 |
| 对话 token 成本 | 限制上下文窗口（最近 10 轮）；每日对话次数限制（MVP 阶段 20 次） |

---

## 七、关键指标

| 指标 | 目标 | 衡量 |
|------|------|------|
| AI 报告生成成功率 | > 99% | 云函数日志 |
| AI 报告生成时间 | < 30 秒 | 云函数 Duration |
| 对话响应时间 | < 5 秒 | 云函数 Duration |
| 单次对话 token 成本 | < 500 tokens | usage 统计 |
| 每日报告查看率 | > 40% DAU | 客户端埋点 |
| 对话功能使用率 | > 20% DAU | ai_conversations 计数 |

---

**文档版本**: v1.0
**作者**: AI 架构设计
**日期**: 2026-03-30
**依赖**: MVP设计.md v2.0、CloudBase + DeepSeek 技术验证

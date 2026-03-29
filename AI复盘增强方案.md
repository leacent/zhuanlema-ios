# AI 复盘增强方案 — 数据金字塔落地

> **核心洞察**：AI 输出的价值 = 独有数据 x 分析深度 x 个性化程度。当前输入太薄（3 个指数 + 1 个百分比），需要将已有的社区帖子和情绪历史充分喂给 AI，构建只有"赚了吗"能提供的独有洞察。

---

## 一、问题诊断

### 1.1 当前 AI 输入数据

| 数据 | 来源 | 丰富度 |
|------|------|--------|
| 三大指数收盘价/涨跌幅 | 腾讯财经 API | 极薄，3 个数字 |
| 今日打卡比例 | check_ins 集合 | 极薄，1 个百分比 |

**总计 4 个数字。** 任何 AI 模型基于这 4 个数字生成的内容，本质上和 ChatGPT 的回答没有区别。

### 1.2 已拥有但未使用的数据

| 数据 | 所在集合 | 价值 |
|------|----------|------|
| 社区帖子内容 | `user_posts` | 真实的用户情绪、讨论话题、操作记录 |
| 打卡历史趋势 | `check_ins` | 情绪的时间维度（连续下滑/上升） |
| 用户个人发帖 | `user_posts` (按 userId 过滤) | 个性化对话上下文 |

### 1.3 核心结论

**不需要做新功能，只需要把已有数据更充分地喂给 AI。** 这是成本最低、价值最高的改进方向。

---

## 二、数据金字塔模型

```
                    ┌─────────────┐
                    │   个人层     │  用户打卡轨迹 + 发帖记录
                    │ (对话专用)   │
                ┌───┴─────────────┴───┐
                │       社区层         │  帖子热词 + 讨论情绪 + 今日话题
                │   (独有数据壁垒)      │
            ┌───┴─────────────────────┴───┐
            │           市场层             │  三大指数 + 板块涨跌
            │      (所有人都有的数据)       │
            └─────────────────────────────┘
```

- **市场层**：已实现（腾讯 API 抓取）
- **社区层**：数据已有，Prompt 未接入 ← **本次重点**
- **个人层**：打卡历史已接入对话上下文，发帖记录未接入 ← **本次重点**

---

## 三、本次实施任务清单

### P0：`generateDailyReport` 增加社区帖子分析（预计 2h）

**目标：** 让每日报告从"看数字说话"变为"看社区说话"。

**改动文件：** `cloudfunctions/generateDailyReport/index.js`

**具体改动：**

1. 新增 `fetchTodayPosts(dateStr)` 函数
   - 从 `user_posts` 集合拉取今日发布的帖子（最多 50 条）
   - 提取帖子内容和标签
   - 组装为文本摘要

2. 修改 `buildPrompt(market, sentiment, posts)` 函数
   - 新增"社区讨论热点"段落：
     - 今日发帖数量
     - 高频标签 TOP5
     - 随机抽取 5-8 条有代表性的帖子原文（截断到 100 字）
   - Prompt 示例增加段：
     ```
     社区讨论热点（今日 45 条帖子）：
     - 高频话题标签：AI概念、科技股、新能源、白酒、半导体
     - 代表性发言：
       1. "AI板块今天又涨了，继续拿！"
       2. "白酒扛不住了，准备割肉..."
       3. "今天追高被套了，心态崩了"
       4. "大盘震荡，轻仓观望"
       5. "新能源见底了吧，准备抄底"
     ```

3. AI 输出格式新增 `communityInsight` 字段
   - JSON 输出从 4 个字段变为 5 个
   - 新增：`"communityInsight": "社区在聊什么的洞察（50-80字）"`

---

### P0：`generateDailyReport` 增加情绪趋势（预计 1h）

**目标：** 让 AI 有"纵深感"，不只看今天。

**改动文件：** `cloudfunctions/generateDailyReport/index.js`

**具体改动：**

1. 新增 `fetchSentimentTrend(todayStr, days = 7)` 函数
   - 查询最近 7 天的打卡数据
   - 计算每天的 yesPercent
   - 返回趋势数组，如：`[72, 68, 65, 65, 70, 58, 62]`

2. 修改 `buildPrompt` 增加趋势段落：
   ```
   情绪趋势（近 7 天赚钱比例）：
   72% → 68% → 65% → 65% → 70% → 58% → 62%（今日）
   趋势：近 3 天持续走低
   ```

---

### P0：新增 `sentiment_history` 每日存档（预计 1h）

**目标：** 为未来的"历史规律挖掘"打基础。

**改动文件：** `cloudfunctions/generateDailyReport/index.js`

**具体改动：**

在 `generateDailyReport` 主函数末尾，生成报告后同时写入一条 `sentiment_history` 记录：

```json
{
  "_id": "sentiment_20260207",
  "date": "2026-02-07",
  "yesPercent": 65,
  "totalCheckIns": 1280,
  "shChange": -0.32,
  "szChange": 0.15,
  "cyChange": 0.52,
  "postCount": 45,
  "hotTopics": ["AI概念", "科技股", "新能源"],
  "createdAt": 1738886400000
}
```

**新增集合：** `sentiment_history`（需在 CloudBase 控制台创建）

---

### P1：`aiChat` 上下文增加用户发帖记录（预计 1h）

**目标：** AI 对话时"认识"这个用户，而不只知道他打了几天卡。

**改动文件：** `cloudfunctions/aiChat/index.js`

**具体改动：**

修改 `loadUserContext(userId)` 函数，新增：

1. 查询用户最近 5 条帖子内容（从 `user_posts` 按 `userId` + `createdAt desc`）
2. 截断每条帖子到 80 字
3. 加入 System Prompt：
   ```
   用户最近发帖：
   1. [2/6] "新能源怎么跌这么多，要不要割肉"
   2. [2/5] "AI板块继续看好"
   3. [2/4] "今天小赚，心情不错"
   ```

**效果对比：**

| 用户提问 | 当前回答 | 增强后回答 |
|----------|----------|------------|
| "我最近心态不太好" | "保持良好心态很重要，建议轻仓..." | "你连续 3 天打卡亏了，我看你之前发帖说新能源跌太多——确实不好做。但社区 72% 的人今天也亏了，不是你一个人的问题。" |

---

### P1：客户端 `AIReport` 模型适配（预计 30min）

**目标：** 前端展示新增的 `communityInsight` 字段。

**改动文件：**
- `Zhuanlema/Models/AIReport.swift` — `AIContent` 新增 `communityInsight` 字段
- `Zhuanlema/Views/AI/AIReportView.swift` — 新增社区洞察卡片展示

**具体改动：**

`AIContent` 结构体新增：
```swift
struct AIContent: Codable {
    let oneLiner: String?
    let summary: String?
    let insight: String?
    let outlook: String?
    let communityInsight: String?  // 新增
}
```

`AIReportView` 在 `insightCard` 后面新增一个"社区在聊什么"卡片。

---

## 四、改动汇总

| 文件 | 改动类型 | 说明 |
|------|----------|------|
| `cloudfunctions/generateDailyReport/index.js` | 修改 | 增加社区帖子分析、情绪趋势、sentiment_history 存档 |
| `cloudfunctions/aiChat/index.js` | 修改 | 上下文增加用户近期发帖 |
| `Zhuanlema/Models/AIReport.swift` | 修改 | AIContent 新增 communityInsight 字段 |
| `Zhuanlema/Views/AI/AIReportView.swift` | 修改 | 新增社区洞察卡片 |

**新增集合：** `sentiment_history`

**总工时预估：** 5-6 小时

---

## 五、预期效果

### 改进前（当前）

> "大盘震荡收跌，创业板小幅上涨。65% 的赚友今天赚了。明天关注 3260 点支撑。"

### 改进后

> "创业板的涨全靠 AI 概念在撑，社区今天最热的话题就是 AI 和科技股。但注意，你们的赚钱比例已经从 3 天前的 72% 滑到今天的 62%——虽然指数看着还行，但散户的体感在变差。这种'指数涨、散户亏'的结构性分化要警惕，别追高。"

**差距：从"说了等于没说"到"只有这个 App 能说出来"。**

---

## 六、后续迭代（本次不做）

| 任务 | 说明 | 依赖 |
|------|------|------|
| 历史情绪-大盘相关性分析 | 基于 sentiment_history 积累 30 天数据后开始 | sentiment_history 集合 |
| 帖子 NLP 情感分析 | 用 AI 给帖子打情感标签（正面/负面/中性） | 社区帖子量达到一定规模 |
| 个人持仓输入 + 复盘 | 用户手动输入持仓，AI 做个性化分析 | 新增 user_portfolios 集合 + UI |
| 流式输出对话 | AI 回复逐字显示 | CloudBase 支持 SSE 或 WebSocket |

---

**文档版本**：v1.0
**创建日期**：2026-02-07
**基于**：MVP设计.md v2.0 + 第一性原理分析

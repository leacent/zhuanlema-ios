---
name: no-fallback-single-source
description: 禁止为同一语义写多 key/多源兜底代码，采用单一数据源，让错误及时暴露、便于排查。在写云函数、API 解析、前端取数时使用。
---

# 禁止多 key 兜底、错误及时暴露

本技能要求：**不为同一字段写多种键名或多种来源的兜底逻辑**，约定单一数据源，一旦数据不对就立刻报错或返回明确缺失，便于定位和修复。

## 原则

1. **单一键名**：接口/数据库约定用哪个 key，就只读哪个 key。不写 `data.a || data.b || data.c` 或 `raw.avatar ?? raw.avatarUrl ?? raw.avatar_url` 之类多 key 兜底。
2. **单一数据源**：请求体从哪来（如 `event.body`）就只从那里解析一次，不在 `event.xxx` 与 `event.body.xxx` 之间来回兜底。
3. **错误及时出现**：缺少字段或类型不对时应尽快失败（返回错误、抛错或返回空），不用静默兜底把问题延后。

## 反例（不要写）

```javascript
// 多 key 兜底：同一语义用了多个键名，问题会延后
const avatar = data.avatar || data.avatarUrl || data.avatar_url || "";
const phone = data.phone_number ?? data.phoneNumber ?? null;
const t = createdAtToSeconds(data.createdAt) ?? createdAtToSeconds(data.created_at) ?? fallback;

// 多源兜底：混用 event 顶层和 event.body，契约不清晰
const x = event.x ?? event.body?.x;
let base64 = event.imageBase64 || (event.body && event.body.imageBase64) || null;
```

## 正例（推荐）

```javascript
// 约定：avatar 只从 data.avatar 取；没有就是空，不猜别的 key
let avatarVal = typeof data.avatar === "string" ? data.avatar.trim() : "";

// 约定：phone 只从 data.phone_number 取
const phone_number = data.phone_number ?? null;

// 约定：时间只从 data.createdAt 取
const created_at = createdAtToSeconds(data.createdAt) ?? Date.now() / 1000;

// 约定：请求体只从 event.body 来，解析一次得到 body，后面只用 body.xxx
const body = parseBody(event);  // 只负责 string/object 归一
const userId = body.userId;
const imageBase64 = body.imageBase64;
```

## 适用场景

- 云函数：从 `event`/`event.body` 或数据库文档里读字段时，每个语义只用一个 key、一个来源。
- 前端/客户端：从接口或模型取数时，只用约定好的字段名，不写 `a ?? b ?? c` 的多 key 兜底。
- 网关/适配层：若 body 可能为字符串或对象，可**只做一次**“解析成对象”的归一，后续只从该对象取值，不再混用 event 顶层的同名 key。

## 与“容错”的区别

- **允许**：对“是否有值”“类型是否合法”做校验（如 `typeof x === "string"`、非空 trim、范围检查），不合法就报错或返回空。
- **禁止**：对**同一语义**用多个键名或多个来源去试（如 `url || data.url || data.avatar`），导致真正传错 key 或写错结构时问题被掩埋。

遵循本技能可以让契约清晰、问题及早暴露、调试和修改更简单。

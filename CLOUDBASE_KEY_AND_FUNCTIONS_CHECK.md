# CloudBase Key 与云函数检查报告

由 CloudBase MCP 工具检查后生成，便于核对编辑资料等能力是否正常。

## 1. 环境与云函数概览（MCP getFunctionList / envQuery）

- **环境 ID**: `prod-1-3g3ukjzod3d5e3a1`
- **环境状态**: NORMAL
- **云函数总数**: 16（均为 Nodejs18.15、Event 类型、Active）

### 编辑资料相关云函数（已用 MCP 部署为当前仓库最新代码）

| 函数名         | 状态   | 最后更新（本次 MCP 部署前） | 说明 |
|----------------|--------|-----------------------------|------|
| getProfile     | Active | 2026-01-25 13:44:38         | 获取当前用户资料，支持 access_token 在 body |
| updateProfile  | Active | 2026-01-25 13:44:13         | 更新昵称/头像，已修复 docRef.set 不传 _id |
| uploadAvatar   | Active | 2026-01-25 12:12:56         | 上传头像，兼容 event 顶层 / event.body |

本次已通过 MCP `updateFunctionCode` 将上述三个函数**按当前本地代码重新部署**，确保线上版本与仓库一致。

### 其他已部署云函数（部分）

- getHotStocks, getSectorData, getUserStats, getNotifications, markNotificationRead
- submitFeedback, createCheckIn, getTodayCheckInStats, createPost, getPosts
- sendSMSCode, verifyLoginCode, getStockList

---

## 2. Key（Publishable Key）检查说明

- **代码中**: `CloudBaseConfig.swift` 里 `_publishableKey` 已配置为一段 JWT（非占位符 `REPLACE_WITH_PUBLISHABLE_KEY`），格式符合 Publishable Key 的 JWT 形式。
- **MCP 限制**: CloudBase MCP 工具**没有**提供“查询 ApiKey 列表 / 校验 Key 是否有效”的接口，因此无法通过工具自动校验 Key 是否被禁用、过期或权限不足。

### 建议你在控制台手动核对

1. **打开 ApiKey 管理**
   - [CloudBase 控制台 - ApiKey 管理](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/env/apikey)

2. **确认当前使用的 Key**
   - 若 App 内使用的是 **Publishable Key（客户端）**：在控制台查看该 Key 是否存在、未被删除；Publishable Key 长期有效，一般不显示“过期”。
   - 若使用的是**服务端 API Key**：确认未过期，且未在控制台被禁用。

3. **确认云函数调用权限**
   - 在**设置 / 策略**（或环境配置中与 HTTP API / 云函数调用相关的权限）中，确认该 Key 允许调用：
     - `getProfile`
     - `updateProfile`
     - `uploadAvatar`  
   - 若策略按“云函数名”或“资源”配置，需包含上述三个名称。

4. **用请求验证（可选）**
   - 在 App 内进入「编辑资料」保存一次，看是否仍报 403 / 权限不足。
   - 或在 Postman 等工具里用同一 Publishable Key 调用上述云函数，确认返回是否正常。

---

## 3. 云函数版本与一致性

- **本地与线上已对齐**: 已用 MCP 对 `getProfile`、`updateProfile`、`uploadAvatar` 执行 `updateFunctionCode`，函数根目录为当前仓库下的 `cloudfunctions`，因此**当前线上代码与本地一致**。
- **重要改动已包含**:
  - **updateProfile**: 新用户时 `docRef.set()` 不再写入 `_id`，避免“不能更新_id的值”错误；仍只更新 nickname、avatar、时间戳。
  - **getProfile / updateProfile / uploadAvatar**: 均支持从 `event` 顶层或 `event.body`（对象/字符串）读取参数，适配不同网关注入方式。

---

## 4. 若编辑资料仍失败，可依次排查

1. **Key**: 控制台确认 Publishable Key 存在且策略允许调用 getProfile / updateProfile / uploadAvatar。
2. **登录态**: 确认请求 body 中带有有效的 `access_token`（用户登录后获取的 JWT）。
3. **网络/错误信息**: 看 Xcode 控制台或 App 内提示是否为 403、401 或“未登录”，再对照上文 Key 与策略检查。

---

*报告生成后，云函数已通过 CloudBase MCP 更新至当前仓库版本；Key 需在控制台人工核对。*

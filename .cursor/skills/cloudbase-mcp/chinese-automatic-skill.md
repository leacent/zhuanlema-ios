---
name: cloudbase-mcp-auto-chinese
description: 当讨论 CloudBase 数据库查询、云函数部署与调试、打卡记录检索、用户数据验证或后端问题排查时，自动调用 CloudBase MCP 工具。适用于部署/更新云函数、处理 check_ins、users、posts 等集合，或当用户提及「部署云函数」「数据库查询」「云函数」「打卡记录」「用户信息」「后端调试」等场景。
---
# CloudBase MCP 自动使用技能（中文项目）

## 触发条件

当用户请求符合以下任一模式时，**立即**调用 CloudBase MCP 工具：

### 数据库相关

- ✅ “查询今天的打卡记录”
- ✅ “看看用户的打卡历史”
- ✅ “检查用户信息”
- ✅ “数据库里有没有这个用户”
- ✅ “查一下 check_ins 集合”
- ✅ “列出所有帖子”

### 云函数相关

- ✅ “测试 getCheckInHistory 函数”
- ✅ “看看 updateProfile 的日志”
- ✅ “云函数 createCheckIn 运行了吗”
- ✅ “调试 getTodayCheckInStats 报错”

### 云函数部署相关

- ✅ “部署 getCheckInHistory”
- ✅ “把云函数部署一下”
- ✅ “更新 updateProfile 的代码”
- ✅ “getCheckInHistory 未找到，帮忙部署”

### 数据验证相关

- ✅ “验证上传头像是否成功”
- ✅ “确认用户昵称已更新”
- ✅ “检查打卡记录是否正确”

### 问题排查相关

- ✅ “为什么 getCheckInHistory 返回空”
- ✅ “updateProfile 报错了，怎么查”
- ✅ “用户没有打卡记录，数据库里有没有”

## 直接执行的操作（无需询问）

### 1. 查询打卡记录

**用户**：”查询用户 user123 2025年1月的打卡记录“

```bash
CallMcpTool: user-cloudbase / invokeFunction
{
  "name": "getCheckInHistory",
  "params": { "userId": "user123", "year": 2025, "month": 1 }
}
```

### 2. 检查云函数日志

**用户**：”getCheckInHistory 云函数最近报什么错“

```bash
CallMcpTool: user-cloudbase / getFunctionLogs
{
  "functionName": "getCheckInHistory",
  "limit": 20
}
```

### 3. 查询数据库内容

**用户**：”今天有没有人打卡“

```bash
CallMcpTool: user-cloudbase / readNoSqlDatabaseContent
{
  "collectionName": "check_ins",
  "query": { "date": "2025-01-25" },
  "limit": 10
}
```

### 4. 验证用户数据

**用户**：”数据库里有没有手机号是 +86 13800138000 的用户“

```bash
CallMcpTool: user-cloudbase / readNoSqlDatabaseContent
{
  "collectionName": "users",
  "query": { "phone_number": "+86 13800138000" }
}
```

### 5. 部署 / 更新云函数（通过 MCP）

**用户**：”部署 getCheckInHistory“ 或 “更新 updateProfile 云函数代码”

- 先调用 `getFunctionList`（action: "list"）看该函数是否已存在。
- **已存在**：用 `updateFunctionCode`，参数 `name`（函数名）、`functionRootPath`（`cloudfunctions` 文件夹的绝对路径，如 `{workspaceRoot}/cloudfunctions`）。
- **不存在**：用 `createFunction`，参数 `func`（name、runtime: "Nodejs18.15"、handler: "index.main"、timeout: 20，参考 cloudbaserc.json）、`functionRootPath`（同上）、`force`: true。
- 部署完成后用 `invokeFunction` 或 `getFunctionList`（action: "detail"）做一次验证。

**注意**：调用前先读 MCP 工具 schema（createFunction.json / updateFunctionCode.json），`functionRootPath` 必须是本机「cloudfunctions 目录」的绝对路径（不含函数子目录名）。

## 响应格式

回答时始终包含：

1. **执行的 MCP 操作**（简洁说明）
2. **结果摘要**（关键发现）
3. **下一步建议**（如果需要调试或修复）

示例：

> 📊 **已查询 check_ins 集合** - 用户 user123 今天有 1 条打卡记录（赚了）
>
> 📖 **云函数日志** - getCheckInHistory 近 20 条无报错，最后一次执行成功（11:30）
>
> 🔍 **建议** - 若用户反馈看不到记录，可检查客户端传入的 userId 是否匹配

## 环境说明

- **环境ID**: `prod-1-3g3ukjzod3d5e3a1`
- **Publishable Key**: 已在 `CloudBaseConfig.swift` 配置
- **集合**: check_ins, users, posts, notifications, feedback
- **字段约定**: `_openid` = 用户ID, `date` = 打卡日期, `result` = yes/no

## 常见错误处理

### 查询返回空结果

- ✅ 首先确认用户ID是否存在
- ✅ 检查日期格式是否正确（yyyy-MM-dd）
- ✅ 放宽查询条件（去掉具体筛选）再试

### 云函数报错

- ✅ 立即执行 `getFunctionLogs` 查看最近错误
- ✅ 检查输入参数是否符合函数定义
- ✅ 验证数据库连接是否正常（尝试简单查询）

### 权限问题

- ✅ 确认 Publishable Key 已配置
- ✅ 检查云函数 HTTP 访问权限设置
- ✅ 验证集合 ACL 配置

## 优先级顺序

1. **安全验证数据** → 查询具体用户记录时优先执行
2. **实时调试** → 函数报错时立即查日志
3. **历史验证** → 用户声称记录异常时查历史
4. **性能确认** → 用户反馈慢时检查集合索引

## 不执行 MCP 的情况

❌ 当用户请求的是 **iOS 代码实现** 而非**数据查询/验证**时
❌ 当讨论的是 **UI 设计** 等前端问题而非后端数据时

> **注意**: 以上情况应优先使用现有 iOS 代码库或标准开发流程，不调用 MCP 工具

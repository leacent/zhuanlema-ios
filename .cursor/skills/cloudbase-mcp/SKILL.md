---
name: cloudbase-mcp
description: Use CloudBase MCP tools to manage Tencent CloudBase resources including NoSQL database queries, cloud function deployment and updates, and storage. Use when working with CloudBase backend, deploying or updating cloud functions, querying check_ins/users/posts collections, debugging cloud functions, or when the user mentions CloudBase, database, cloud functions, deploy, or backend operations.
---

# CloudBase MCP Integration

Use the CloudBase MCP server (`user-cloudbase`) to interact with Tencent CloudBase backend services directly from Cursor.

## When to Use CloudBase MCP

**Always prefer MCP tools over manual code when:**
- Querying database collections (check_ins, users, posts, notifications, feedback)
- Inspecting cloud function code or logs
- Debugging backend issues
- Verifying data structure or content
- Testing cloud function invocations
- Managing storage files

**Use iOS code instead when:**
- Implementing app features (use CloudBaseDatabaseService/CloudBaseHTTPClient)
- Writing production client code

## Project Context

**Environment**: `prod-1-3g3ukjzod3d5e3a1`

**Key Collections**:
- `check_ins`: User daily check-in records (date, result: "yes"/"no", userId)
- `users`: User profiles (nickname, avatar, phone_number, createdAt)
- `posts`: Community posts
- `notifications`: User notifications
- `feedback`: User feedback submissions

**Cloud Functions** (in `cloudfunctions/`):
- `createCheckIn`, `getCheckInHistory`, `getTodayCheckInStats`
- `getProfile`, `updateProfile`, `uploadAvatar`
- `getPosts`, `createPost`
- `getUserStats`, `getNotifications`, `submitFeedback`
- `getHotStocks`, `getSectorData`

## Common Operations

### 1. Query Database Collections

**List all collections:**
```
CallMcpTool: user-cloudbase / readNoSqlDatabaseStructure
{
  "action": "listCollections"
}
```

**Check collection structure:**
```
CallMcpTool: user-cloudbase / readNoSqlDatabaseStructure
{
  "action": "describeCollection",
  "collectionName": "check_ins"
}
```

**Query records:**
```
CallMcpTool: user-cloudbase / readNoSqlDatabaseContent
{
  "collectionName": "check_ins",
  "query": { "date": "2025-01-25" },
  "limit": 10
}
```

**Query with sorting:**
```
CallMcpTool: user-cloudbase / readNoSqlDatabaseContent
{
  "collectionName": "posts",
  "sort": { "createdAt": -1 },
  "limit": 5
}
```

### 2. Inspect Cloud Functions

**List all functions:**
```
CallMcpTool: user-cloudbase / getFunctionList
{
  "action": "list"
}
```

**Get function details:**
```
CallMcpTool: user-cloudbase / getFunctionList
{
  "action": "detail",
  "name": "getCheckInHistory"
}
```

**View function logs:**
```
CallMcpTool: user-cloudbase / getFunctionLogs
{
  "functionName": "updateProfile",
  "limit": 20
}
```

### 3. Test Cloud Functions

**Invoke a function:**
```
CallMcpTool: user-cloudbase / invokeFunction
{
  "name": "getTodayCheckInStats",
  "params": {}
}
```

**Invoke with parameters:**
```
CallMcpTool: user-cloudbase / invokeFunction
{
  "name": "getCheckInHistory",
  "params": {
    "userId": "user123",
    "year": 2025,
    "month": 1
  }
}
```

### 4. Deploy or Update Cloud Functions (via MCP)

**When to use:** User asks to deploy/update a cloud function; `invokeFunction` returns "Function not found"; after editing code in `cloudfunctions/<name>/`.

**Required:** Read the tool schema first (`createFunction.json`, `updateFunctionCode.json` in mcps/user-cloudbase/tools/).  
`functionRootPath` must be the **absolute path to the `cloudfunctions` folder** (the directory that contains `getCheckInHistory`, `updateProfile`, etc.), e.g. `{workspaceRoot}/cloudfunctions`.

**Update existing function code** (function already exists in CloudBase):
```
call_mcp_tool: server "user-cloudbase", toolName "updateFunctionCode"
arguments: {
  "name": "getCheckInHistory",
  "functionRootPath": "/Users/leacentsong/Documents/my-code/Zhuanlema/cloudfunctions"
}
```

**Create new function** (e.g. first-time deploy of getCheckInHistory):
```
call_mcp_tool: server "user-cloudbase", toolName "createFunction"
arguments: {
  "func": {
    "name": "getCheckInHistory",
    "runtime": "Nodejs18.15",
    "handler": "index.main",
    "timeout": 20
  },
  "functionRootPath": "/Users/leacentsong/Documents/my-code/Zhuanlema/cloudfunctions",
  "force": true
}
```

**Create HTTP access** (if the function must be callable via HTTP gateway; many environments already have gateway configured):
```
call_mcp_tool: server "user-cloudbase", toolName "createFunctionHTTPAccess"
arguments: { "name": "getCheckInHistory", "path": "/getCheckInHistory" }
```

**Deploy workflow:**
1. If user says "部署 getCheckInHistory" or "deploy getCheckInHistory": call `getFunctionList` with `action: "list"`; if the function name is missing, use `createFunction` (with `func` from `cloudbaserc.json`); if it exists, use `updateFunctionCode` to refresh code.
2. `functionRootPath`: use workspace root + `"/cloudfunctions"` (absolute path, no trailing slash to the function subfolder).
3. After deploy, verify with `invokeFunction` or `getFunctionList` (action: "detail", name: "getCheckInHistory").

## Workflow Patterns

### Debugging a Cloud Function Issue

1. **Check function logs:**
   ```
   getFunctionLogs: { functionName: "updateProfile", limit: 50 }
   ```

2. **Verify input data in database:**
   ```
   readNoSqlDatabaseContent: { collectionName: "users", query: { _id: "userId" } }
   ```

3. **Test function directly:**
   ```
   invokeFunction: { name: "updateProfile", params: { ... } }
   ```

### Verifying Data After iOS Changes

When iOS code creates/updates records:

1. **Query the collection:**
   ```
   readNoSqlDatabaseContent: { collectionName: "check_ins", query: { userId: "..." } }
   ```

2. **Check recent records:**
   ```
   readNoSqlDatabaseContent: { 
     collectionName: "check_ins",
     sort: { createTime: -1 },
     limit: 5
   }
   ```

### Investigating User Issues

1. **Find user record:**
   ```
   readNoSqlDatabaseContent: { collectionName: "users", query: { phone_number: "+86 ..." } }
   ```

2. **Check user's check-ins:**
   ```
   readNoSqlDatabaseContent: { collectionName: "check_ins", query: { _openid: "userId" } }
   ```

3. **Verify user stats:**
   ```
   invokeFunction: { name: "getUserStats", params: { userId: "..." } }
   ```

## Field Name Conventions

**CloudBase collections use:**
- `_id`: Document ID (auto-generated or explicit)
- `_openid`: User ID (for check_ins, posts)
- `createTime` / `createdAt`: Timestamps (milliseconds)
- `updatedAt`: Update timestamp

**iOS models use:**
- `id` (maps from `_id`)
- `userId` (maps from `_openid`)
- `createdAt: Date` (decoded from seconds)

## Tips

1. **Always read tool schema first** before calling MCP tools (use Read on the .json file)
2. **Use MCP for quick verification** instead of running iOS simulator
3. **Check logs first** when debugging function errors
4. **Query recent records** with sort: { createTime: -1 } or { createdAt: -1 }
5. **Limit results** to avoid overwhelming output (default limit: 10-20)

## Common Queries

**Today's check-ins:**
```json
{
  "collectionName": "check_ins",
  "query": { "date": "2025-01-25" },
  "limit": 50
}
```

**User's check-in history:**
```json
{
  "collectionName": "check_ins",
  "query": { "_openid": "userId" },
  "sort": { "date": -1 },
  "limit": 31
}
```

**Recent posts:**
```json
{
  "collectionName": "posts",
  "sort": { "createdAt": -1 },
  "limit": 10
}
```

**All collections:**
```json
{
  "action": "listCollections"
}
```

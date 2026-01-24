# CloudBase 配置说明（iOS 必读）

iOS 应用通过 **HTTP API** 调用 CloudBase 云函数（无 SDK），需配置 **Publishable Key** 方可请求成功。

## 1. 获取 Publishable Key

1. 打开 [CloudBase 控制台 - ApiKey 管理](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/env/apikey)
2. 若尚未创建，点击创建 **Publishable Key**（可暴露在客户端，用于匿名访问公开资源）
3. 复制生成的 Key

## 2. 填入项目

打开 `Zhuanlema/Services/CloudBase/CloudBaseConfig.swift`，将 `_publishableKey` 的占位符替换为你的 Key：

```swift
private static let _publishableKey = "你的Publishable_Key"
```

## 3. 验证

- 社区页加载帖子：会请求 `getPosts` 云函数，需 Publishable Key
- 未配置时：提示「请在 CloudBaseConfig 中配置 Publishable Key」
- 配置后：社区列表应正常展示 `user_posts` 数据

## 4. 调用方式说明

| 方式 | 说明 |
|------|------|
| **HTTP API**（当前） | `https://{envId}.api.tcloudbasegateway.com/v1/functions/{name}`，Header `Authorization: Bearer {Publishable Key}`，不依赖「HTTP 访问服务」 |
| HTTP 访问服务 | `https://{envId}.service.tcloudbase.com/{path}`，需在控制台开通并配置触发路径，当前环境未激活 |

当前实现使用 **HTTP API + Publishable Key**，云函数通过 MCP 部署，数据通过 HTTP API 请求。

---

## 5. 短信服务配置（可选）

`sendSMSCode` 云函数已接入腾讯云短信服务，支持真实发送验证码。

### 配置步骤

1. **申请短信服务**
   - 登录 [腾讯云短信控制台](https://console.cloud.tencent.com/smsv2)
   - 申请短信签名和模板（需审核通过）

2. **配置云函数环境变量**
   - 打开 [CloudBase 控制台 - 云函数](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf)
   - 找到 `sendSMSCode` → 「函数配置」→ 「环境变量」
   - 添加以下变量：
     - `SMS_SDK_APP_ID`: 短信应用 ID（在短信控制台获取）
     - `SMS_TEMPLATE_ID`: 短信模板 ID（已审核通过的模板）
     - `SMS_SIGN_NAME`: 短信签名（可选）

3. **短信模板示例**
   ```
   您的验证码是{1}，5分钟内有效。
   ```
   其中 `{1}` 会被替换为6位验证码。

### 未配置短信服务时

- 验证码仍会正常生成并存储到数据库
- 返回 `debug_code` 字段（可在登录页查看）
- 可通过数据库查看验证码进行测试

### 权限说明

云函数运行角色已自动获得短信服务访问权限，无需手动配置。

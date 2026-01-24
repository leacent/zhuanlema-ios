# CloudBase 身份认证配置说明

本项目已迁移到 **CloudBase 官方身份认证模块**，支持短信验证码登录和微信授权登录。

## 前置条件

### 1. 开启身份认证服务

1. 登录 [CloudBase 控制台 - 身份认证](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/identity/quick-start)
2. 确保身份认证服务已开启

### 2. 配置短信验证码登录

1. 进入 [登录方式管理](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/identity/login-manage)
2. 找到「短信验证码登录」，点击「开启」
3. **注意**：短信验证码登录仅支持**上海地域**

### 3. 配置微信授权登录

1. 在 [微信开放平台](https://open.weixin.qq.com/) 注册应用，获取 `AppId` 和 `AppSecret`
2. 在 [登录方式管理](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/identity/login-manage) 中找到「微信开放平台登录」
3. 点击「去设置」，填入 `AppId` 和 `AppSecret`

### 4. 配置 iOS URL Scheme（微信登录）

在 `Info.plist` 中添加 URL Scheme，用于接收微信授权回调：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>zhuanlema</string>
        </array>
    </dict>
</array>
```

## 功能说明

### 短信验证码登录

1. 用户输入手机号
2. 点击「获取验证码」→ 调用 CloudBase API 发送真实短信
3. 用户输入验证码
4. 点击「登录」→ 验证并登录

**特点：**
- 使用 CloudBase 官方身份认证
- 自动管理用户账号和 Token
- 支持新用户自动注册

### 微信授权登录

1. 用户点击「微信登录」
2. 跳转到微信授权页
3. 用户授权后回调到 App
4. 自动完成登录

**首次微信登录：**
- 如果用户不存在，会返回错误
- 需要先使用手机号注册，然后绑定微信账号

## API 说明

### 短信验证码登录流程

1. **发送验证码**：`POST /auth/v1/verification`
   - Body: `{ "phone_number": "+86 13800000000", "target": "ANY" }`
   - 返回：`{ "verification_id": "...", "expires_in": 600, "is_user": false }`

2. **验证验证码**：`POST /auth/v1/verification/verify`
   - Body: `{ "verification_id": "...", "verification_code": "123456" }`
   - 返回：`{ "verification_token": "..." }`

3. **登录**：`POST /auth/v1/signin`
   - Body: `{ "verification_token": "...", "phone_number": "+86 13800000000" }`
   - 返回：`{ "user": {...}, "access_token": "...", "refresh_token": "..." }`

### 微信授权登录流程

1. **生成授权页 URL**：`POST /auth/v1/provider/redirect_uri`
   - Body: `{ "provider_id": "wx_open", "provider_redirect_uri": "...", "state": "..." }`
   - 返回：`{ "uri": "..." }`

2. **获取授权 Token**：`POST /auth/v1/provider/token`
   - Body: `{ "provider_id": "wx_open", "provider_code": "...", "provider_redirect_uri": "..." }`
   - 返回：`{ "provider_token": "..." }`

3. **登录**：`POST /auth/v1/signin`
   - Body: `{ "provider_token": "..." }`
   - 返回：`{ "user": {...}, "access_token": "...", "refresh_token": "..." }`

## 与旧实现的区别

### 已移除

- ❌ 自定义 `sendSMSCode` 云函数
- ❌ 自定义 `verifyLoginCode` 云函数
- ❌ 自定义 `sms_codes` 数据库集合
- ❌ 自定义用户表和 Token 管理

### 新特性

- ✅ 使用 CloudBase 官方身份认证
- ✅ 自动用户管理（无需手动创建用户表）
- ✅ 自动 Token 管理（Access Token + Refresh Token）
- ✅ 支持多种登录方式（短信、微信等）
- ✅ 可视化管理界面（控制台查看用户）

## 注意事项

1. **短信验证码登录仅支持上海地域**
2. **微信登录需要配置 URL Scheme**
3. **首次微信登录需要先注册用户**
4. **Token 有效期**：Access Token 2小时，Refresh Token 30天

## 测试

### 测试短信验证码登录

1. 确保已开启短信验证码登录
2. 输入手机号，点击「获取验证码」
3. 检查手机是否收到验证码
4. 输入验证码完成登录

### 测试微信登录

1. 确保已配置微信 AppId 和 AppSecret
2. 确保已配置 URL Scheme
3. 点击「微信登录」
4. 完成授权后自动登录

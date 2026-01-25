# 赚了吗 (Zhuanlema) - iOS App

<div align="center">
  <img src="https://img.shields.io/badge/iOS-15.0+-blue.svg" alt="iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.5+-orange.svg" alt="Swift 5.5+">
  <img src="https://img.shields.io/badge/SwiftUI-✓-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/CloudBase-✓-red.svg" alt="CloudBase">
</div>

## 📱 项目简介

**赚了吗** 是一款轻量级投资交易社区 iOS App，专注于交易心得分享和社区互动。采用中国红设计主题，为投资者提供简洁友好的社区体验。

### 核心功能

- 🎯 **每日打卡**: 记录每日盈亏，查看社区统计
- 💬 **心得分享**: 发布交易心得，支持文字、图片、标签
- 👥 **社区互动**: 浏览、点赞、评论其他用户的分享
- 📱 **极简登录**: 手机号验证码，登录即注册

### 技术特点

- **架构**: MVVM + Repository 模式
- **后端**: 腾讯云 CloudBase（数据库、云函数、云存储）
- **设计**: 完整的设计系统，中国红主题
- **适配**: 支持 Dark Mode，响应式布局

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone git@github.com:leacent/zhuanlema-ios.git
cd zhuanlema-ios
```

### 2. 配置 Xcode 项目

详细步骤请参考 [`ADD_FILES_TO_XCODE.md`](ADD_FILES_TO_XCODE.md)

### 3. 构建运行

```bash
open Zhuanlema.xcodeproj
```

在 Xcode 中选择模拟器或真机，点击 Run (⌘R)

### 模拟器下常见控制台提示（可忽略）

运行在 **iOS 模拟器** 时，可能出现：

```
CHHapticPattern patternForKey:error: Failed to read pattern library data ...
hapticpatternlibrary.plist couldn't be opened because there is no such file.
```

这是系统触觉库在模拟器上不存在导致的，**不影响功能**，可忽略。真机上不会出现。项目内如需触觉反馈请使用 `HapticHelper`（仅在真机触发）。

## 📐 项目架构

```
┌─────────────────────────────────────────┐
│          SwiftUI Views                  │
│  (LoginView, HomeView, CommunityView)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          ViewModels                     │
│  (LoginViewModel, HomeViewModel, etc.)  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Repositories                   │
│  (UserRepository, CheckInRepository)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      CloudBase Services                 │
│  (Auth, Database, Storage)              │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      腾讯云 CloudBase                    │
│  (云函数、数据库、云存储)                 │
└─────────────────────────────────────────┘
```

详细架构说明请参考 [`PROJECT_SETUP.md`](PROJECT_SETUP.md)

## 🎨 设计系统

项目包含完整的设计系统，位于 `Zhuanlema/DesignSystem/` 目录：

- **颜色系统**: 中国红主题，支持 Light/Dark Mode
- **排版系统**: 基于 Apple HIG 的字体层级
- **组件库**: 可复用的 UI 组件

详细设计规范请参考 [`Zhuanlema/DesignSystem/README.md`](Zhuanlema/DesignSystem/README.md)

## 🗄️ CloudBase 后端

### ⚠️ 必配：Publishable Key（社区等接口请求必需）

iOS 通过 **HTTP API** 调用云函数，需配置 Publishable Key。详见 **[CLOUDBASE_SETUP.md](CLOUDBASE_SETUP.md)**：

1. 打开 [ApiKey 管理](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/env/apikey)
2. 创建/复制 **Publishable Key**
3. 在 `Zhuanlema/Services/CloudBase/CloudBaseConfig.swift` 中替换 `_publishableKey` 占位符

未配置时，社区页会提示「请在 CloudBaseConfig 中配置 Publishable Key」。

### 环境信息
- **环境 ID**: `prod-1-3g3ukjzod3d5e3a1`
- **控制台**: [打开控制台](https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1)

### 数据库集合

| 集合名 | 说明 | 权限 |
|--------|------|------|
| users | 用户信息 | PRIVATE |
| check_ins | 打卡记录 | PRIVATE |
| posts | 帖子列表 | READONLY |
| sms_codes | 验证码（系统用） | ADMINONLY |

### 云函数

| 函数名 | 说明 |
|--------|------|
| sendSMSCode | 发送短信验证码 |
| verifyLoginCode | 验证登录并注册 |
| getTodayCheckInStats | 获取今日打卡统计 |

## 📦 项目结构

```
Zhuanlema/
├── Models/                    # 数据模型
├── Services/                  # 服务层（CloudBase 封装）
├── Repositories/              # 数据仓库层
├── ViewModels/                # 视图模型（业务逻辑）
├── Views/                     # 视图（UI）
├── Common/                    # 通用工具
└── DesignSystem/              # 设计系统

cloudfunctions/                # 云函数代码
├── sendSMSCode/
├── verifyLoginCode/
└── getTodayCheckInStats/
```

## 🔧 开发指南

### 本地开发

1. 修改代码后，在 Xcode 中构建（⌘B）
2. 运行模拟器测试（⌘R）
3. 查看 Console 输出调试信息

### 云函数开发

1. 修改 `cloudfunctions/` 下的代码
2. 使用 CloudBase MCP 工具部署

### 数据库查看

访问 CloudBase 控制台查看和管理数据：
https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc

## 🎯 MVP 功能清单

### ✅ 已实现
- [x] 手机验证码登录
- [x] 每日打卡功能
- [x] 打卡统计展示
- [x] 社区心得列表
- [x] 发布心得（文字+标签）
- [x] 点赞功能
- [x] 个人中心
- [x] 底部导航

### 🚧 待实现（后续迭代）
- [ ] 图片上传功能
- [ ] 评论功能
- [ ] 表情包选择器
- [ ] 大盘行情展示
- [ ] 个股信息页面
- [ ] 自选股列表
- [ ] 消息通知
- [ ] 用户资料编辑

## 📝 注意事项

1. **CloudBase 调用**: 所有后端操作通过云函数 HTTP API 调用
2. **权限配置**: 数据库安全规则已配置，确保数据安全
3. **Mock 数据**: 部分功能（如图片上传）暂时返回 Mock 数据
4. **测试账号**: 可使用任意手机号测试（开发环境验证码会在云函数日志中）

## 🐛 调试技巧

### 查看云函数日志
访问：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf

### 查看数据库数据
访问：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc

### Xcode 控制台
在 Xcode 中查看 Console 输出，可以看到网络请求和错误信息

## 📄 相关文档

- [项目配置指南](PROJECT_SETUP.md) - 详细的项目配置说明
- [文件添加指南](ADD_FILES_TO_XCODE.md) - 如何将文件添加到 Xcode
- [设计系统](Zhuanlema/DesignSystem/README.md) - UI 设计规范
- [产品需求文档](product.md) - 产品 PRD

## 👨‍💻 作者

**leacent song**

- GitHub: [@leacent](https://github.com/leacent)

## 📄 License

MIT License

---

**最后更新**: 2026-01-24  
**版本**: MVP v1.0
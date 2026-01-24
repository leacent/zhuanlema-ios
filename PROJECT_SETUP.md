# "赚了吗" 项目配置指南

## 项目概述

**赚了吗 (Zhuanlema)** 是一款轻量级投资交易社区 iOS App，功能包括：
- 每日打卡（记录盈亏）
- 社区心得分享
- 交易氛围统计

## 技术栈

- **前端**: SwiftUI (iOS 15+)
- **架构**: MVVM + Repository
- **后端**: 腾讯云 CloudBase
- **设计**: 中国红主题

## Xcode 项目配置

### 步骤 1: 在 Xcode 中添加新文件

由于 SwiftUI 项目需要在 Xcode 中正确配置，请按以下步骤操作：

1. **打开项目**
   ```bash
   open Zhuanlema.xcodeproj
   ```

2. **添加新创建的文件到项目**
   
   在 Xcode 左侧项目导航器中，右键点击 `Zhuanlema` 组，选择 "Add Files to Zhuanlema..."，然后添加以下目录：
   
   - `Models/` (包含 User.swift, CheckIn.swift, Post.swift)
   - `Services/` (包含 CloudBase 服务)
   - `Repositories/` (包含数据仓库)
   - `ViewModels/` (包含视图模型)
   - `Views/` (包含所有视图)
   - `Common/` (通用工具)
   
   **重要**: 确保勾选 "Copy items if needed" 和选择正确的 Target (Zhuanlema)

### 步骤 2: 配置项目设置

1. **设置最低支持版本**
   - 选择项目 > General > Deployment Info
   - iOS Deployment Target: iOS 15.0

2. **配置 App Tint Color**
   - 在 `Assets.xcassets` 中确认已有中国红颜色定义

3. **Info.plist 配置**
   
   添加以下权限（如果需要）：
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>需要访问相册以上传图片</string>
   <key>NSCameraUsageDescription</key>
   <string>需要使用相机拍照</string>
   ```

## CloudBase 资源

### 环境信息
- **环境 ID**: `prod-1-3g3ukjzod3d5e3a1`
- **控制台地址**: https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1

### 数据库集合

| 集合名 | 权限 | 说明 |
|--------|------|------|
| users | PRIVATE | 用户信息 |
| check_ins | PRIVATE | 打卡记录 |
| posts | READONLY | 帖子列表 |
| sms_codes | ADMINONLY | 验证码（系统使用） |

### 云函数

| 函数名 | 说明 | 调用方式 |
|--------|------|----------|
| sendSMSCode | 发送短信验证码 | POST /function/sendSMSCode |
| verifyLoginCode | 验证登录 | POST /function/verifyLoginCode |
| getTodayCheckInStats | 获取今日打卡统计 | POST /function/getTodayCheckInStats |

## 项目架构

```
Zhuanlema/
├── Models/                    # 数据模型
│   ├── User.swift             # 用户模型
│   ├── CheckIn.swift          # 打卡模型
│   └── Post.swift             # 帖子模型
├── Services/                  # 服务层
│   └── CloudBase/             # CloudBase 服务封装
│       ├── CloudBaseConfig.swift
│       ├── CloudBaseAuthService.swift
│       ├── CloudBaseDatabaseService.swift
│       └── CloudBaseStorageService.swift
├── Repositories/              # 数据仓库层
│   ├── UserRepository.swift
│   ├── CheckInRepository.swift
│   └── PostRepository.swift
├── ViewModels/                # 视图模型
│   ├── LoginViewModel.swift
│   ├── HomeViewModel.swift
│   └── CommunityViewModel.swift
├── Views/                     # 视图
│   ├── Login/
│   │   └── LoginView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── CheckInButton.swift
│   ├── Community/
│   │   ├── CommunityView.swift
│   │   └── PostCard.swift
│   ├── MainTabView.swift
│   └── ProfileView.swift
└── DesignSystem/              # 设计系统
    └── Colors/                # 颜色定义
```

## 数据流架构

```
SwiftUI Views
    ↓
ViewModels (业务逻辑)
    ↓
Repositories (数据访问抽象)
    ↓
CloudBase Services (服务封装)
    ↓
CloudBase Backend (腾讯云)
```

## 快速开始

### 1. 构建并运行

在 Xcode 中：
1. 选择模拟器或真机
2. 点击 Run (⌘R)

### 2. 测试登录流程

1. 启动 App，显示登录页面
2. 输入手机号（测试用）
3. 点击"获取验证码"
4. 查看云函数日志获取验证码（开发环境会返回）
5. 输入验证码登录

### 3. 测试打卡功能

1. 登录后进入首页
2. 点击中央圆形打卡按钮
3. 选择"赚了"或"亏了"
4. 查看统计数据更新

### 4. 测试社区功能

1. 切换到"社区" Tab
2. 点击右上角发布按钮
3. 输入内容和标签
4. 发布帖子

## 开发注意事项

### CloudBase 调用说明

所有 CloudBase 操作通过云函数 HTTP API 调用，不使用 SDK：

```swift
// 示例：调用云函数
let url = CloudBaseConfig.functionURL(name: "functionName")
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
// ... 发送请求
```

### 调试技巧

1. **查看云函数日志**
   - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf
   - 查看函数执行日志

2. **查看数据库数据**
   - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc

3. **Mock 数据测试**
   - 初期可以在 Repository 层返回 Mock 数据
   - 确保 UI 和交互正常后再对接真实数据

### 待完善功能

以下功能在 MVP 阶段简化，后续可以迭代：

- [ ] 图片真实上传（目前返回 Mock URL）
- [ ] 真实点赞功能
- [ ] 评论功能
- [ ] 个股行情展示
- [ ] 自选股列表
- [ ] 个人中心完整功能
- [ ] 表情包选择器

## 部署与发布

### CloudBase 资源已部署
- ✅ 数据库集合
- ✅ 安全规则
- ✅ 云函数

### iOS App 发布流程
1. 配置 App ID 和证书
2. 准备 App Icon 和截图
3. 提交 App Store Connect 审核

## 联系与支持

- **开发者**: leacent song
- **项目仓库**: https://github.com/leacent/zhuanlema-ios
- **CloudBase 文档**: https://cloud.tencent.com/document/product/876

---

**最后更新**: 2026-01-24  
**版本**: MVP v1.0

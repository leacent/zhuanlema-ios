# "赚了吗" App 验证清单

## 📋 项目配置验证

### Xcode 项目配置
- [ ] 已在 Xcode 中打开 `Zhuanlema.xcodeproj`
- [ ] 所有 Swift 文件已添加到项目（26 个文件）
- [ ] 文件的 Target Membership 正确（勾选 Zhuanlema）
- [ ] 项目可以成功构建（⌘B 无错误）

### 文件完整性检查

**数据模型 (3 个文件)**
- [ ] `Models/User.swift`
- [ ] `Models/CheckIn.swift`
- [ ] `Models/Post.swift`

**服务层 (4 个文件)**
- [ ] `Services/CloudBase/CloudBaseConfig.swift`
- [ ] `Services/CloudBase/CloudBaseAuthService.swift`
- [ ] `Services/CloudBase/CloudBaseDatabaseService.swift`
- [ ] `Services/CloudBase/CloudBaseStorageService.swift`

**仓库层 (3 个文件)**
- [ ] `Repositories/UserRepository.swift`
- [ ] `Repositories/CheckInRepository.swift`
- [ ] `Repositories/PostRepository.swift`

**视图模型 (3 个文件)**
- [ ] `ViewModels/LoginViewModel.swift`
- [ ] `ViewModels/HomeViewModel.swift`
- [ ] `ViewModels/CommunityViewModel.swift`

**视图层 (8 个文件)**
- [ ] `Views/Login/LoginView.swift`
- [ ] `Views/Home/HomeView.swift`
- [ ] `Views/Home/CheckInButton.swift`
- [ ] `Views/Community/CommunityView.swift`
- [ ] `Views/Community/PostCard.swift`
- [ ] `Views/MainTabView.swift`
- [ ] `Views/ProfileView.swift`
- [ ] `ZhuanlemaApp.swift` (已修改)

**工具类 (2 个文件)**
- [ ] `Common/Extensions/Color+Extensions.swift`
- [ ] `Common/Utils/DateFormatter+Extensions.swift`

## 🧪 功能测试验证

### 登录功能测试
- [ ] **打开 App 显示登录页面**
  - 中国红 Logo 和标题
  - 手机号输入框
  - 验证码输入框
  - 登录按钮

- [ ] **手机号验证**
  - 输入非 11 位数字，登录按钮禁用
  - 输入正确格式，登录按钮启用

- [ ] **发送验证码**
  - 点击"获取验证码"
  - 开始 60 秒倒计时
  - 按钮变灰并显示秒数

- [ ] **查看验证码**（开发环境）
  - 在 Xcode Console 中查找
  - 格式：`[DEBUG] 验证码: 123456`

- [ ] **登录成功**
  - 输入验证码
  - 点击登录
  - 跳转到主界面（首页）

### 打卡功能测试
- [ ] **首页显示**
  - 顶部导航栏
  - 中央圆形打卡按钮（红色，150pt）
  - 统计信息区域
  - 底部 TabBar

- [ ] **打卡按钮动画**
  - 点击按钮有缩放动画
  - 动画流畅自然（Spring 效果）

- [ ] **打卡弹窗**
  - 弹出选择界面
  - 显示"今天赚了吗？"标题
  - "赚了" 按钮（绿色，向上箭头）
  - "亏了" 按钮（红色，向下箭头）
  - 取消按钮

- [ ] **打卡提交**
  - 选择"赚了"或"亏了"
  - 弹窗关闭
  - 按钮变灰，显示"已打卡"
  - 统计数据更新

- [ ] **统计展示**
  - 显示"今日 X% 的人赚了"
  - 左侧：赚了百分比和人数（绿色）
  - 右侧：亏了百分比和人数（红色）

- [ ] **重复打卡限制**
  - 已打卡后再次点击
  - 提示"今日已打卡"

### 社区功能测试
- [ ] **社区列表**
  - 切换到"社区" Tab
  - 显示帖子列表（空状态或有数据）
  - 下拉可以刷新

- [ ] **发布帖子**
  - 点击右上角发布按钮
  - 打开发布页面
  - 输入内容（多行文本）
  - 输入标签（空格分隔）
  - 点击"发布"按钮

- [ ] **帖子卡片显示**
  - 用户头像和昵称
  - 发布时间（相对时间）
  - 内容文字
  - 标签（红色背景）
  - 点赞按钮和数量
  - 评论按钮

- [ ] **点赞交互**
  - 点击爱心图标
  - 数量增加
  - 图标变色（视觉反馈）

### 个人中心测试
- [ ] **个人信息显示**
  - 头像（昵称首字母）
  - 昵称
  - 手机号（中间 4 位隐藏）

- [ ] **统计数据**
  - 打卡数（占位）
  - 帖子数（占位）
  - 点赞数（占位）

- [ ] **功能列表**
  - 编辑资料
  - 消息通知
  - 设置
  - 帮助与反馈

- [ ] **退出登录**
  - 点击"退出登录"
  - 显示确认弹窗
  - 确认后返回登录页面

### 导航功能测试
- [ ] **底部 TabBar**
  - 首页 Tab（房子图标）
  - 社区 Tab（对话气泡图标）
  - 我的 Tab（人物图标）

- [ ] **Tab 切换**
  - 点击不同 Tab 切换页面
  - 选中 Tab 显示红色
  - 切换流畅无卡顿

### Dark Mode 测试
- [ ] **切换到 Dark Mode**
  - 设置 > 显示与亮度 > 深色
  - 或在模拟器：Settings > Developer > Dark Appearance

- [ ] **颜色适配**
  - 背景色自动变暗
  - 文字颜色自动调整
  - 卡片对比度良好
  - 主题红色保持一致

## 🔧 CloudBase 后端验证

### 数据库集合
- [ ] **users 集合已创建**
  - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc/collection/users
  - 权限：PRIVATE

- [ ] **check_ins 集合已创建**
  - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc/collection/check_ins
  - 权限：PRIVATE

- [ ] **posts 集合已创建**
  - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc/collection/posts
  - 权限：READONLY

- [ ] **sms_codes 集合已创建**
  - 访问控制台：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc/collection/sms_codes
  - 权限：ADMINONLY

### 云函数部署
- [ ] **sendSMSCode 函数**
  - 访问：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf/detail?id=sendSMSCode
  - 状态：正常

- [ ] **verifyLoginCode 函数**
  - 访问：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf/detail?id=verifyLoginCode
  - 状态：正常

- [ ] **getTodayCheckInStats 函数**
  - 访问：https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf/detail?id=getTodayCheckInStats
  - 状态：正常

## 📱 UI/UX 质量检查

### 视觉设计
- [ ] 主色调为中国红（#DC143C）
- [ ] 上涨用绿色，下跌用红色（符合中国习惯）
- [ ] 圆角统一（按钮 12pt，卡片 16pt）
- [ ] 阴影效果适度
- [ ] 间距符合 8pt 网格系统

### 交互体验
- [ ] 所有按钮有点击反馈
- [ ] 加载状态有 Loading 指示器
- [ ] 错误提示清晰友好
- [ ] 页面切换流畅
- [ ] 手势操作符合 iOS 规范

### 可访问性
- [ ] 最小触摸区域 44×44pt
- [ ] 文字支持 Dynamic Type
- [ ] 颜色对比度符合标准
- [ ] VoiceOver 标签清晰

## ✅ 最终验收标准

### 必须通过的测试
1. ✅ App 可以成功编译和运行
2. ✅ 登录流程完整可用
3. ✅ 打卡功能正常工作
4. ✅ 社区可以浏览和发布
5. ✅ 三个 Tab 可以正常切换
6. ✅ Dark Mode 适配正常
7. ✅ CloudBase 后端资源部署成功

### 可选的增强测试
- 不同尺寸设备适配（iPhone SE, iPhone 15 Pro Max）
- 网络异常情况处理
- 边界情况测试（空列表、超长文本等）
- 内存和性能表现

## 🎯 验收结果

完成所有必须项后，项目即可交付使用。

**验收人**: _______________  
**验收日期**: _______________  
**验收结果**: [ ] 通过  [ ] 待修改

---

**祝验收顺利！** 🎉

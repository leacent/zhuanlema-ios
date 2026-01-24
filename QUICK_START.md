# "赚了吗" 快速启动指南

## 🚀 3 分钟启动 App

### 步骤 1: 打开 Xcode 项目 (30秒)

```bash
cd /Users/leacentsong/.cursor/worktrees/Zhuanlema/lkt
open Zhuanlema.xcodeproj
```

### 步骤 2: 添加新文件到项目 (1分钟)

在 Xcode 中：

1. 右键点击左侧 `Zhuanlema` 文件夹
2. 选择 "Add Files to 'Zhuanlema'..."
3. 按住 ⌘ 键，选择以下文件夹：
   - `Models`
   - `Services`
   - `Repositories`
   - `ViewModels`
   - `Views`
4. 确保勾选 ✅ "Copy items if needed" 和 ✅ Target: `Zhuanlema`
5. 点击 "Add"

### 步骤 3: 构建并运行 (30秒)

1. 选择模拟器: `iPhone 15 Pro` 或任意设备
2. 按 ⌘B 构建项目
3. 按 ⌘R 运行项目

### 步骤 4: 测试 App (1分钟)

**测试登录**
1. 输入手机号（任意11位数字，如：13800138000）
2. 点击"获取验证码"
3. 查看 Xcode Console，找到日志中的验证码（格式：`[DEBUG] 验证码: XXXXXX`）
4. 输入验证码，点击"登录"

**测试打卡**
1. 登录后自动进入首页
2. 点击中央红色圆形按钮
3. 在弹窗中选择"赚了"或"亏了"
4. 查看统计数据更新

**测试社区**
1. 点击底部"社区" Tab
2. 点击右上角发布按钮
3. 输入内容："今天大盘涨了！"
4. 输入标签："大盘 涨停"
5. 点击"发布"

## ✅ 如果一切正常

你应该看到：
- ✅ 精美的登录界面（中国红主题）
- ✅ 圆形打卡按钮（带动画效果）
- ✅ 统计数据展示
- ✅ 社区帖子列表
- ✅ 底部导航栏

## ❌ 遇到问题？

### 编译错误
- **找不到文件**: 检查文件是否正确添加到 Target
- **模块导入失败**: Clean Build Folder (⌘⇧K) 后重新构建

### 运行错误
- **登录失败**: 检查 CloudBase 环境是否正常
- **网络错误**: 检查模拟器网络连接
- **数据加载失败**: 查看 CloudBase 控制台日志

### 查看详细日志

**云函数日志**
https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/scf

**数据库数据**
https://tcb.cloud.tencent.com/dev?envId=prod-1-3g3ukjzod3d5e3a1#/db/doc

## 📚 更多文档

- [完整项目说明](README.md)
- [项目配置指南](PROJECT_SETUP.md)
- [文件添加详细步骤](ADD_FILES_TO_XCODE.md)
- [交付总结](DELIVERY_SUMMARY.md)

---

**祝你使用愉快！如有问题随时反馈。** 🎉

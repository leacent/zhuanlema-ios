# 如何将新文件添加到 Xcode 项目

## 方法一：批量添加文件夹（推荐）

1. **打开 Xcode 项目**
   ```bash
   cd /Users/leacentsong/.cursor/worktrees/Zhuanlema/lkt
   open Zhuanlema.xcodeproj
   ```

2. **在 Xcode 中添加文件夹**
   - 在左侧项目导航器中，右键点击 `Zhuanlema` 文件夹
   - 选择 "Add Files to 'Zhuanlema'..."
   - 导航到项目根目录
   - 按住 ⌘ 键，选择以下文件夹：
     - `Models`
     - `Services`
     - `Repositories`
     - `ViewModels`
     - `Views`
     - `Common`
   
3. **配置添加选项**
   - ✅ 勾选 "Copy items if needed"
   - ✅ 选择 "Create groups"
   - ✅ 勾选 Target: `Zhuanlema`
   - 点击 "Add"

## 方法二：逐个添加文件

如果批量添加遇到问题，可以逐个添加：

### 必须添加的核心文件（按顺序）：

1. **Models 层**
   - `Models/User.swift`
   - `Models/CheckIn.swift`
   - `Models/Post.swift`

2. **Services 层**
   - `Services/CloudBase/CloudBaseConfig.swift`
   - `Services/CloudBase/CloudBaseAuthService.swift`
   - `Services/CloudBase/CloudBaseDatabaseService.swift`
   - `Services/CloudBase/CloudBaseStorageService.swift`

3. **Repositories 层**
   - `Repositories/UserRepository.swift`
   - `Repositories/CheckInRepository.swift`
   - `Repositories/PostRepository.swift`

4. **ViewModels 层**
   - `ViewModels/LoginViewModel.swift`
   - `ViewModels/HomeViewModel.swift`
   - `ViewModels/CommunityViewModel.swift`

5. **Views 层**
   - `Views/Login/LoginView.swift`
   - `Views/Home/HomeView.swift`
   - `Views/Home/CheckInButton.swift`
   - `Views/Community/CommunityView.swift`
   - `Views/Community/PostCard.swift`
   - `Views/MainTabView.swift`
   - `Views/ProfileView.swift`

## 验证文件已添加

1. 在 Xcode 左侧导航器中，确认所有文件都显示
2. 尝试构建项目（⌘B）
3. 检查是否有编译错误

## 常见问题

### Q: 文件显示为灰色？
A: 右键点击文件 > "Show in Finder"，确认文件存在后，右键 > "Delete" > "Remove Reference"，然后重新添加。

### Q: 编译时提示找不到文件？
A: 检查 Target Membership，确保文件属于正确的 Target。

### Q: 文件夹结构混乱？
A: 在 Finder 中整理好文件夹结构后，删除 Xcode 中的引用，重新批量添加。

## 下一步

文件添加完成后：
1. 构建项目（⌘B）确认无编译错误
2. 运行项目（⌘R）测试功能
3. 参考 `PROJECT_SETUP.md` 了解项目详情

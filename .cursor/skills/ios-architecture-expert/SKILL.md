---
name: ios-architecture-expert
description: 资深iOS架构工程师，精通iOS应用架构设计和性能优化。专注于架构模式(MVVM/VIPER/Clean Architecture)、模块化设计、腾讯云CloudBase后台集成、性能调优、内存管理和启动优化。遵循SOLID原则和最佳实践。本项目使用腾讯云CloudBase作为后台服务（数据库、用户认证、云函数、存储）。当用户需要设计应用架构、集成后台服务、重构代码结构、优化性能、解决内存问题、审查架构代码时使用。
---

# iOS架构专家技能

作为资深iOS架构工程师，提供专业的应用架构设计和性能优化指导，确保代码可维护、可测试、高性能。

**重要**: 本项目使用腾讯云 CloudBase 作为后台服务，所有后台功能通过 `/cloudbase` 命令调用 CloudBase MCP 工具实现。

## 核心职责

### 1. 架构设计与模式选择

根据项目规模和需求选择合适的架构模式：

**小型项目 (< 20个页面)**
- **推荐**: MVVM with Combine/Async-Await
- **理由**: 简洁、现代化、易于理解
- **数据流**: View → ViewModel → Model

**中型项目 (20-50个页面)**
- **推荐**: MVVM + Coordinator
- **理由**: 解耦导航逻辑、便于模块化
- **数据流**: View → ViewModel → Model + Coordinator处理路由

**大型项目 (> 50个页面)**
- **推荐**: Clean Architecture或VIPER
- **理由**: 高度模块化、清晰的依赖关系、易于团队协作
- **分层**: Presentation → Domain → Data

**架构评估清单**
```markdown
评估现有或计划的架构：
- [ ] 职责是否明确分离？
- [ ] 是否便于单元测试？
- [ ] 新成员能否快速理解？
- [ ] 是否支持模块化开发？
- [ ] 业务逻辑是否独立于UI框架？
```

### 2. MVVM架构实现

**ViewModel最佳实践**
```swift
/// ViewModel应该：
/// - 不依赖UIKit（除必要的类型如UIImage）
/// - 提供可观察的状态（使用Combine或@Published）
/// - 处理所有业务逻辑和数据转换
/// - 通过协议注入依赖（便于测试）

/// ✅ 良好的ViewModel设计
final class UserProfileViewModel {
    // 输出：UI需要观察的状态
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // 依赖注入
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    // 输入：UI触发的动作
    func loadUserProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        
        userService.fetchUser(id: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                }
            )
            .store(in: &cancellables)
    }
}
```

**View层职责**
- 仅负责UI展示和用户交互
- 通过ViewModel获取数据
- 不包含业务逻辑
- 保持轻量级

### 3. 模块化与依赖管理

**模块划分原则**
```
App架构示例：
├── Core/                    # 核心模块
│   ├── Networking/         # 网络层
│   ├── Storage/            # 数据持久化
│   └── Common/             # 通用工具
├── Features/               # 功能模块
│   ├── Authentication/     # 认证模块
│   ├── UserProfile/        # 用户资料
│   └── Feed/               # 内容流
└── App/                    # 应用入口

依赖规则：
- Feature模块不能相互依赖
- Core模块独立，可被Feature使用
- 通过协议定义模块间通信
```

**依赖注入策略**
```swift
/// 使用协议抽象依赖
protocol UserServiceProtocol {
    func fetchUser(id: String) -> AnyPublisher<UserProfile, Error>
}

/// 通过初始化器注入（推荐用于ViewModels）
class UserViewModel {
    private let userService: UserServiceProtocol
    init(userService: UserServiceProtocol) {
        self.userService = userService
    }
}

/// 使用工厂模式创建依赖
class ServiceFactory {
    static func makeUserService() -> UserServiceProtocol {
        #if DEBUG
        return MockUserService()
        #else
        return UserService()
        #endif
    }
}
```

### 4. 腾讯云 CloudBase 后台集成

**重要说明**: 本项目使用腾讯云 CloudBase 作为后台服务，所有后台功能（数据库、用户认证、云函数、文件存储等）都通过 CloudBase MCP 工具实现。

**CloudBase 服务集成架构**

```
iOS App
   ├─ Presentation Layer (Views, ViewModels)
   ├─ Domain Layer (Use Cases, Business Logic)
   └─ Data Layer
       ├─ Repositories (抽象层)
       └─ CloudBase Services (具体实现)
           ├─ CloudBaseAuth (用户认证)
           ├─ CloudBaseDatabase (数据库)
           ├─ CloudBaseStorage (文件存储)
           └─ CloudBaseFunction (云函数)
```

**核心服务封装**

```swift
/// CloudBase 认证服务
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String) async throws -> User
    func logout() async throws
    func getCurrentUser() -> User?
}

class CloudBaseAuthService: AuthServiceProtocol {
    /// 使用 /cloudbase 命令调用 CloudBase MCP 工具实现
    /// 工具: login, manageDataModel (用户表)
    
    func login(email: String, password: String) async throws -> User {
        // 通过 CloudBase MCP 工具的 executeReadOnlySQL 或 readNoSqlDatabaseContent
        // 验证用户凭证并返回用户信息
        
        // 示例实现流程：
        // 1. 调用 CloudBase 云函数验证登录
        // 2. 获取用户Token
        // 3. 存储到本地 Keychain
        // 4. 返回用户对象
        
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func register(email: String, password: String) async throws -> User {
        // 通过 writeNoSqlDatabaseContent 创建新用户
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func logout() async throws {
        // 清除本地token和缓存
        TokenManager.shared.clearToken()
        CacheManager.shared.clearUserCache()
    }
    
    func getCurrentUser() -> User? {
        // 从本地获取已登录用户信息
        return TokenManager.shared.currentUser
    }
}

/// CloudBase 数据库服务
protocol DatabaseServiceProtocol {
    func fetchItems<T: Codable>(collection: String, query: [String: Any]?) async throws -> [T]
    func create<T: Codable>(collection: String, item: T) async throws -> String
    func update<T: Codable>(collection: String, id: String, item: T) async throws
    func delete(collection: String, id: String) async throws
}

class CloudBaseDatabaseService: DatabaseServiceProtocol {
    /// 使用 /cloudbase 命令调用以下 MCP 工具：
    /// - readNoSqlDatabaseContent: 读取数据
    /// - writeNoSqlDatabaseContent: 写入数据
    /// - executeReadOnlySQL: 执行只读SQL查询
    /// - executeWriteSQL: 执行写入SQL
    
    func fetchItems<T: Codable>(collection: String, query: [String: Any]?) async throws -> [T] {
        // 通过 readNoSqlDatabaseContent 或 executeReadOnlySQL 查询数据
        // 返回解码后的对象数组
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func create<T: Codable>(collection: String, item: T) async throws -> String {
        // 通过 writeNoSqlDatabaseContent 或 executeWriteSQL 创建记录
        // 返回新创建的文档ID
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func update<T: Codable>(collection: String, id: String, item: T) async throws {
        // 更新指定ID的文档
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func delete(collection: String, id: String) async throws {
        // 删除指定ID的文档
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
}

/// CloudBase 存储服务
protocol StorageServiceProtocol {
    func uploadFile(data: Data, path: String) async throws -> String
    func downloadFile(path: String) async throws -> Data
    func deleteFile(path: String) async throws
}

class CloudBaseStorageService: StorageServiceProtocol {
    /// 使用 /cloudbase 命令调用以下 MCP 工具：
    /// - uploadFiles: 上传文件
    /// - downloadRemoteFile: 下载文件
    /// - deleteFiles: 删除文件
    /// - queryStorage: 查询存储信息
    
    func uploadFile(data: Data, path: String) async throws -> String {
        // 通过 uploadFiles 上传文件到云存储
        // 返回文件的云端URL
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func downloadFile(path: String) async throws -> Data {
        // 通过 downloadRemoteFile 下载文件
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
    
    func deleteFile(path: String) async throws {
        // 通过 deleteFiles 删除云端文件
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
}

/// CloudBase 云函数服务
protocol CloudFunctionServiceProtocol {
    func invoke(functionName: String, parameters: [String: Any]) async throws -> [String: Any]
}

class CloudBaseFunctionService: CloudFunctionServiceProtocol {
    /// 使用 /cloudbase 命令调用以下 MCP 工具：
    /// - invokeFunction: 调用云函数
    /// - getFunctionList: 获取函数列表
    /// - createFunction: 创建云函数（开发时使用）
    
    func invoke(functionName: String, parameters: [String: Any]) async throws -> [String: Any] {
        // 通过 invokeFunction 调用云函数
        // 返回函数执行结果
        throw NSError(domain: "待通过CloudBase MCP实现", code: -1)
    }
}
```

**Repository 层集成示例**

```swift
/// 用户数据仓库
class UserRepository {
    private let authService: AuthServiceProtocol
    private let databaseService: DatabaseServiceProtocol
    
    init(authService: AuthServiceProtocol = CloudBaseAuthService(),
         databaseService: DatabaseServiceProtocol = CloudBaseDatabaseService()) {
        self.authService = authService
        self.databaseService = databaseService
    }
    
    func login(email: String, password: String) async throws -> User {
        return try await authService.login(email: email, password: password)
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let profiles: [UserProfile] = try await databaseService.fetchItems(
            collection: "users",
            query: ["_id": userId]
        )
        
        guard let profile = profiles.first else {
            throw RepositoryError.userNotFound
        }
        
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await databaseService.update(
            collection: "users",
            id: profile.id,
            item: profile
        )
    }
}

/// 内容数据仓库
class ContentRepository {
    private let databaseService: DatabaseServiceProtocol
    private let storageService: StorageServiceProtocol
    
    init(databaseService: DatabaseServiceProtocol = CloudBaseDatabaseService(),
         storageService: StorageServiceProtocol = CloudBaseStorageService()) {
        self.databaseService = databaseService
        self.storageService = storageService
    }
    
    func fetchFeedItems(page: Int, pageSize: Int) async throws -> [FeedItem] {
        // 从 CloudBase 数据库查询内容列表
        return try await databaseService.fetchItems(
            collection: "feed_items",
            query: [
                "skip": page * pageSize,
                "limit": pageSize,
                "sort": ["createdAt": -1]
            ]
        )
    }
    
    func uploadImage(_ imageData: Data) async throws -> String {
        // 上传图片到 CloudBase 云存储
        let imagePath = "images/\(UUID().uuidString).jpg"
        return try await storageService.uploadFile(data: imageData, path: imagePath)
    }
}
```

**使用 CloudBase 的架构最佳实践**

1. **分层隔离**: Repository 层封装所有 CloudBase 调用，Domain 层不直接依赖 CloudBase
2. **协议抽象**: 使用协议定义服务接口，便于单元测试和 Mock
3. **错误处理**: 统一处理 CloudBase 错误，转换为业务错误类型
4. **缓存策略**: 本地缓存频繁访问的数据，减少云端请求
5. **安全规则**: 通过 CloudBase 安全规则控制数据访问权限

**CloudBase MCP 工具调用方式**

在需要实现后台功能时，使用 `/cloudbase` 命令配合以下 MCP 工具：

| 功能类别 | 主要工具 |
|---------|---------|
| **数据库操作** | readNoSqlDatabaseContent, writeNoSqlDatabaseContent, executeReadOnlySQL, executeWriteSQL |
| **用户认证** | manageDataModel (用户表), invokeFunction (认证函数) |
| **文件存储** | uploadFiles, downloadRemoteFile, deleteFiles, queryStorage |
| **云函数** | invokeFunction, getFunctionList, createFunction, updateFunctionCode |
| **权限控制** | readSecurityRule, writeSecurityRule |

**示例：实现用户登录功能的完整流程**

```markdown
1. 设计数据模型
   - 调用 /cloudbase 使用 manageDataModel 创建用户表结构

2. 创建认证云函数
   - 调用 /cloudbase 使用 createFunction 创建登录验证函数
   - 使用 updateFunctionCode 实现登录逻辑

3. 实现 iOS 端服务层
   - 创建 CloudBaseAuthService 实现登录接口
   - 通过 invokeFunction 调用云端登录函数

4. 集成到架构中
   - Repository 使用 AuthService
   - ViewModel 调用 Repository
   - View 绑定 ViewModel 状态
```

### 5. 性能优化策略

**启动时间优化**
```swift
/// 优化app启动流程
/// 
/// 目标：
/// - Cold Launch < 400ms
/// - Warm Launch < 200ms

// ✅ 延迟非必要的初始化
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 立即执行：仅初始化关键服务
    setupWindow()
    configureNetworking()
    
    // 延迟执行：非关键服务
    DispatchQueue.main.async {
        self.setupAnalytics()
        self.configureThirdPartySDKs()
    }
    
    // 后台执行：数据预加载
    DispatchQueue.global(qos: .background).async {
        self.preloadCache()
    }
    
    return true
}

// ❌ 避免：同步执行耗时操作
func application(...) -> Bool {
    setupDatabase()        // 可能耗时100ms
    initializeSDKs()       // 可能耗时200ms
    loadConfiguration()    // 可能耗时50ms
    return true
}
```

**内存优化**
```swift
/// 避免内存泄漏和过度占用

// ✅ 使用weak/unowned打破循环引用
class ImageLoader {
    func loadImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            // 使用weak self避免循环引用
        }.resume()
    }
}

// ✅ 大对象及时释放
class DataProcessor {
    func processLargeFile() {
        autoreleasepool {
            // 大数据处理在这里
            let data = loadLargeData()
            process(data)
            // 离开作用域时自动释放
        }
    }
}

// ✅ 图片内存优化
extension UIImageView {
    func loadImage(url: URL) {
        // 根据imageView尺寸调整图片大小
        let size = self.bounds.size
        ImageCache.shared.loadImage(url: url, targetSize: size) { [weak self] image in
            self?.image = image
        }
    }
}
```

**列表性能优化**
```swift
/// UITableView/UICollectionView优化

// ✅ 正确实现cell重用
class FeedCell: UITableViewCell {
    static let identifier = "FeedCell"
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 重置状态，取消pending任务
        imageView?.image = nil
        imageLoadTask?.cancel()
    }
    
    func configure(with item: FeedItem) {
        // 配置cell
    }
}

// ✅ 使用prefetching预加载
extension FeedViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // 预加载图片或数据
        for indexPath in indexPaths {
            let item = items[indexPath.row]
            ImageCache.shared.prefetch(url: item.imageURL)
        }
    }
}

// ✅ 避免在cellForRow中执行耗时操作
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    // ✅ 数据已在后台准备好
    let item = viewModel.items[indexPath.row]
    cell.configure(with: item)
    
    // ❌ 避免：在这里进行数据转换或计算
    // let formatted = heavyCalculation(item) // 会导致滚动卡顿
    
    return cell
}
```

**网络性能优化**
```swift
/// 网络请求优化策略

// ✅ 实现请求缓存
class NetworkService {
    private let cache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,  // 50 MB
        diskCapacity: 100 * 1024 * 1024     // 100 MB
    )
    
    func fetch<T: Decodable>(url: URL, cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: url)
        request.cachePolicy = cachePolicy
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// ✅ 请求合并与批处理
class BatchRequestManager {
    private var pendingUserIDs: Set<String> = []
    private var batchTimer: Timer?
    
    func fetchUser(id: String, completion: @escaping (User?) -> Void) {
        pendingUserIDs.insert(id)
        
        // 100ms内的请求合并成一个批量请求
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.executeBatchRequest()
        }
    }
}
```

### 6. 代码质量与SOLID原则

**单一职责原则 (SRP)**
```swift
// ❌ 职责混乱
class UserManager {
    func fetchUser() { }
    func saveUser() { }
    func validateEmail() { }
    func sendNotification() { }
}

// ✅ 职责明确分离
class UserRepository {
    func fetchUser() -> User? { }
    func saveUser(_ user: User) { }
}

class EmailValidator {
    func validate(_ email: String) -> Bool { }
}

class NotificationService {
    func send(message: String) { }
}
```

**开闭原则 (OCP)**
```swift
// ✅ 通过协议扩展，无需修改原有代码
protocol PaymentMethod {
    func processPayment(amount: Decimal) -> Bool
}

class CreditCardPayment: PaymentMethod { }
class ApplePayPayment: PaymentMethod { }
class WeChatPayment: PaymentMethod { } // 新增支付方式

class PaymentProcessor {
    func process(using method: PaymentMethod, amount: Decimal) {
        method.processPayment(amount: amount)
    }
}
```

**依赖倒置原则 (DIP)**
```swift
// ✅ 依赖抽象而非具体实现
protocol DataStore {
    func save(_ data: Data) async throws
    func load() async throws -> Data
}

class ViewModel {
    private let dataStore: DataStore
    
    // 可以注入任何实现DataStore的类
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
}

class UserDefaultsStore: DataStore { }
class FileSystemStore: DataStore { }
class KeychainStore: DataStore { }
```

### 7. 架构审查清单

审查代码时使用此清单：

**架构层面**
- [ ] 是否有明确的分层架构？
- [ ] 各层职责是否清晰？
- [ ] 依赖方向是否正确（高层不依赖低层细节）？
- [ ] 是否便于编写单元测试？

**性能层面**
- [ ] 是否存在主线程阻塞？
- [ ] 图片是否正确缓存和压缩？
- [ ] 列表滚动是否流畅（60fps）？
- [ ] 是否有内存泄漏风险？
- [ ] 启动流程是否优化？

**代码质量**
- [ ] 是否遵循SOLID原则？
- [ ] 函数/类是否足够简洁？（函数<50行，类<500行）
- [ ] 是否有重复代码可以提取？
- [ ] 命名是否清晰表意？
- [ ] 注释是否使用JSDoc格式？

**可维护性**
- [ ] 新功能是否易于添加？
- [ ] 是否便于替换第三方库？
- [ ] 配置是否集中管理？
- [ ] 错误处理是否完善？

## 工作流程

### 新功能架构设计

```markdown
1. 需求分析
   - 理解功能需求和用户场景
   - 评估复杂度和依赖关系

2. 架构设计
   - 选择合适的架构模式
   - 定义数据流和状态管理
   - 设计协议和接口

3. 模块划分
   - 确定需要的ViewModel、Service、Repository
   - 定义模块间通信方式
   - 考虑可测试性

4. 实现评审
   - 代码是否符合SOLID原则？
   - 是否考虑了性能影响？
   - 测试覆盖是否充分？
```

### 性能问题诊断

```markdown
1. 问题定位
   - 使用Instruments (Time Profiler, Allocations, Leaks)
   - 确定性能瓶颈位置

2. 分析原因
   - 主线程阻塞？
   - 内存过度使用？
   - 频繁的对象创建/销毁？
   - 网络请求过多？

3. 优化方案
   - 异步处理耗时操作
   - 实现合理的缓存策略
   - 优化算法和数据结构
   - 减少不必要的计算

4. 验证效果
   - 重新测试性能指标
   - 确保无副作用
```

### 重构现有代码

```markdown
1. 评估现状
   - 代码复杂度如何？
   - 测试覆盖率多少？
   - 主要问题是什么？

2. 制定计划
   - 确定重构范围（避免过度重构）
   - 优先级排序
   - 评估风险

3. 渐进式重构
   - 添加测试保护
   - 小步迭代，频繁验证
   - 保持功能不变

4. 代码审查
   - 是否达成重构目标？
   - 是否引入新问题？
   - 团队是否理解新架构？
```

## 常见问题与解决方案

### Q: 如何选择合适的架构模式？

**考虑因素**：
- 团队规模和经验
- 项目复杂度和生命周期
- 是否需要多模块开发
- 测试要求

**决策树**：
```
项目是否会持续维护超过1年？
├─ 是 → 项目是否有超过3个开发者？
│       ├─ 是 → Clean Architecture / VIPER
│       └─ 否 → MVVM + Coordinator
└─ 否 → 团队是否熟悉SwiftUI？
        ├─ 是 → SwiftUI + MVVM
        └─ 否 → 简化的MVVM
```

### Q: 如何避免Massive ViewModel？

**解决方案**：
1. 提取子ViewModels处理复杂子功能
2. 使用Use Case封装业务逻辑
3. 状态管理独立成State对象
4. 网络/存储逻辑下沉到Repository层

```swift
// ✅ 将复杂ViewModel拆分
class OrderListViewModel {
    private let listManager: OrderListManager
    private let filterManager: OrderFilterManager
    private let sortManager: OrderSortManager
    
    var filterViewModel: OrderFilterViewModel { ... }
    var sortViewModel: OrderSortViewModel { ... }
}
```

### Q: 如何处理异步操作和状态管理？

**推荐方案**：
- Swift 5.5+: 使用 async/await
- 状态管理: Combine 或 第三方库 (Redux-like)
- 错误处理: Result type + 明确的错误类型

```swift
// ✅ 使用async/await
class DataViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    
    enum ViewState {
        case idle
        case loading
        case loaded(data: [Item])
        case error(message: String)
    }
    
    func loadData() async {
        state = .loading
        
        do {
            let items = try await repository.fetchItems()
            state = .loaded(data: items)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
}
```

### Q: 如何优化App包体积？

**优化策略**：
1. **资源优化**
   - 压缩图片（使用Asset Catalog的压缩选项）
   - 移除未使用的资源
   - 按需下载资源（On-Demand Resources）

2. **代码优化**
   - 移除未使用的代码和库
   - 启用App Thinning
   - 使用动态库代替静态库（对于大型库）

3. **第三方库审查**
   - 评估每个库的必要性
   - 寻找更轻量的替代方案
   - 考虑自己实现简单功能

### Q: 如何在架构中正确集成 CloudBase 后台服务？

**集成原则**：
1. **分层隔离**: 将 CloudBase 调用封装在 Data Layer 的 Service 层
2. **协议抽象**: 通过协议定义后台服务接口，Domain Layer 不直接依赖 CloudBase
3. **错误转换**: 将 CloudBase 错误转换为业务层错误类型

**实现步骤**：

```swift
// 第1步: 定义业务层协议（Domain Layer）
protocol UserRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func fetchProfile(userId: String) async throws -> UserProfile
}

// 第2步: 实现 CloudBase Service（Data Layer）
class CloudBaseService {
    // 调用 /cloudbase 命令使用 MCP 工具
    func invokeCloudFunction(_ name: String, params: [String: Any]) async throws -> [String: Any] {
        // 实际通过 CloudBase MCP 的 invokeFunction 工具实现
        fatalError("使用 /cloudbase 命令实现")
    }
    
    func queryDatabase(_ collection: String, query: [String: Any]) async throws -> [[String: Any]] {
        // 通过 readNoSqlDatabaseContent 工具实现
        fatalError("使用 /cloudbase 命令实现")
    }
}

// 第3步: 实现 Repository（Data Layer）
class UserRepository: UserRepositoryProtocol {
    private let cloudBaseService: CloudBaseService
    
    init(cloudBaseService: CloudBaseService = CloudBaseService()) {
        self.cloudBaseService = cloudBaseService
    }
    
    func login(email: String, password: String) async throws -> User {
        do {
            // 调用 CloudBase 云函数验证登录
            let result = try await cloudBaseService.invokeCloudFunction(
                "userLogin",
                params: ["email": email, "password": password]
            )
            
            // 转换为业务对象
            return try User(from: result)
        } catch {
            // 转换错误类型
            throw RepositoryError.loginFailed(reason: error.localizedDescription)
        }
    }
    
    func fetchProfile(userId: String) async throws -> UserProfile {
        let results = try await cloudBaseService.queryDatabase(
            "users",
            query: ["_id": userId]
        )
        
        guard let profileData = results.first else {
            throw RepositoryError.userNotFound
        }
        
        return try UserProfile(from: profileData)
    }
}

// 第4步: ViewModel 使用 Repository（Presentation Layer）
class UserViewModel: ObservableObject {
    private let repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
    
    func login(email: String, password: String) async {
        do {
            let user = try await repository.login(email: email, password: password)
            // 更新UI状态
        } catch {
            // 显示错误
        }
    }
}
```

**CloudBase 集成最佳实践**：
- ✅ **使用命令**: 通过 `/cloudbase` 命令调用 MCP 工具实现后台功能
- ✅ **错误处理**: 统一捕获和转换 CloudBase 错误
- ✅ **缓存策略**: 实现本地缓存减少网络请求
- ✅ **离线支持**: 缓存关键数据，支持离线访问
- ✅ **安全规则**: 使用 CloudBase 安全规则保护数据
- ✅ **测试隔离**: 通过协议 Mock CloudBase 服务进行单元测试

## 参考资源

详细的架构模式和性能优化技术，请参考：
- [ARCHITECTURE_PATTERNS.md](ARCHITECTURE_PATTERNS.md) - 深入讲解各种架构模式
- [PERFORMANCE_GUIDE.md](PERFORMANCE_GUIDE.md) - 详细的性能优化指南

## 输出标准

提供架构建议或代码审查时：

1. **架构设计方案**
   - 清晰说明选择的架构模式和原因
   - 提供目录结构和模块划分示例
   - 说明数据流和依赖关系
   - **包含 CloudBase 集成方案**（如何封装后台服务）

2. **代码示例**
   - 使用JSDoc风格注释
   - 包含关键接口和协议定义
   - 展示完整的数据流
   - **标注 CloudBase 调用点**（说明需要通过 `/cloudbase` 命令实现）

3. **性能优化方案**
   - 明确指出性能问题
   - 提供具体的优化代码
   - 给出预期的性能提升
   - **考虑 CloudBase 请求优化**（缓存、批量请求等）

4. **后台功能实现**
   - 明确说明需要使用 `/cloudbase` 命令
   - 列出需要的 CloudBase MCP 工具
   - 提供数据模型和云函数设计
   - 说明安全规则配置

5. **审查反馈**
   - 🔴 **严重问题**：影响性能、稳定性或可维护性
   - 🟡 **建议改进**：可以做得更好的地方
   - 🟢 **好的实践**：值得保持的优秀代码
   - 💡 **CloudBase 优化**：后台服务可以改进的地方

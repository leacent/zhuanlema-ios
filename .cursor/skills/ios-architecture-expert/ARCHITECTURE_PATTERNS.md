# iOS 架构模式详解

本文档深入讲解iOS开发中常用的架构模式，帮助你根据项目需求选择合适的架构。

## 目录

- [MVC (Model-View-Controller)](#mvc)
- [MVVM (Model-View-ViewModel)](#mvvm)
- [VIPER](#viper)
- [Clean Architecture](#clean-architecture)
- [Coordinator Pattern](#coordinator-pattern)
- [架构对比](#架构对比)

---

## MVC

### 概述
Apple推荐的传统架构模式，View和Controller紧密结合。

### 结构

```
Model ←→ Controller ←→ View
```

### 适用场景
- 原型项目或POC
- 非常简单的应用（<10个页面）
- 快速开发优先于长期维护

### 优点
- 简单直接，学习曲线低
- Apple原生支持
- 代码量少

### 缺点
- Controller容易变成"Massive View Controller"
- 难以测试
- View和Controller耦合严重

### 示例

```swift
// Model
struct User {
    let id: String
    let name: String
}

// View Controller (View + Controller)
class UserViewController: UIViewController {
    private let nameLabel = UILabel()
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUser()
    }
    
    private func loadUser() {
        // 数据加载、业务逻辑、UI更新都在这里
        APIService.fetchUser { [weak self] user in
            self?.user = user
            self?.nameLabel.text = user.name
        }
    }
}
```

---

## MVVM

### 概述
将业务逻辑从View Controller分离到ViewModel，通过数据绑定同步UI。

### 结构

```
View ←→ ViewModel ←→ Model
       (binding)
```

### 适用场景
- 中小型项目（10-50个页面）
- 需要良好的可测试性
- 使用SwiftUI或Combine的项目

### 优点
- ViewModel可独立测试
- View层轻量化
- 清晰的数据流
- 支持数据绑定

### 缺点
- 需要数据绑定机制（Combine/RxSwift）
- 对于简单页面可能过度设计

### 完整示例

```swift
// Model
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

// Service Protocol
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws
}

// ViewModel
@MainActor
class UserViewModel: ObservableObject {
    // Output: UI观察的状态
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    // Dependencies
    private let userService: UserServiceProtocol
    private let userId: String
    
    init(userId: String, userService: UserServiceProtocol) {
        self.userId = userId
        self.userService = userService
    }
    
    // Input: UI触发的操作
    func loadUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.fetchUser(id: userId)
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateUserName(_ name: String) async {
        guard var currentUser = user else { return }
        currentUser.name = name
        
        do {
            try await userService.updateUser(currentUser)
            user = currentUser
        } catch {
            errorMessage = "更新失败: \(error.localizedDescription)"
        }
    }
}

// View (SwiftUI)
struct UserView: View {
    @StateObject private var viewModel: UserViewModel
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: UserViewModel(
            userId: userId,
            userService: UserService()
        ))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                VStack {
                    Text(user.name)
                    Text(user.email)
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadUser()
        }
    }
}

// View (UIKit)
class UserViewController: UIViewController {
    private let viewModel: UserViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let nameLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView()
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        
        Task {
            await viewModel.loadUser()
        }
    }
    
    private func bindViewModel() {
        viewModel.$user
            .sink { [weak self] user in
                self?.nameLabel.text = user?.name
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
}
```

---

## VIPER

### 概述
View-Interactor-Presenter-Entity-Router，高度模块化的架构。

### 结构

```
View ←→ Presenter ←→ Interactor
         ↓              ↓
      Router         Entity
```

- **View**: 显示UI，传递用户操作
- **Interactor**: 业务逻辑
- **Presenter**: 协调View和Interactor
- **Entity**: 数据模型
- **Router**: 导航逻辑

### 适用场景
- 大型项目（>50个页面）
- 多人团队协作
- 需要高度模块化
- 复杂的业务逻辑

### 优点
- 职责极其明确
- 高度可测试
- 易于模块化
- 便于团队并行开发

### 缺点
- 代码量大，文件多
- 学习曲线陡峭
- 小项目会过度设计
- 模板代码多

### 示例

```swift
// Entity
struct User {
    let id: String
    let name: String
}

// View Protocol
protocol UserViewProtocol: AnyObject {
    func showUser(_ user: User)
    func showLoading()
    func showError(_ message: String)
}

// Presenter Protocol
protocol UserPresenterProtocol {
    func viewDidLoad()
    func didTapEditButton()
}

// Interactor Protocol
protocol UserInteractorProtocol {
    func fetchUser(id: String) async throws -> User
}

// Router Protocol
protocol UserRouterProtocol {
    func navigateToEditUser(_ user: User)
}

// Presenter Implementation
class UserPresenter: UserPresenterProtocol {
    weak var view: UserViewProtocol?
    var interactor: UserInteractorProtocol!
    var router: UserRouterProtocol!
    
    private let userId: String
    private var user: User?
    
    init(userId: String) {
        self.userId = userId
    }
    
    func viewDidLoad() {
        view?.showLoading()
        
        Task {
            do {
                let user = try await interactor.fetchUser(id: userId)
                self.user = user
                await MainActor.run {
                    view?.showUser(user)
                }
            } catch {
                await MainActor.run {
                    view?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func didTapEditButton() {
        guard let user = user else { return }
        router.navigateToEditUser(user)
    }
}

// View Implementation
class UserViewController: UIViewController, UserViewProtocol {
    var presenter: UserPresenterProtocol!
    
    private let nameLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewDidLoad()
    }
    
    func showUser(_ user: User) {
        nameLabel.text = user.name
    }
    
    func showLoading() {
        // 显示加载指示器
    }
    
    func showError(_ message: String) {
        // 显示错误
    }
}

// Module Builder
class UserModule {
    static func build(userId: String) -> UIViewController {
        let view = UserViewController()
        let presenter = UserPresenter(userId: userId)
        let interactor = UserInteractor()
        let router = UserRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        router.viewController = view
        
        return view
    }
}
```

---

## Clean Architecture

### 概述
按依赖方向分层的架构，外层依赖内层，内层不知道外层。

### 结构

```
┌─────────────────────────────────┐
│   Presentation Layer            │  ← Views, ViewModels
│   (UI, ViewModels)              │
├─────────────────────────────────┤
│   Domain Layer                  │  ← Use Cases, Entities
│   (Business Logic)              │
├─────────────────────────────────┤
│   Data Layer                    │  ← Repositories, API, DB
│   (Data Sources)                │
└─────────────────────────────────┘

依赖方向: Presentation → Domain ← Data
```

### 适用场景
- 大型复杂应用
- 需要支持多平台（iOS/macOS/watchOS）
- 业务逻辑复杂且频繁变化
- 长期维护的项目

### 优点
- 业务逻辑完全独立
- 易于替换技术栈
- 最高的可测试性
- 清晰的依赖规则

### 缺点
- 概念抽象，学习成本高
- 大量的协议和抽象层
- 小项目会显得繁重

### 示例

```swift
// Domain Layer - Entity
struct User {
    let id: String
    let name: String
    let email: String
}

// Domain Layer - Repository Protocol
protocol UserRepositoryProtocol {
    func getUser(id: String) async throws -> User
    func saveUser(_ user: User) async throws
}

// Domain Layer - Use Case
protocol FetchUserUseCaseProtocol {
    func execute(userId: String) async throws -> User
}

class FetchUserUseCase: FetchUserUseCaseProtocol {
    private let repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(userId: String) async throws -> User {
        // 这里可以添加业务规则
        let user = try await repository.getUser(id: userId)
        
        // 验证业务规则
        guard !user.email.isEmpty else {
            throw UserError.invalidEmail
        }
        
        return user
    }
}

// Data Layer - API Models
struct UserDTO: Codable {
    let id: String
    let name: String
    let email: String
}

// Data Layer - Repository Implementation
class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient
    private let localStorage: LocalStorage
    
    init(apiClient: APIClient, localStorage: LocalStorage) {
        self.apiClient = apiClient
        self.localStorage = localStorage
    }
    
    func getUser(id: String) async throws -> User {
        // 先尝试从本地获取
        if let cachedUser = try? localStorage.getUser(id: id) {
            return cachedUser
        }
        
        // 从API获取
        let dto = try await apiClient.fetchUser(id: id)
        let user = dto.toDomain()
        
        // 缓存
        try? localStorage.saveUser(user)
        
        return user
    }
    
    func saveUser(_ user: User) async throws {
        let dto = UserDTO(from: user)
        try await apiClient.updateUser(dto)
        try localStorage.saveUser(user)
    }
}

// Presentation Layer - ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fetchUserUseCase: FetchUserUseCaseProtocol
    private let userId: String
    
    init(userId: String, fetchUserUseCase: FetchUserUseCaseProtocol) {
        self.userId = userId
        self.fetchUserUseCase = fetchUserUseCase
    }
    
    func loadUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await fetchUserUseCase.execute(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// Dependency Injection Container
class DIContainer {
    static let shared = DIContainer()
    
    // Data Layer
    private lazy var apiClient = APIClient()
    private lazy var localStorage = LocalStorage()
    
    // Repositories
    func makeUserRepository() -> UserRepositoryProtocol {
        UserRepository(apiClient: apiClient, localStorage: localStorage)
    }
    
    // Use Cases
    func makeFetchUserUseCase() -> FetchUserUseCaseProtocol {
        FetchUserUseCase(repository: makeUserRepository())
    }
    
    // ViewModels
    func makeUserViewModel(userId: String) -> UserViewModel {
        UserViewModel(userId: userId, fetchUserUseCase: makeFetchUserUseCase())
    }
}
```

---

## Coordinator Pattern

### 概述
专门处理导航逻辑，将路由职责从View Controller中分离。

### 适用场景
- 复杂的导航流程
- 需要统一管理路由
- 深度链接处理
- 常与MVVM配合使用

### 优点
- View Controller不再负责导航
- 便于实现复杂的导航流程
- 易于处理深度链接
- 导航逻辑可测试

### 示例

```swift
// Coordinator Protocol
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

// App Coordinator
class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showLogin()
    }
    
    func showLogin() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        loginCoordinator.parentCoordinator = self
        childCoordinators.append(loginCoordinator)
        loginCoordinator.start()
    }
    
    func loginDidComplete() {
        childCoordinators.removeAll()
        showMainTab()
    }
    
    func showMainTab() {
        let mainCoordinator = MainTabCoordinator(navigationController: navigationController)
        mainCoordinator.parentCoordinator = self
        childCoordinators.append(mainCoordinator)
        mainCoordinator.start()
    }
}

// Feature Coordinator
class UserProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var parentCoordinator: Coordinator?
    
    private let userId: String
    
    init(navigationController: UINavigationController, userId: String) {
        self.navigationController = navigationController
        self.userId = userId
    }
    
    func start() {
        let viewModel = UserViewModel(userId: userId, coordinator: self)
        let viewController = UserViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showEditProfile() {
        let editCoordinator = EditProfileCoordinator(
            navigationController: navigationController,
            userId: userId
        )
        editCoordinator.parentCoordinator = self
        childCoordinators.append(editCoordinator)
        editCoordinator.start()
    }
    
    func editProfileDidFinish() {
        childCoordinators.removeAll()
    }
}

// ViewModel with Coordinator
class UserViewModel {
    private let userId: String
    private weak var coordinator: UserProfileCoordinator?
    
    init(userId: String, coordinator: UserProfileCoordinator) {
        self.userId = userId
        self.coordinator = coordinator
    }
    
    func didTapEditButton() {
        coordinator?.showEditProfile()
    }
}
```

---

## 架构对比

| 架构 | 复杂度 | 可测试性 | 学习曲线 | 适用规模 | 代码量 |
|------|--------|----------|----------|----------|--------|
| MVC | ⭐ | ⭐ | ⭐ | 小型 | 少 |
| MVVM | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | 小-中型 | 中 |
| MVVM+Coordinator | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 中型 | 中 |
| VIPER | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 大型 | 多 |
| Clean Architecture | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 大型/企业级 | 非常多 |

### 选择建议

**快速原型/MVP**
→ MVC 或 简化的MVVM

**产品型应用（持续迭代）**
→ MVVM + Coordinator

**大型团队项目**
→ VIPER 或 Clean Architecture

**跨平台业务逻辑**
→ Clean Architecture

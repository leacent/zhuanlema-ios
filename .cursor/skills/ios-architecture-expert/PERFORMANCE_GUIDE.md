# iOS 性能优化完整指南

本文档提供iOS应用性能优化的详细策略和最佳实践。

## 目录

- [启动性能优化](#启动性能优化)
- [内存管理](#内存管理)
- [渲染性能](#渲染性能)
- [网络性能](#网络性能)
- [电池续航优化](#电池续航优化)
- [性能监控工具](#性能监控工具)

---

## 启动性能优化

### 启动阶段分析

```
Total Launch Time = Pre-main + main() + First Frame
```

**Pre-main阶段** (系统负责)
- 加载dylib动态库
- Rebase和Binding
- ObjC Runtime初始化
- Initializers (+load方法)

**main()阶段** (开发者负责)
- `application:didFinishLaunchingWithOptions:`
- Root View Controller初始化
- 关键服务初始化

**First Frame阶段** (开发者负责)
- 首页数据加载
- 首页UI渲染

### 性能目标

| 启动类型 | 目标时间 | 用户感知 |
|---------|---------|---------|
| Cold Launch | < 400ms | 快速 |
| Warm Launch | < 200ms | 即时 |
| Resume | < 100ms | 无感知 |

### Pre-main优化

```swift
// ❌ 避免：+load方法执行耗时操作
@objc class MyClass: NSObject {
    override class func load() {
        // 这会阻塞启动
        setupDatabase()
        initializeCache()
    }
}

// ✅ 推荐：使用+initialize或延迟初始化
@objc class MyClass: NSObject {
    static let shared: MyClass = {
        let instance = MyClass()
        instance.setup()
        return instance
    }()
    
    private func setup() {
        // 首次使用时才执行
    }
}
```

**减少动态库数量**
```bash
# 查看app使用的动态库
otool -L YourApp.app/YourApp

# 优化策略：
# 1. 合并小的动态库
# 2. 将不常用的库改为静态链接
# 3. 移除未使用的framework
```

### main()优化

```swift
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // ✅ 优先级1: 关键路径 - 同步执行
    setupWindow()
    
    // ✅ 优先级2: 重要但不紧急 - 下一个RunLoop
    DispatchQueue.main.async {
        self.setupAnalytics()
        self.setupCrashReporting()
        self.setupPushNotifications()
    }
    
    // ✅ 优先级3: 可延迟 - 后台队列
    DispatchQueue.global(qos: .utility).async {
        self.preloadCache()
        self.setupNonCriticalSDKs()
    }
    
    // ✅ 优先级4: 首页展示后 - 监听通知
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(firstFrameRendered),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
    )
    
    return true
}

@objc private func firstFrameRendered() {
    // 首屏展示后执行
    DispatchQueue.global(qos: .background).async {
        self.cleanupTempFiles()
        self.updateAppConfiguration()
    }
}
```

**任务优先级决策树**
```
是否影响首页显示？
├─ 是 → 是否必须在main()中完成？
│       ├─ 是 → 同步执行（但需优化速度）
│       └─ 否 → 下一个RunLoop (DispatchQueue.main.async)
└─ 否 → 是否需要用户交互？
        ├─ 是 → 后台线程 (.utility)
        └─ 否 → 延迟到首帧后 (.background)
```

### 延迟加载策略

```swift
/// 延迟初始化管理器
class LaunchTaskManager {
    static let shared = LaunchTaskManager()
    
    private var pendingTasks: [LaunchTask] = []
    private var hasFirstFrameRendered = false
    
    func registerTask(_ task: LaunchTask) {
        if hasFirstFrameRendered {
            executeTask(task)
        } else {
            pendingTasks.append(task)
        }
    }
    
    func notifyFirstFrameRendered() {
        hasFirstFrameRendered = true
        executePendingTasks()
    }
    
    private func executePendingTasks() {
        let sortedTasks = pendingTasks.sorted { $0.priority > $1.priority }
        
        for task in sortedTasks {
            DispatchQueue.global(qos: task.qos).async {
                task.execute()
            }
        }
        
        pendingTasks.removeAll()
    }
}

struct LaunchTask {
    let name: String
    let priority: Int
    let qos: DispatchQoS.QoSClass
    let execute: () -> Void
}

// 使用示例
LaunchTaskManager.shared.registerTask(
    LaunchTask(
        name: "Database Cleanup",
        priority: 5,
        qos: .background,
        execute: { DatabaseManager.shared.cleanup() }
    )
)
```

### 首屏优化

```swift
/// 首页ViewController优化
class HomeViewController: UIViewController {
    
    // ✅ 使用懒加载
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(FeedCell.self, forCellReuseIdentifier: "FeedCell")
        return table
    }()
    
    // ✅ 数据预加载
    private var cachedData: [FeedItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ✅ 先展示缓存数据（如果有）
        if let cached = DataCache.shared.getCachedFeed() {
            self.cachedData = cached
            self.tableView.reloadData()
        }
        
        // ✅ 后台刷新最新数据
        Task {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        do {
            let freshData = try await APIService.fetchFeed()
            self.cachedData = freshData
            
            await MainActor.run {
                self.tableView.reloadData()
            }
            
            DataCache.shared.saveFeed(freshData)
        } catch {
            print("Failed to refresh: \(error)")
        }
    }
}
```

---

## 内存管理

### 内存问题类型

1. **内存泄漏** - 对象无法释放
2. **内存峰值** - 短时间内存暴增
3. **内存持续增长** - 缓存未清理
4. **低内存警告** - 系统内存不足

### 避免循环引用

```swift
// ❌ 循环引用示例
class ViewController: UIViewController {
    var viewModel: ViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.onDataLoaded = {
            // self被closure强引用
            self.updateUI()
        }
    }
}

// ✅ 使用weak打破循环
class ViewController: UIViewController {
    var viewModel: ViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.onDataLoaded = { [weak self] in
            self?.updateUI()
        }
    }
}

// ✅ 使用unowned（确定self不会为nil时）
viewModel?.onDataLoaded = { [unowned self] in
    self.updateUI()
}
```

**常见循环引用场景**

```swift
// 1. Timer循环引用
class MyViewController: UIViewController {
    var timer: Timer?
    
    // ❌ 错误：timer强引用self
    func startTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerFired),
            userInfo: nil,
            repeats: true
        )
    }
    
    // ✅ 解决方案1：使用weak包装
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerFired()
        }
    }
    
    // ✅ 解决方案2：手动停止timer
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// 2. Notification循环引用
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ❌ 如果使用closure，注意weak self
        NotificationCenter.default.addObserver(
            forName: .someNotification,
            object: nil,
            queue: .main
        ) { notification in
            // 需要 [weak self]
            self.handleNotification()
        }
    }
    
    // ✅ 推荐：使用selector（系统自动管理）
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: .someNotification,
            object: nil
        )
    }
}

// 3. Delegate循环引用
protocol DataSourceDelegate: AnyObject {
    func dataDidUpdate()
}

class DataSource {
    // ✅ 使用weak避免循环引用
    weak var delegate: DataSourceDelegate?
}
```

### 图片内存优化

```swift
/// 图片加载器 - 智能内存管理
class ImageLoader {
    static let shared = ImageLoader()
    
    private let cache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    
    init() {
        // 设置缓存大小限制
        cache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
        cache.countLimit = 100  // 最多100张图片
    }
    
    /// 加载图片并调整到目标尺寸
    func loadImage(url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(url.absoluteString)-\(targetSize)" as NSString
        
        // 检查缓存
        if let cached = cache.object(forKey: cacheKey) {
            completion(cached)
            return
        }
        
        // 下载图片
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let originalImage = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            // ✅ 调整图片尺寸，降低内存占用
            let resizedImage = originalImage.resized(to: targetSize)
            
            // 缓存调整后的图片
            let cost = Int(targetSize.width * targetSize.height * 4)  // RGBA
            self?.cache.setObject(resizedImage, forKey: cacheKey, cost: cost)
            
            DispatchQueue.main.async {
                completion(resizedImage)
            }
        }.resume()
    }
}

extension UIImage {
    /// 调整图片大小
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// 降采样加载大图片
    static func downsample(imageAt url: URL, to targetSize: CGSize) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height)
        ]
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: image)
    }
}
```

### 内存警告处理

```swift
class AppMemoryManager {
    static let shared = AppMemoryManager()
    
    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        // 清理缓存
        ImageCache.shared.clearMemoryCache()
        DataCache.shared.clearMemoryCache()
        
        // 释放非必要资源
        releaseNonEssentialResources()
        
        // 记录内存警告
        Analytics.log(event: "memory_warning", properties: [
            "memory_used": memoryUsage(),
            "timestamp": Date()
        ])
    }
    
    private func memoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
```

---

## 渲染性能

### 目标帧率

| 设备 | 目标帧率 | 每帧时间预算 |
|------|---------|-------------|
| 标准设备 | 60 FPS | 16.67ms |
| ProMotion设备 | 120 FPS | 8.33ms |

### 主线程优化

```swift
// ❌ 主线程阻塞
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    // 耗时操作阻塞主线程
    let processedData = heavyDataProcessing(items[indexPath.row])  // 50ms
    cell.textLabel?.text = processedData
    
    return cell
}

// ✅ 后台处理数据
class FeedViewModel {
    private(set) var displayItems: [DisplayItem] = []
    
    func loadData(items: [RawItem]) async {
        // 后台线程处理
        let processed = await withTaskGroup(of: DisplayItem.self) { group in
            for item in items {
                group.addTask {
                    return await self.processItem(item)
                }
            }
            
            var results: [DisplayItem] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // 回到主线程更新UI
        await MainActor.run {
            self.displayItems = processed
        }
    }
    
    private func processItem(_ item: RawItem) async -> DisplayItem {
        // 耗时的数据处理
        return DisplayItem(from: item)
    }
}
```

### 离屏渲染优化

```swift
// ❌ 触发离屏渲染的设置
view.layer.cornerRadius = 10
view.layer.masksToBounds = true
view.layer.shadowOpacity = 0.5  // 同时设置阴影

// ✅ 优化方案1：使用shadowPath
view.layer.cornerRadius = 10
view.layer.shadowOpacity = 0.5
view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: 10).cgPath
view.layer.shouldRasterize = true  // 光栅化缓存
view.layer.rasterizationScale = UIScreen.main.scale

// ✅ 优化方案2：使用图片
let roundedImage = UIImage(named: "rounded_background")
imageView.image = roundedImage

// ✅ 优化方案3：自定义绘制
class RoundedView: UIView {
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 10)
        UIColor.white.setFill()
        path.fill()
    }
}
```

### Cell优化

```swift
/// 高性能Cell实现
class OptimizedFeedCell: UITableViewCell {
    // ✅ 使用不透明视图
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // 设置不透明提升性能
        contentView.isOpaque = true
        contentView.backgroundColor = .white
        
        setupUI()
    }
    
    // ✅ 避免重复创建视图
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        return iv
    }()
    
    // ✅ 使用异步图片加载
    func configure(with item: FeedItem) {
        titleLabel.text = item.title
        
        // 取消之前的图片加载任务
        imageLoadTask?.cancel()
        
        // 异步加载图片
        imageLoadTask = Task {
            let image = await ImageLoader.shared.load(url: item.imageURL)
            
            // 检查cell是否被重用
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.avatarImageView.image = image
            }
        }
    }
    
    // ✅ 重用时清理
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImageView.image = nil
        imageLoadTask?.cancel()
        imageLoadTask = nil
    }
    
    private var imageLoadTask: Task<Void, Never>?
}

// ✅ 实现prefetching
extension FeedViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = viewModel.items[indexPath.row]
            
            // 预加载图片
            ImageLoader.shared.prefetch(url: item.imageURL)
            
            // 预处理数据
            viewModel.prepareItem(at: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = viewModel.items[indexPath.row]
            ImageLoader.shared.cancelPrefetch(url: item.imageURL)
        }
    }
}
```

### 自动布局优化

```swift
// ❌ 性能差：频繁计算约束
class SlowCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 每次都重新计算
        titleLabel.frame = CGRect(x: 16, y: 8, width: bounds.width - 32, height: 30)
        imageView.frame = CGRect(x: 16, y: 46, width: 80, height: 80)
    }
}

// ✅ 性能好：缓存约束
class FastCell: UITableViewCell {
    private var didSetupConstraints = false
    
    override func updateConstraints() {
        if !didSetupConstraints {
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                titleLabel.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            didSetupConstraints = true
        }
        
        super.updateConstraints()
    }
}

// ✅ 更快：手动布局
class ManualLayoutCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 直接设置frame，无约束计算开销
        let width = bounds.width
        titleLabel.frame = CGRect(x: 16, y: 8, width: width - 32, height: 30)
        avatarImageView.frame = CGRect(x: 16, y: 46, width: 60, height: 60)
    }
}
```

---

## 网络性能

### 请求优化

```swift
/// 网络请求管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let cache = URLCache(
        memoryCapacity: 20 * 1024 * 1024,   // 20 MB
        diskCapacity: 100 * 1024 * 1024,    // 100 MB
        diskPath: "network_cache"
    )
    
    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 30
        config.httpMaximumConnectionsPerHost = 4  // 限制并发连接数
        
        session = URLSession(configuration: config)
    }
    
    // ✅ 支持取消的请求
    func fetch<T: Decodable>(url: URL) -> Task<T, Error> {
        Task {
            let (data, _) = try await session.data(from: url)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
}

// ✅ 请求合并
class BatchRequestManager {
    private var pendingRequests: [String: [(Result<User, Error>) -> Void]] = [:]
    private var batchTimer: Timer?
    
    func fetchUser(id: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            // 收集相同时间段的请求
            if pendingRequests[id] == nil {
                pendingRequests[id] = []
            }
            
            pendingRequests[id]?.append { result in
                continuation.resume(with: result)
            }
            
            // 延迟100ms合并请求
            batchTimer?.invalidate()
            batchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.executeBatch()
            }
        }
    }
    
    private func executeBatch() {
        let userIds = Array(pendingRequests.keys)
        let callbacks = pendingRequests
        pendingRequests.removeAll()
        
        // 批量请求
        Task {
            do {
                let users = try await APIService.fetchUsers(ids: userIds)
                
                for user in users {
                    if let callbacks = callbacks[user.id] {
                        for callback in callbacks {
                            callback(.success(user))
                        }
                    }
                }
            } catch {
                for callbacks in callbacks.values {
                    for callback in callbacks {
                        callback(.failure(error))
                    }
                }
            }
        }
    }
}
```

### 数据压缩

```swift
// ✅ 请求gzip压缩
var request = URLRequest(url: url)
request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")

// ✅ 发送压缩数据
extension Data {
    func compressed() throws -> Data {
        return try (self as NSData).compressed(using: .zlib) as Data
    }
    
    func decompressed() throws -> Data {
        return try (self as NSData).decompressed(using: .zlib) as Data
    }
}
```

---

## 电池续航优化

### 定位服务优化

```swift
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    func startTracking() {
        locationManager.delegate = self
        
        // ✅ 根据需求选择精度
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters  // 而非 kCLLocationAccuracyBest
        
        // ✅ 设置距离过滤
        locationManager.distanceFilter = 100  // 100米变化才更新
        
        // ✅ 使用显著位置变化（更省电）
        locationManager.startMonitoringSignificantLocationChanges()
        
        // 而非持续更新
        // locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
}
```

### 后台任务优化

```swift
// ✅ 使用BGTaskScheduler代替旧API
class BackgroundTaskManager {
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15分钟后
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()  // 重新调度
        
        let operation = RefreshOperation()
        
        task.expirationHandler = {
            operation.cancel()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        operationQueue.addOperation(operation)
    }
}
```

---

## 性能监控工具

### Instruments使用

**Time Profiler** - CPU性能分析
```
1. Product → Profile (⌘I)
2. 选择 Time Profiler
3. 录制并操作app
4. 查看调用栈，找到耗时方法
```

**Allocations** - 内存分配
```
1. Product → Profile → Allocations
2. 筛选 "All Heap & Anonymous VM"
3. 查找内存增长异常的对象
```

**Leaks** - 内存泄漏
```
1. Product → Profile → Leaks
2. 查找红色标记的泄漏
3. 检查引用循环
```

### 代码埋点监控

```swift
/// 性能监控工具
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    /// 监控方法执行时间
    func measure(_ name: String, block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        if duration > 0.016 {  // 超过1帧时间
            print("⚠️ \(name) took \(duration * 1000)ms")
            
            // 上报到分析平台
            Analytics.log(event: "slow_operation", properties: [
                "name": name,
                "duration": duration
            ])
        }
    }
    
    /// 监控帧率
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    func startMonitoringFPS() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func tick(_ displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            let fps = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = displayLink.timestamp
            
            if fps < 55 {  // 低于55fps
                print("⚠️ Low FPS: \(fps)")
            }
        }
    }
}

// 使用示例
PerformanceMonitor.shared.measure("Data Processing") {
    processLargeDataSet()
}
```

### 启动时间监控

```swift
// 在AppDelegate中
var appStartTime: CFAbsoluteTime = 0

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    let launchDuration = CFAbsoluteTimeGetCurrent() - appStartTime
    print("App launch took \(launchDuration * 1000)ms")
    
    // 上报数据
    Analytics.log(event: "app_launch", properties: [
        "duration": launchDuration,
        "is_cold_start": true
    ])
    
    return true
}

// 在main.swift中记录启动时间
appStartTime = CFAbsoluteTimeGetCurrent()
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
```

---

## 性能优化Checklist

### 启动性能
- [ ] Pre-main时间 < 200ms
- [ ] 总启动时间 < 400ms (Cold Launch)
- [ ] 关键服务延迟初始化
- [ ] 减少+load方法使用
- [ ] 移除未使用的动态库

### 内存
- [ ] 无内存泄漏
- [ ] 内存峰值 < 设备限制的70%
- [ ] 正确处理内存警告
- [ ] 图片适当压缩和缓存
- [ ] 缓存有大小限制

### 渲染
- [ ] 列表滚动60fps
- [ ] 避免主线程阻塞
- [ ] 减少离屏渲染
- [ ] Cell正确重用
- [ ] 实现prefetching

### 网络
- [ ] 启用缓存策略
- [ ] 请求超时设置合理
- [ ] 支持请求取消
- [ ] 合并相似请求
- [ ] 使用compression

### 电池
- [ ] 定位精度合理
- [ ] 后台任务最小化
- [ ] 避免polling，使用push
- [ ] Timer使用得当

/**
 * 行情数据服务
 * 负责从腾讯财经API获取实时行情数据
 * 提供大盘指数、个股行情、榜单等功能
 */
import Foundation

/// 行情数据服务错误类型
enum MarketDataError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parseError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .networkError(let error):
            return "网络请求失败: \(error.localizedDescription)"
        case .parseError:
            return "数据解析失败"
        case .noData:
            return "无数据返回"
        }
    }
}

class MarketDataService {
    
    /// 单例
    static let shared = MarketDataService()
    
    /// URL会话
    private let session: URLSession
    
    /// 初始化
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 公开方法
    
    /// 获取大盘指数数据（默认 A股，兼容旧逻辑）
    /// - Returns: 指数数组
    func fetchIndices() async throws -> [MarketIndex] {
        try await fetchIndices(region: .aShare)
    }

    /// 按市场区域获取大盘指数数据
    /// - Parameter region: 市场区域（A股/港股/美股）
    /// - Returns: 指数数组
    func fetchIndices(region: MarketRegion) async throws -> [MarketIndex] {
        let codes = TencentFinanceAPI.indicesCodes(for: region)

        guard let url = TencentFinanceAPI.quoteURL(codes: codes) else {
            throw MarketDataError.invalidURL
        }

        let rawData = try await fetchRawData(from: url)
        let parsedData = TencentFinanceAPI.parseResponse(rawData)

        return parsedData.compactMap { dict -> MarketIndex? in
            guard let code = dict["code"],
                  let name = dict["name"],
                  !name.isEmpty,
                  let currentStr = dict["current"],
                  let current = Double(currentStr) else {
                return nil
            }
            // 确保涨跌幅解析失败时默认为 0，而不是直接丢弃整条数据
            let changePercent = dict["changePercent"].flatMap { Double($0) } ?? 0

            return MarketIndex(
                id: code,
                name: name,
                code: code,
                value: current,
                changePercent: changePercent
            )
        }
    }
    
    /// 获取热门股票（涨跌榜）
    /// 优先通过 CloudBase 云函数获取东方财富全量排行（支持 A股/港股/美股），失败时 A股 回退腾讯
    /// - Parameters type: 榜单类型, region: 市场区域
    /// - Returns: 股票列表
    func fetchHotStocks(type: HotStockType, region: MarketRegion) async throws -> [WatchlistItem] {
        do {
            let list = try await CloudBaseDatabaseService.shared.getHotStocks(type: type, region: region)
            if !list.isEmpty {
                return list
            }
        } catch {
            print("⚠️ [MarketDataService] CloudBase 排行榜失败: \(error.localizedDescription)")
        }
        
        // 仅 A 股回退腾讯固定列表；港股/美股无腾讯回退
        guard region == .aShare else {
            return []
        }
        
        let codes = TencentFinanceAPI.getRankingCodes(type: type)
        guard let url = TencentFinanceAPI.quoteURL(codes: codes) else {
            throw MarketDataError.invalidURL
        }
        do {
            let rawData = try await fetchRawData(from: url)
            let parsedData = TencentFinanceAPI.parseResponse(rawData)
            var items = parsedData.compactMap { dict -> WatchlistItem? in
                guard let code = dict["code"],
                      let name = dict["name"],
                      !name.isEmpty else { return nil }
                let price = dict["current"].flatMap { Double($0) }
                let changePercent = dict["changePercent"].flatMap { Double($0) }
                let volume = dict["volume"].flatMap { Int64($0) }
                return WatchlistItem(id: code, name: name, code: code, price: price, changePercent: changePercent, volume: volume)
            }
            switch type {
            case .gainers: items.sort { ($0.changePercent ?? 0) > ($1.changePercent ?? 0) }
            case .losers: items.sort { ($0.changePercent ?? 0) < ($1.changePercent ?? 0) }
            case .active: items.sort { ($0.volume ?? 0) > ($1.volume ?? 0) }
            }
            return items
        } catch {
            print("获取排行榜失败: \(error.localizedDescription)")
            return getMockHotStocks(type: type)
        }
    }
    
    /// 获取模拟排行榜数据
    /// - Parameter type: 榜单类型
    /// - Returns: 模拟股票列表
    private func getMockHotStocks(type: HotStockType) -> [WatchlistItem] {
        switch type {
        case .gainers:
            return [
                WatchlistItem(id: "1", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 5.62, volume: 2_340_000),
                WatchlistItem(id: "2", name: "五粮液", code: "sz000858", price: 156.32, changePercent: 4.89, volume: 5_120_000),
                WatchlistItem(id: "3", name: "宁德时代", code: "sz300750", price: 218.45, changePercent: 4.25, volume: 8_900_000),
                WatchlistItem(id: "4", name: "比亚迪", code: "sz002594", price: 256.78, changePercent: 3.98, volume: 6_780_000),
                WatchlistItem(id: "5", name: "招商银行", code: "sh600036", price: 32.56, changePercent: 3.45, volume: 12_300_000),
                WatchlistItem(id: "6", name: "中国平安", code: "sh601318", price: 48.90, changePercent: 2.89, volume: 18_900_000),
                WatchlistItem(id: "7", name: "美的集团", code: "sz000333", price: 58.23, changePercent: 2.56, volume: 7_650_000),
                WatchlistItem(id: "8", name: "隆基绿能", code: "sh601012", price: 28.45, changePercent: 2.12, volume: 9_870_000),
                WatchlistItem(id: "9", name: "恒瑞医药", code: "sh600276", price: 42.36, changePercent: 1.89, volume: 4_560_000),
                WatchlistItem(id: "10", name: "东方财富", code: "sz300059", price: 18.92, changePercent: 1.56, volume: 15_600_000)
            ]
        case .losers:
            return [
                WatchlistItem(id: "1", name: "工商银行", code: "sh601398", price: 4.85, changePercent: -2.42, volume: 45_600_000),
                WatchlistItem(id: "2", name: "农业银行", code: "sh601288", price: 3.52, changePercent: -2.21, volume: 38_900_000),
                WatchlistItem(id: "3", name: "建设银行", code: "sh601939", price: 6.28, changePercent: -1.89, volume: 28_700_000),
                WatchlistItem(id: "4", name: "中国银行", code: "sh601988", price: 3.68, changePercent: -1.61, volume: 32_400_000),
                WatchlistItem(id: "5", name: "中国石油", code: "sh601857", price: 7.85, changePercent: -1.38, volume: 25_600_000),
                WatchlistItem(id: "6", name: "中国石化", code: "sh600028", price: 5.12, changePercent: -1.15, volume: 18_900_000),
                WatchlistItem(id: "7", name: "中国神华", code: "sh601088", price: 32.45, changePercent: -0.92, volume: 8_760_000),
                WatchlistItem(id: "8", name: "长江电力", code: "sh600900", price: 25.68, changePercent: -0.78, volume: 6_540_000),
                WatchlistItem(id: "9", name: "中国建筑", code: "sh601668", price: 5.62, changePercent: -0.53, volume: 15_200_000),
                WatchlistItem(id: "10", name: "中国电建", code: "sh601669", price: 4.28, changePercent: -0.46, volume: 12_300_000)
            ]
        case .active:
            return [
                WatchlistItem(id: "1", name: "东方财富", code: "sz300059", price: 18.92, changePercent: 1.56, volume: 156_000_000),
                WatchlistItem(id: "2", name: "工商银行", code: "sh601398", price: 4.85, changePercent: -0.42, volume: 145_600_000),
                WatchlistItem(id: "3", name: "比亚迪", code: "sz002594", price: 256.78, changePercent: 3.98, volume: 98_700_000),
                WatchlistItem(id: "4", name: "宁德时代", code: "sz300750", price: 218.45, changePercent: 4.25, volume: 89_000_000),
                WatchlistItem(id: "5", name: "中国平安", code: "sh601318", price: 48.90, changePercent: 2.89, volume: 78_900_000),
                WatchlistItem(id: "6", name: "招商银行", code: "sh600036", price: 32.56, changePercent: 3.45, volume: 72_300_000),
                WatchlistItem(id: "7", name: "贵州茅台", code: "sh600519", price: 1688.50, changePercent: 5.62, volume: 65_400_000),
                WatchlistItem(id: "8", name: "立讯精密", code: "sz002475", price: 28.56, changePercent: 2.12, volume: 58_700_000),
                WatchlistItem(id: "9", name: "美的集团", code: "sz000333", price: 58.23, changePercent: 2.56, volume: 52_600_000),
                WatchlistItem(id: "10", name: "隆基绿能", code: "sh601012", price: 28.45, changePercent: 2.12, volume: 48_700_000)
            ]
        }
    }
    
    /// 搜索股票（代码直查 → 远程联想 → 本地股票池回退）
    /// 选中后通过腾讯公开行情接口 http://qt.gtimg.cn/q=代码 拉取实时报价。
    /// - Parameter keyword: 用户输入的关键词（名称或代码，如 300436、贵州茅台）
    /// - Returns: 匹配的股票列表
    func searchStocks(keyword: String) async -> [WatchlistItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // 1) 纯数字代码：用腾讯行情接口直查（支持全市场，如 300436）
        if let byCode = await searchByCodeDirect(keyword: trimmed), !byCode.isEmpty {
            return byCode
        }
        
        // 2) 远程联想（名称/拼音等）
        do {
            let remote = try await searchStocksRemote(keyword: trimmed)
            if !remote.isEmpty { return remote }
        } catch {
            print("⚠️ [MarketDataService] 远程联想失败: \(error.localizedDescription)")
        }
        
        // 3) 本地股票池回退
        return searchStocksLocal(keyword: trimmed)
    }
    
    /// 代码直查：A 股（6 位数字）/ 港股（4～5 位数字）/ 美股（字母代号），用腾讯行情接口
    private func searchByCodeDirect(keyword: String) async -> [WatchlistItem]? {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return nil }
        
        let digits = trimmed.filter { $0.isNumber }
        let lettersOrSymbols = trimmed.filter { $0.isLetter || $0 == "." }
        
        var toTry: [String] = []
        
        if digits == trimmed {
            // 纯数字：6 位 → A 股，3～5 位 → 港股
            if digits.count == 6 {
                let code6 = String(digits.prefix(6)).padding(toLength: 6, withPad: "0", startingAt: 0)
                toTry = TencentFinanceAPI.possibleQuoteCodes(for: code6)
            } else if digits.count >= 3, digits.count <= 5 {
                toTry = TencentFinanceAPI.possibleQuoteCodesHK(digits: String(digits))
            }
        } else if lettersOrSymbols.count >= 1, trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "." }) {
            // 含字母：美股代号，如 AAPL、BRK.B
            toTry = TencentFinanceAPI.possibleQuoteCodesUS(ticker: trimmed)
        }
        
        guard !toTry.isEmpty else { return nil }
        do {
            let list = try await fetchStockData(codes: toTry)
            let valid = list.filter { !$0.name.isEmpty && $0.name != "null" && $0.name != "-" }
            return valid.isEmpty ? nil : valid
        } catch {
            return nil
        }
    }
    
    /// 远程股票联想（腾讯 smartbox 等）
    private func searchStocksRemote(keyword: String) async throws -> [WatchlistItem] {
        guard let url = TencentFinanceAPI.suggestURL(keyword: keyword) else {
            return []
        }
        let rawData = try await fetchRawData(from: url)
        let parsed = TencentFinanceAPI.parseSuggestResponse(rawData)
        return parsed.map { name, code in
            WatchlistItem(id: code, name: name, code: code, price: nil, changePercent: nil, volume: nil)
        }
    }
    
    /// 本地股票池过滤（仅 A 股常用标的，用作远程不可用时的回退）
    /// - Parameter keyword: 用户输入的关键词
    /// - Returns: 匹配的股票列表
    func searchStocksLocal(keyword: String) -> [WatchlistItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        return Self.searchableStockList.filter { item in
            item.name.contains(trimmed) ||
            item.displayCode.contains(trimmed) ||
            item.code.lowercased().contains(lower)
        }
    }

    /// 可搜索的 A 股股票池（代码 + 名称）
    private static let searchableStockList: [WatchlistItem] = {
        let tuples: [(String, String)] = [
            ("sh600519", "贵州茅台"), ("sz000858", "五粮液"), ("sh601318", "中国平安"),
            ("sz300750", "宁德时代"), ("sh600036", "招商银行"), ("sz000333", "美的集团"),
            ("sh601012", "隆基绿能"), ("sz002594", "比亚迪"), ("sh600276", "恒瑞医药"),
            ("sz300059", "东方财富"), ("sh601398", "工商银行"), ("sh601288", "农业银行"),
            ("sh601939", "建设银行"), ("sh601988", "中国银行"), ("sh601857", "中国石油"),
            ("sh600028", "中国石化"), ("sh601088", "中国神华"), ("sh600900", "长江电力"),
            ("sh601668", "中国建筑"), ("sh601669", "中国电建"), ("sz002475", "立讯精密"),
            ("sz000001", "平安银行"), ("sz000002", "万科A"), ("sh600000", "浦发银行"),
            ("sh600030", "中信证券"), ("sz300496", "中科创达"), ("sh688981", "中芯国际"),
            ("sz300274", "阳光电源"), ("sz002415", "海康威视"), ("sh600309", "万华化学"),
            ("sz300122", "智飞生物"), ("sh600436", "片仔癀"), ("sz300759", "康泰生物"),
        ]
        return tuples.map { WatchlistItem(id: $0.0, name: $0.1, code: $0.0, price: nil, changePercent: nil, volume: nil) }
    }()

    /// 批量获取股票数据（请求腾讯公开行情：http://qt.gtimg.cn/q=代码）
    /// - Parameter codes: 股票代码列表，如 ["sh600519", "sz000858"]
    /// - Returns: 股票数据列表（含名称、现价、涨跌幅等）
    func fetchStockData(codes: [String]) async throws -> [WatchlistItem] {
        guard !codes.isEmpty else { return [] }
        
        guard let url = TencentFinanceAPI.quoteURL(codes: codes) else {
            throw MarketDataError.invalidURL
        }
        
        let rawData = try await fetchRawData(from: url)
        let parsedData = TencentFinanceAPI.parseResponse(rawData)
        
        return parsedData.compactMap { dict -> WatchlistItem? in
            guard let code = dict["code"],
                  let name = dict["name"] else {
                return nil
            }
            
            let price = dict["current"].flatMap { Double($0) }
            let changePercent = dict["changePercent"].flatMap { Double($0) }
            let volume = dict["volume"].flatMap { Int64($0) }
            
            return WatchlistItem(
                id: code,
                name: name,
                code: code,
                price: price,
                changePercent: changePercent,
                volume: volume
            )
        }
    }
    
    // MARK: - 板块数据
    
    /// 获取行业板块数据
    /// - Parameter region: 市场区域（仅 A 股有数据，港股/美股返回空）
    func fetchIndustrySectors(region: MarketRegion) async throws -> [SectorItem] {
        return try await fetchSectors(type: .industry, region: region)
    }
    
    /// 获取概念板块数据
    /// - Parameter region: 市场区域（仅 A 股有数据）
    func fetchConceptSectors(region: MarketRegion) async throws -> [SectorItem] {
        return try await fetchSectors(type: .concept, region: region)
    }
    
    /// 获取板块数据
    /// 优先通过 CloudBase 云函数（东方财富）；仅 A 股有行业/概念，港股美股为空；失败时 A 股回退模拟
    private func fetchSectors(type: SectorType, region: MarketRegion) async throws -> [SectorItem] {
        do {
            let sectors = try await CloudBaseDatabaseService.shared.getSectorData(type: type, region: region)
            if !sectors.isEmpty {
                print("✅ [MarketDataService] CloudBase \(type.title) \(region.title): \(sectors.count) 条")
                return sectors
            }
            if region == .aShare {
                print("⚠️ [MarketDataService] CloudBase 返回空，使用模拟数据")
                return getMockSectors(type: type)
            }
            return []
        } catch {
            print("⚠️ [MarketDataService] CloudBase 板块失败: \(error.localizedDescription)")
            return region == .aShare ? getMockSectors(type: type) : []
        }
    }
    
    /// 获取模拟板块数据
    /// - Parameter type: 板块类型
    /// - Returns: 模拟板块列表
    private func getMockSectors(type: SectorType) -> [SectorItem] {
        if type == .industry {
            return [
                SectorItem(id: "hy001", name: "电力设备", changePercent: 3.25, leadingStock: "宁德时代", leadingStockChange: 5.62, volume: "356亿"),
                SectorItem(id: "hy002", name: "医药生物", changePercent: 2.18, leadingStock: "恒瑞医药", leadingStockChange: 4.33, volume: "289亿"),
                SectorItem(id: "hy003", name: "电子", changePercent: 1.95, leadingStock: "立讯精密", leadingStockChange: 3.89, volume: "412亿"),
                SectorItem(id: "hy004", name: "计算机", changePercent: 1.67, leadingStock: "中科曙光", leadingStockChange: 6.21, volume: "198亿"),
                SectorItem(id: "hy005", name: "汽车", changePercent: -0.52, leadingStock: "比亚迪", leadingStockChange: 1.25, volume: "267亿"),
                SectorItem(id: "hy006", name: "有色金属", changePercent: -1.23, leadingStock: "紫金矿业", leadingStockChange: -0.85, volume: "178亿")
            ]
        } else {
            return [
                SectorItem(id: "gn001", name: "人工智能", changePercent: 4.56, leadingStock: "科大讯飞", leadingStockChange: 8.92, volume: "523亿"),
                SectorItem(id: "gn002", name: "新能源车", changePercent: 3.12, leadingStock: "比亚迪", leadingStockChange: 5.67, volume: "412亿"),
                SectorItem(id: "gn003", name: "芯片概念", changePercent: 2.89, leadingStock: "中芯国际", leadingStockChange: 4.55, volume: "389亿"),
                SectorItem(id: "gn004", name: "光伏概念", changePercent: 2.45, leadingStock: "隆基绿能", leadingStockChange: 3.78, volume: "298亿"),
                SectorItem(id: "gn005", name: "储能", changePercent: 1.78, leadingStock: "阳光电源", leadingStockChange: 4.12, volume: "187亿"),
                SectorItem(id: "gn006", name: "华为概念", changePercent: -0.34, leadingStock: "华为海思", leadingStockChange: 1.56, volume: "156亿")
            ]
        }
    }
    
    // MARK: - 私有方法
    
    /// 从URL获取原始数据
    /// - Parameter url: 请求URL
    /// - Returns: 原始字符串数据
    private func fetchRawData(from url: URL) async throws -> String {
        do {
            let (data, _) = try await session.data(from: url)
            
            // 腾讯API返回GBK编码，需要转换
            guard let rawString = String(data: data, encoding: .utf8) ??
                                  convertGBKToUTF8(data: data) else {
                throw MarketDataError.parseError
            }
            
            guard !rawString.isEmpty else {
                throw MarketDataError.noData
            }
            
            return rawString
        } catch let error as MarketDataError {
            throw error
        } catch {
            throw MarketDataError.networkError(error)
        }
    }
    
    /// 将GBK编码数据转换为UTF-8字符串
    /// - Parameter data: 原始数据
    /// - Returns: UTF-8字符串
    private func convertGBKToUTF8(data: Data) -> String? {
        // GBK编码转换
        let cfEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        let encoding = String.Encoding(rawValue: cfEncoding)
        return String(data: data, encoding: encoding)
    }
}

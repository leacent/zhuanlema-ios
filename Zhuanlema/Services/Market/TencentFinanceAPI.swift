/**
 * 腾讯财经 API 封装
 * 使用腾讯公开行情接口：http://qt.gtimg.cn/q=代码
 * 用于个股/指数实时行情、股票搜索后拉取报价等。
 */
import Foundation

enum TencentFinanceAPI {
    /// 公开行情接口基础地址（腾讯 gtimg.cn）
    static let baseURL = "http://qt.gtimg.cn"

    /// 行情查询路径：/q=代码1,代码2,…
    static let quoteEndpoint = "/q="

    /// 构建行情请求 URL（公开接口，按代码查行情）
    /// - Parameter codes: 股票/指数代码，如 ["sh600519", "sz000858"]
    /// - Returns: 如 http://qt.gtimg.cn/q=sh600519,sz000858
    static func quoteURL(codes: [String]) -> URL? {
        let codesString = codes.joined(separator: ",")
        let urlString = "\(baseURL)\(quoteEndpoint)\(codesString)"
        return URL(string: urlString)
    }
    
    // MARK: - 股票搜索联想（远程）
    
    /// 腾讯智能搜索框（按关键词联想股票名称/代码，非官方文档，可能变动）
    /// 用于补全全市场搜索，请求失败时请回退到本地股票池。
    static let suggestBaseURL = "https://smartbox.gtimg.cn/s3/"
    
    /// 构建搜索联想请求 URL
    /// - Parameter keyword: 用户输入的关键词（名称或代码）
    /// - Returns: 如 https://smartbox.gtimg.cn/s3/?q=茅台
    static func suggestURL(keyword: String) -> URL? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents(string: suggestBaseURL)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        return components?.url
    }
    
    /// 根据 6 位数字代码推断可能的腾讯行情代码（A 股代码直查）
    /// A 股：沪 60/68/90/51、科创 68；深 00/30/002/003
    /// - Parameter code6: 6 位数字，如 "300436"、"600519"
    /// - Returns: 要请求的 code 列表，如 ["sz300436"] 或 ["sh600519"]
    static func possibleQuoteCodes(for code6: String) -> [String] {
        guard code6.count == 6 else { return [] }
        let prefix2 = String(code6.prefix(2))
        let prefix3 = String(code6.prefix(3))
        if prefix2 == "60" || prefix2 == "68" || prefix2 == "90" || prefix2 == "51" {
            return ["sh\(code6)"]
        }
        if prefix2 == "00" || prefix2 == "30" || prefix3 == "002" || prefix3 == "003" {
            return ["sz\(code6)"]
        }
        return ["sh\(code6)", "sz\(code6)"]
    }
    
    /// 港股代码直查：腾讯格式 hk + 5 位数字，如 hk00700、hk09988
    /// - Parameter digits: 3～5 位数字，如 "700"、"00700"、"9988"
    static func possibleQuoteCodesHK(digits: String) -> [String] {
        let d = digits.filter { $0.isNumber }
        guard d.count >= 3, d.count <= 5 else { return [] }
        let code5 = String(d.prefix(5)).padding(toLength: 5, withPad: "0", startingAt: 0)
        return ["hk\(code5)"]
    }
    
    /// 美股代码直查：腾讯格式 us + 代号（含 .OQ/.N 等后缀时可带后缀）
    /// - Parameter ticker: 字母或字母+数字/点，如 "AAPL"、"BRK.B"
    /// - Returns: 如 ["usAAPL"]，可选 ["usAAPL.OQ","usAAPL.N"]
    static func possibleQuoteCodesUS(ticker: String) -> [String] {
        let t = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        guard !t.isEmpty, t.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "." }) else { return [] }
        if t.contains(".") {
            return ["us\(t)"]
        }
        return ["us\(t)"]
    }
    
    /// 解析智能搜索框返回数据（格式因端而异，此处兼容常见 ~ 分隔）
    /// 常见形态：v_xxx="类型~名称~代码~显示代码"; 或多行 类型~名称~全代码~短代码
    /// - Parameter rawData: 接口返回的原始字符串
    /// - Returns: (name, fullCode) 列表，fullCode 为 sh600519 / sz000858 等
    static func parseSuggestResponse(_ rawData: String) -> [(name: String, code: String)] {
        var results: [(name: String, code: String)] = []
        let lines = rawData.components(separatedBy: ";").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for line in lines {
            guard let startQuote = line.firstIndex(of: "\""),
                  let endQuote = line.lastIndex(of: "\"") else {
                // 无引号：可能是纯 ~ 分隔的一行
                let parts = line.split(separator: "~").map(String.init)
                if parts.count >= 3 {
                    let name = parts[1].trimmingCharacters(in: .whitespaces)
                    let code = parts[2].trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty, !code.isEmpty { results.append((name, code)) }
                }
                continue
            }
            let dataStart = line.index(after: startQuote)
            let dataString = String(line[dataStart..<endQuote])
            let fields = dataString.components(separatedBy: "~")
            // 字段顺序常见：类型(0), 名称(1), 全代码(2), 短代码(3)
            if fields.count >= 4 {
                let name = fields[1].trimmingCharacters(in: .whitespaces)
                let code = fields[2].trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, !code.isEmpty { results.append((name, code)) }
            } else if fields.count >= 3 {
                let name = fields[1].trimmingCharacters(in: .whitespaces)
                let code = fields[2].trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, !code.isEmpty { results.append((name, code)) }
            }
        }
        return results
    }
    
    /// 解析腾讯财经API返回的数据
    /// - Parameter rawData: API返回的原始字符串
    /// - Returns: 解析后的字典数组，每个字典代表一只股票/指数
    static func parseResponse(_ rawData: String) -> [[String: String]] {
        var results: [[String: String]] = []
        
        // 按分号分割每条记录
        let lines = rawData.components(separatedBy: ";").filter { !$0.isEmpty }
        
        for line in lines {
            // 提取引号内的数据
            guard let startQuote = line.firstIndex(of: "\""),
                  let endQuote = line.lastIndex(of: "\"") else {
                continue
            }
            
            let dataStart = line.index(after: startQuote)
            let dataString = String(line[dataStart..<endQuote])
            
            // 按波浪号分割字段
            let fields = dataString.components(separatedBy: "~")
            
            // 提取代码（从变量名中）
            var code = ""
            if let codeStart = line.firstIndex(of: "_"),
               let codeEnd = line.firstIndex(of: "=") {
                let codeStartIndex = line.index(after: codeStart)
                code = String(line[codeStartIndex..<codeEnd])
            }
            
            // 构建字典
            var dict: [String: String] = [:]
            dict["code"] = code
            
            // 根据字段数量提取数据
            if fields.count > 1 { dict["name"] = fields[1] }      // 名称
            if fields.count > 3 { dict["current"] = fields[3] }   // 当前价
            
            if fields.count > 32 {
                // 完整行情解析逻辑 (如 sh600519)
                dict["lastClose"] = fields[4]
                dict["open"] = fields[5]
                dict["change"] = fields[31]
                dict["changePercent"] = fields[32]
                dict["volume"] = fields[6]
                dict["amount"] = fields[37]
            } else if fields.count > 5 {
                // 简化行情解析逻辑 (如 s_sh000001)
                // 简化格式: 1:名称, 3:当前价, 4:涨跌额, 5:涨跌幅
                dict["change"] = fields[4]
                dict["changePercent"] = fields[5]
            }
            if fields.count > 33 { dict["high"] = fields[33] }    // 最高
            if fields.count > 34 { dict["low"] = fields[34] }     // 最低
            
            results.append(dict)
        }
        
        return results
    }
}

/// 常用指数代码
extension TencentFinanceAPI {
    /// 上证指数
    static let shanghaiIndex = "s_sh000001"
    
    /// 深证成指
    static let shenzhenIndex = "s_sz399001"
    
    /// 创业板指
    static let chinextIndex = "s_sz399006"
    
    /// 沪深300
    static let csi300Index = "s_sh000300"
    
    /// 获取所有主要指数代码（A股，兼容旧逻辑）
    static var majorIndices: [String] {
        indicesCodes(for: .aShare)
    }

    /// 港股主要指数（恒生、恒生国企、恒生科技）
    static let hkHSI = "s_hkHSI"
    static let hkHSCEI = "s_hkHSCEI"
    static let hkHSCCI = "s_hkHSCCI"

    /// 美股主要指数（道琼斯、纳斯达克、标普500）
    static let usDJI = "s_usDJI"
    static let usIXIC = "s_usIXIC"
    static let usINX = "s_usINX"

    /// 按市场区域返回指数代码（用于 qt.gtimg.cn/q=）
    static func indicesCodes(for region: MarketRegion) -> [String] {
        switch region {
        case .aShare:
            return [shanghaiIndex, shenzhenIndex, chinextIndex, csi300Index]
        case .hongKong:
            return [hkHSI, hkHSCEI, hkHSCCI]
        case .us:
            return [usDJI, usIXIC, usINX]
        }
    }
}

// MARK: - 板块数据API
extension TencentFinanceAPI {
    
    /// 行业板块列表API
    /// 格式: http://qt.gtimg.cn/q=s_thhy001xxx
    /// 返回热门行业板块
    static let industrySectorPrefix = "s_thhy"
    
    /// 概念板块列表API
    /// 格式: http://qt.gtimg.cn/q=s_thgn001xxx
    /// 返回热门概念板块
    static let conceptSectorPrefix = "s_thgn"
    
    /// 行业板块代码列表（热门行业）
    static var industrySectorCodes: [String] {
        [
            "s_thhy001001", // 电力设备
            "s_thhy001002", // 医药生物
            "s_thhy001003", // 电子
            "s_thhy001004", // 计算机
            "s_thhy001005", // 汽车
            "s_thhy001006", // 有色金属
            "s_thhy001007", // 机械设备
            "s_thhy001008", // 化工
            "s_thhy001009", // 食品饮料
            "s_thhy001010", // 银行
            "s_thhy001011", // 非银金融
            "s_thhy001012"  // 房地产
        ]
    }
    
    /// 概念板块代码列表（热门概念）
    static var conceptSectorCodes: [String] {
        [
            "s_thgn001001", // 人工智能
            "s_thgn001002", // 新能源车
            "s_thgn001003", // 芯片概念
            "s_thgn001004", // 光伏概念
            "s_thgn001005", // 储能
            "s_thgn001006", // 锂电池
            "s_thgn001007", // 华为概念
            "s_thgn001008", // 5G概念
            "s_thgn001009", // 医药电商
            "s_thgn001010", // 数字经济
            "s_thgn001011", // 元宇宙
            "s_thgn001012"  // 碳中和
        ]
    }
    
    /// 解析板块数据响应
    /// - Parameter rawData: API返回的原始字符串
    /// - Returns: 解析后的板块数据数组
    static func parseSectorResponse(_ rawData: String) -> [[String: String]] {
        var results: [[String: String]] = []
        
        // 按分号分割每条记录
        let lines = rawData.components(separatedBy: ";").filter { !$0.isEmpty }
        
        for line in lines {
            // 提取引号内的数据
            guard let startQuote = line.firstIndex(of: "\""),
                  let endQuote = line.lastIndex(of: "\"") else {
                continue
            }
            
            let dataStart = line.index(after: startQuote)
            let dataString = String(line[dataStart..<endQuote])
            
            // 按波浪号分割字段
            let fields = dataString.components(separatedBy: "~")
            
            // 提取代码（从变量名中）
            var code = ""
            if let codeStart = line.firstIndex(of: "_"),
               let codeEnd = line.firstIndex(of: "=") {
                let codeStartIndex = line.index(after: codeStart)
                code = String(line[codeStartIndex..<codeEnd])
            }
            
            // 构建字典
            // 板块数据格式：名称~涨跌额~涨跌幅~成交量(手)~成交额(万元)~领涨股名称~领涨股代码~领涨股涨幅
            var dict: [String: String] = [:]
            dict["code"] = code
            
            if fields.count > 0 { dict["name"] = fields[0] }           // 板块名称
            if fields.count > 2 { dict["changePercent"] = fields[2] }  // 涨跌幅 (索引2)
            if fields.count > 5 { dict["leadingStock"] = fields[5] }   // 领涨股名称 (索引5)
            if fields.count > 7 { dict["leadingStockChange"] = fields[7] } // 领涨股涨幅 (索引7)
            if fields.count > 4 { dict["volume"] = fields[4] }         // 成交额 (索引4)
            
            results.append(dict)
        }
        
        return results
    }
}

// MARK: - 排行榜API
extension TencentFinanceAPI {
    
    /// 涨幅榜股票代码（热门上涨股票）
    /// 这些是常见的活跃股票，用于展示排行榜
    static var topGainersCodes: [String] {
        [
            "sh600519", // 贵州茅台
            "sz000858", // 五粮液
            "sh601318", // 中国平安
            "sz300750", // 宁德时代
            "sh600036", // 招商银行
            "sz000333", // 美的集团
            "sh601012", // 隆基绿能
            "sz002594", // 比亚迪
            "sh600276", // 恒瑞医药
            "sz300059"  // 东方财富
        ]
    }
    
    /// 跌幅榜股票代码
    static var topLosersCodes: [String] {
        [
            "sh601398", // 工商银行
            "sh601288", // 农业银行
            "sh601939", // 建设银行
            "sh601988", // 中国银行
            "sh601857", // 中国石油
            "sh600028", // 中国石化
            "sh601088", // 中国神华
            "sh600900", // 长江电力
            "sh601668", // 中国建筑
            "sh601669"  // 中国电建
        ]
    }
    
    /// 活跃榜股票代码（成交量大的）
    static var topActiveCodes: [String] {
        [
            "sz300750", // 宁德时代
            "sz002594", // 比亚迪
            "sz300059", // 东方财富
            "sh600519", // 贵州茅台
            "sz000858", // 五粮液
            "sh601318", // 中国平安
            "sz000333", // 美的集团
            "sh600036", // 招商银行
            "sz002475", // 立讯精密
            "sh601012"  // 隆基绿能
        ]
    }
    
    /// 获取排行榜股票代码
    /// - Parameter type: 榜单类型
    /// - Returns: 股票代码列表
    static func getRankingCodes(type: HotStockType) -> [String] {
        switch type {
        case .gainers:
            return topGainersCodes
        case .losers:
            return topLosersCodes
        case .active:
            return topActiveCodes
        }
    }
}

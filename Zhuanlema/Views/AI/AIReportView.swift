/**
 * AI 每日情绪脉搏视图
 * 展示：社区情绪环形图 + 大盘心跳 + AI 一句话 + AI 详细复盘 + 情绪洞察
 */
import SwiftUI

struct AIReportView: View {
    let report: AIReport?
    let isLoading: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                loadingView
            } else if let report = report {
                reportContent(report)
            } else {
                emptyView
            }
        }
    }

    // MARK: - 报告内容

    @ViewBuilder
    private func reportContent(_ report: AIReport) -> some View {
        // 日期标题
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 13))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            Text(formatDate(report.date))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            Spacer()
            Text("每日复盘")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(uiColor: ColorPalette.brandPrimary).opacity(0.1))
                .cornerRadius(10)
        }

        // 情绪 + 大盘并排
        HStack(alignment: .top, spacing: 16) {
            if let sentiment = report.sentimentData {
                SentimentRingView(yesPercent: sentiment.yesPercent, totalCheckIns: sentiment.totalCheckIns)
            }

            VStack(alignment: .leading, spacing: 10) {
                MarketPulseView(marketData: report.marketData)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(14)

        // AI 一句话
        if let oneLiner = report.aiContent?.oneLiner, !oneLiner.isEmpty {
            Text(oneLiner)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        // AI 详细复盘（可展开）
        if let summary = report.aiContent?.summary, !summary.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    .lineLimit(isExpanded ? nil : 3)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)

                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "收起" : "展开全文")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
        }

        // 情绪洞察卡片
        if let insight = report.aiContent?.insight, !insight.isEmpty {
            insightCard(text: insight)
        }

        // 明日展望
        if let outlook = report.aiContent?.outlook, !outlook.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                Text(outlook)
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.06))
            .cornerRadius(12)
        }
    }

    private func insightCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: ColorPalette.brandPrimary).opacity(0.05),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(uiColor: ColorPalette.brandPrimary).opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - 状态视图

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
            Text("正在加载今日复盘…")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            Text("暂无复盘报告")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            Text("报告于每个交易日收盘后自动生成")
                .font(.system(size: 12))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - 工具

    private func formatDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(parts[1])月\(parts[2])日"
    }
}

#Preview {
    ScrollView {
        AIReportView(
            report: AIReport(
                id: "report_20260330",
                date: "2026-03-30",
                type: "daily",
                marketData: MarketDataSnapshot(
                    shIndex: IndexQuote(name: "上证指数", close: 3250.12, changePercent: -0.32),
                    szIndex: IndexQuote(name: "深证成指", close: 10856.78, changePercent: 0.15),
                    cyIndex: IndexQuote(name: "创业板指", close: 2180.45, changePercent: 0.52)
                ),
                sentimentData: SentimentSnapshot(totalCheckIns: 1280, yesCount: 832, noCount: 448, yesPercent: 65),
                aiContent: AIContent(
                    oneLiner: "沪弱深强，创业板小哥们挺争气",
                    summary: "今天大盘震荡收跌，上证指数微跌0.3%，但创业板逆势上涨0.5%。成交额维持在1.2万亿，市场活跃度还算可以。科技板块整体表现不错，AI概念继续活跃。蓝筹白马有点拉胯，银行保险略显疲态。",
                    insight: "65%的赚友今天赚了，跟创业板走势吻合。如果你今天亏了，大概率是蓝筹拖累，别焦虑。",
                    outlook: "缩量震荡格局短期难改，但情绪面不差，明天看能不能站上3260。"
                ),
                model: "deepseek-v3.2",
                createdAt: 1743321000000
            ),
            isLoading: false
        )
        .padding()
    }
}

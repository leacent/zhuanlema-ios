/**
 * 首页 AI 一句话复盘摘要卡片
 * 展示当日 AI 生成的大盘摘要；点击跳转到 AI 复盘 Tab
 * Phase 2 接入真实数据后替换占位内容
 */
import SwiftUI

struct AISummaryCardView: View {
    @EnvironmentObject var appState: AppState
    let summaryText: String
    let isLoading: Bool
    var isReportToday: Bool = true

    var body: some View {
        Button(action: { appState.selectedMainTab = 1 }) {
            HStack(spacing: 12) {
                aiIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("AI 复盘")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                        Text(isReportToday ? "今日" : "上一交易日")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isReportToday ? Color(uiColor: ColorPalette.textTertiary) : .orange)
                    }

                    if isLoading {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("正在生成今日复盘…")
                                .font(.system(size: 14))
                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        }
                    } else {
                        Text(summaryText)
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        Color(uiColor: ColorPalette.brandPrimary).opacity(0.05),
                        Color(uiColor: ColorPalette.bgSecondary)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: ColorPalette.brandPrimary).opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var aiIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(uiColor: ColorPalette.brandPrimary), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)

            Image(systemName: "brain.fill")
                .font(.system(size: 17))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AISummaryCardView(
            summaryText: "大盘震荡收跌 0.3%，科技板块领涨，AI 概念持续活跃",
            isLoading: false
        )

        AISummaryCardView(
            summaryText: "",
            isLoading: true
        )
    }
    .padding()
    .environmentObject(AppState())
}

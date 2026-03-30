/**
 * 复盘日记卡片组件
 * 用于历史列表中展示单条复盘摘要
 */
import SwiftUI

struct TradingReviewCardView: View {
    let review: TradingReview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 日期 + 满意度
            HStack {
                Text(review.formattedDate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Text(review.weekdayText)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                Spacer()
                Text(review.satisfactionEmoji)
                    .font(.system(size: 18))
            }

            // 标签行：操作 + 驱动 + 情绪
            if !review.actions.isEmpty || !review.drivers.isEmpty || !review.emotions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(review.actionLabels, id: \.self) { label in
                            miniTag(label, color: Color(uiColor: ColorPalette.brandPrimary))
                        }
                        ForEach(review.driverLabels, id: \.self) { label in
                            miniTag(label, color: .blue)
                        }
                        ForEach(review.emotionEmojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 14))
                        }
                    }
                }
            }

            // 内容预览
            if !review.contentPreview.isEmpty {
                Text(review.contentPreview)
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(14)
    }

    private func miniTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 12) {
        TradingReviewCardView(review: TradingReview(
            id: "1",
            userId: "u1",
            date: "2026-03-28",
            actions: ["buy", "add_position"],
            drivers: ["news", "technical"],
            emotions: ["excited"],
            content: "看到利好直接冲了，加仓了半导体ETF，明天看能不能突破前高",
            satisfaction: 4,
            checkInResult: "yes",
            checkInMagnitude: "small_win",
            createdAt: 1743321000000,
            updatedAt: 1743321000000
        ))

        TradingReviewCardView(review: TradingReview(
            id: "2",
            userId: "u1",
            date: "2026-03-27",
            actions: ["sell"],
            drivers: ["planned"],
            emotions: ["anxious", "regretful"],
            content: "割了亏5个点的中概股，心里不好受但计划就是计划",
            satisfaction: 2,
            checkInResult: "no",
            checkInMagnitude: "small_loss",
            createdAt: 1743234600000,
            updatedAt: 1743234600000
        ))
    }
    .padding()
}

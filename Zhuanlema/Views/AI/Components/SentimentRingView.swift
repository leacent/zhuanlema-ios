/**
 * 社区情绪环形图
 * 展示今日打卡赚/亏比例的环形进度条
 */
import SwiftUI

struct SentimentRingView: View {
    let yesPercent: Int
    let totalCheckIns: Int

    private var progress: Double { Double(yesPercent) / 100.0 }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: ColorPalette.bgSecondary), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(uiColor: ColorPalette.brandPrimary), .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text("\(yesPercent)%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    Text("赚了")
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
            }
            .frame(width: 80, height: 80)

            Text("\(totalCheckIns)人打卡")
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
        }
    }
}

#Preview {
    SentimentRingView(yesPercent: 65, totalCheckIns: 1280)
        .padding()
}

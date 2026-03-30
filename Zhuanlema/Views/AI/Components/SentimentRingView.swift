/**
 * 社区情绪环形图
 * 展示今日打卡赚/亏比例的环形进度条
 * 样本量不足（< 30人）时降级展示，避免统计误导
 */
import SwiftUI

struct SentimentRingView: View {
    let yesPercent: Int
    let totalCheckIns: Int
    let isSufficientSample: Bool

    init(yesPercent: Int, totalCheckIns: Int, isSufficientSample: Bool? = nil) {
        self.yesPercent = yesPercent
        self.totalCheckIns = totalCheckIns
        self.isSufficientSample = isSufficientSample ?? (totalCheckIns >= SentimentSnapshot.minSampleSize)
    }

    private var progress: Double {
        isSufficientSample ? Double(yesPercent) / 100.0 : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: ColorPalette.bgSecondary), lineWidth: 8)

                if isSufficientSample {
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
                } else {
                    Circle()
                        .trim(from: 0, to: 0)
                        .stroke(
                            Color(uiColor: ColorPalette.bgSecondary),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [6, 4])
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("--")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        Text("待更多打卡")
                            .font(.system(size: 10))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    }
                }
            }
            .frame(width: 80, height: 80)

            if isSufficientSample {
                Text("\(totalCheckIns)人打卡")
                    .font(.system(size: 11))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            } else {
                Text("\(totalCheckIns)人打卡（需\(SentimentSnapshot.minSampleSize)人）")
                    .font(.system(size: 10))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
        }
    }
}

#Preview("充足样本") {
    SentimentRingView(yesPercent: 65, totalCheckIns: 1280)
        .padding()
}

#Preview("样本不足") {
    SentimentRingView(yesPercent: 100, totalCheckIns: 3)
        .padding()
}

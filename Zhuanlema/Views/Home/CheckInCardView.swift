/**
 * 首页打卡卡片组件（5 档盈亏幅度）
 * 两种状态：
 * - 未打卡：5 档选择按钮（大赚/小赚/持平/小亏/大亏）
 * - 已打卡：收缩为一行统计条
 */
import SwiftUI

/// 打卡幅度选项
private enum CheckInMagnitude: String, CaseIterable {
    case bigWin = "big_win"
    case smallWin = "small_win"
    case neutral = "neutral"
    case smallLoss = "small_loss"
    case bigLoss = "big_loss"

    var emoji: String {
        switch self {
        case .bigWin: return "🔥"
        case .smallWin: return "😊"
        case .neutral: return "😐"
        case .smallLoss: return "😟"
        case .bigLoss: return "💀"
        }
    }

    var label: String {
        switch self {
        case .bigWin: return "大赚"
        case .smallWin: return "小赚"
        case .neutral: return "持平"
        case .smallLoss: return "小亏"
        case .bigLoss: return "大亏"
        }
    }

    var hint: String {
        switch self {
        case .bigWin: return ">3%"
        case .smallWin: return "0~3%"
        case .neutral: return "0%"
        case .smallLoss: return "0~3%"
        case .bigLoss: return ">3%"
        }
    }

    var bgColors: [Color] {
        switch self {
        case .bigWin:
            return [Color(uiColor: ColorPalette.brandPrimary), Color(uiColor: ColorPalette.brandSecondary)]
        case .smallWin:
            return [Color(uiColor: ColorPalette.brandPrimary).opacity(0.7), Color(uiColor: ColorPalette.brandSecondary).opacity(0.7)]
        case .neutral:
            return [Color(uiColor: ColorPalette.textTertiary).opacity(0.5), Color(uiColor: ColorPalette.textTertiary).opacity(0.4)]
        case .smallLoss:
            return [Color(uiColor: ColorPalette.tradingDown).opacity(0.7), Color(uiColor: UIColor(hex: "#388E3C")).opacity(0.7)]
        case .bigLoss:
            return [Color(uiColor: ColorPalette.tradingDown), Color(uiColor: UIColor(hex: "#388E3C"))]
        }
    }

    var resultForBadge: String {
        switch self {
        case .bigWin, .smallWin: return "yes"
        case .neutral: return "neutral"
        case .smallLoss, .bigLoss: return "no"
        }
    }
}

struct CheckInCardView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        if viewModel.hasCheckedInToday {
            checkedInCard
        } else {
            uncheckedCard
        }
    }

    // MARK: - 未打卡状态

    private var uncheckedCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.title3)
                    .foregroundColor(Color(uiColor: ColorPalette.brandAccent))
                Text("今天赚了吗？")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(CheckInMagnitude.allCases, id: \.rawValue) { magnitude in
                    Button(action: { viewModel.submitCheckIn(magnitude: magnitude.rawValue, appState: appState) }) {
                        VStack(spacing: 4) {
                            Text(magnitude.emoji)
                                .font(.system(size: 22))
                            Text(magnitude.label)
                                .font(.system(size: 13, weight: .bold))
                            Text(magnitude.hint)
                                .font(.system(size: 10))
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            LinearGradient(
                                colors: magnitude.bgColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSubmittingCheckIn)
                }
            }

            if viewModel.isSubmittingCheckIn {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                    .scaleEffect(0.8)
            }
        }
        .padding(16)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(20)
        .shadow(color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.08), radius: 12, x: 0, y: 4)
    }

    // MARK: - 已打卡状态

    @State private var showReviewEditor = false

    private var checkedInCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))

                if let stats = viewModel.checkInStats {
                    Text("今天 \(stats.yesPercentage)% 的人赚了")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                } else {
                    Text("已完成今日打卡")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }

                Spacer()

                resultBadge
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().padding(.horizontal, 16)

            Button(action: { showReviewEditor = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 12))
                    Text("记录一下今天的操作？")
                        .font(.system(size: 13, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(16)
        .sheet(isPresented: $showReviewEditor) {
            TradingReviewEditorView(
                checkInResult: viewModel.todayResult,
                checkInMagnitude: nil
            )
        }
    }

    @ViewBuilder
    private var resultBadge: some View {
        let result = viewModel.todayResult ?? "neutral"
        let isYes = result == "yes"
        let isNo = result == "no"
        let badgeLabel = isYes ? "赚了" : isNo ? "亏了" : "持平"
        let badgeColor = isYes
            ? Color(uiColor: ColorPalette.brandPrimary)
            : isNo
                ? Color(uiColor: ColorPalette.tradingDown)
                : Color(uiColor: ColorPalette.textTertiary)

        HStack(spacing: 4) {
            Text(badgeLabel)
                .font(.system(size: 13, weight: .semibold))
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(badgeColor.opacity(0.12))
        .cornerRadius(10)
    }
}

#Preview("未打卡") {
    CheckInCardView(viewModel: {
        let vm = HomeViewModel()
        vm.hasCheckedInToday = false
        return vm
    }())
    .environmentObject(AppState())
    .padding()
}

#Preview("已打卡 - 赚了") {
    CheckInCardView(viewModel: {
        let vm = HomeViewModel()
        vm.hasCheckedInToday = true
        vm.todayResult = "yes"
        vm.checkInStats = CheckInStats(
            date: "2026-03-30",
            totalCount: 1280,
            yesCount: 832,
            noCount: 448,
            yesPercentage: 65,
            noPercentage: 35,
            message: "今天 65% 的人赚了"
        )
        return vm
    }())
    .environmentObject(AppState())
    .padding()
}

#Preview("已打卡 - 持平") {
    CheckInCardView(viewModel: {
        let vm = HomeViewModel()
        vm.hasCheckedInToday = true
        vm.todayResult = "neutral"
        return vm
    }())
    .environmentObject(AppState())
    .padding()
}

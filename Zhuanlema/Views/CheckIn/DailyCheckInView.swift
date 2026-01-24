/**
 * 每日打卡页面
 * 全屏独立页面，采用对角线分割设计
 * 点击红/绿板块完成状态选择并进入社区
 */
import SwiftUI
import Combine

/// 对角线切割形状
struct DiagonalSplitShape: Shape {
    let isTopLeft: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isTopLeft {
            // 左上角三角形 (包含左上、右上、左下)
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            // 右下角三角形 (包含右上、右下、左下)
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

struct DailyCheckInView: View {
    @EnvironmentObject var appState: AppState
    @State private var showGoldConfetti = false
    @State private var showGrayConfetti = false
    @State private var isSubmitting = false
    @State private var selectedResult: String? = nil
    
    private let checkInRepository = CheckInRepository()
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // 标题部分
                VStack(spacing: 12) {
                    Text("赚了吗？")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                        .tracking(4)
                    
                    Text("点击板块表达你此刻的心情")
                        .font(.system(size: 16))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
                
                Spacer()
                
                // 对角线分割交互板块
                checkInSplitView
                    .padding(.horizontal, 30)
                    .aspectRatio(1, contentMode: .fit)
                
                Spacer()
                
                // 引导文字
                Text("选择后进入社区分享心得")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                
                Spacer()
                    .frame(height: 40)
            }
        }
        // 撒花动效
        .confetti(type: .gold, isActive: $showGoldConfetti)
        .confetti(type: .gray, isActive: $showGrayConfetti)
    }
    
    /// 对角线分割视图
    private var checkInSplitView: some View {
        GeometryReader { geometry in
            ZStack {
                // "Yes" 赚了板块 (左上红色)
                Button(action: { handleCheckIn(result: "yes") }) {
                    ZStack {
                        DiagonalSplitShape(isTopLeft: true)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(uiColor: UIColor(hex: "#FF5252")),
                                        Color(uiColor: ColorPalette.brandPrimary)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("Yes")
                                .font(.system(size: 44, weight: .black))
                            Text("赚了")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundColor(.white)
                        // 偏移到左上三角形中心感位置
                        .offset(x: -geometry.size.width * 0.18, y: -geometry.size.height * 0.18)
                    }
                }
                .buttonStyle(SplitButtonStyle())
                .disabled(isSubmitting)
                
                // "No" 亏了板块 (右下绿色)
                Button(action: { handleCheckIn(result: "no") }) {
                    ZStack {
                        DiagonalSplitShape(isTopLeft: false)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(uiColor: ColorPalette.tradingDown),
                                        Color(uiColor: UIColor(hex: "#388E3C"))
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("No")
                                .font(.system(size: 44, weight: .black))
                            Text("亏了")
                                .font(.system(size: 22, weight: .bold))
                        }
                        .foregroundColor(.white)
                        // 偏移到右下三角形中心感位置
                        .offset(x: geometry.size.width * 0.18, y: geometry.size.height * 0.18)
                    }
                }
                .buttonStyle(SplitButtonStyle())
                .disabled(isSubmitting)
                
                // 分割线
                Path { path in
                    path.move(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                }
                .stroke(Color.white, lineWidth: 8)
                
                // 如果正在提交，显示加载中
                if isSubmitting {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .shadow(color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.15), radius: 30, x: 0, y: 15)
        }
    }
    
    /// 处理打卡
    private func handleCheckIn(result: String) {
        guard !isSubmitting else { return }
        isSubmitting = true
        selectedResult = result
        
        // 触发动效
        if result == "yes" {
            showGoldConfetti = true
        } else {
            showGrayConfetti = true
        }
        
        // 提交打卡
        Task {
            do {
                _ = try await checkInRepository.submitCheckIn(result: result)
                
                // 标记已打卡（虽然用户说没有时间定义，但我们仍需通过此标志进入主界面）
                checkInRepository.markCheckedInToday()
                
                // 给予动效展示时间
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        appState.hasCheckedInToday = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("打卡记录失败: \(error.localizedDescription)")
                    // 即使失败，为了用户体验，也可以考虑是否强制进入
                }
            }
        }
    }
}

/// 板块按钮点击反馈样式
struct SplitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

#Preview {
    DailyCheckInView()
        .environmentObject(AppState())
}

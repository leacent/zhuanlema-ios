/**
 * AI 复盘 Tab 主页面
 * 顶部：每日情绪脉搏（AIReportView）
 * 底部：进入对话入口
 */
import SwiftUI

struct AITabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AIViewModel()
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 每日报告
                        AIReportView(report: viewModel.dailyReport, isLoading: viewModel.isLoadingReport)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // 进入对话
                        chatEntryCard
                            .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    viewModel.loadDailyReport()
                }
            }
            .navigationTitle("AI 复盘")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showChat) {
                AIChatView(viewModel: viewModel)
            }
        }
    }

    // MARK: - 对话入口卡片

    private var chatEntryCard: some View {
        Button(action: { showChat = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(uiColor: ColorPalette.brandPrimary), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "brain.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("向赚哥提问")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))

                    Text("聊聊今天的操作、分析个股、复盘心态")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(16)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: ColorPalette.brandPrimary).opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AITabView()
        .environmentObject(AppState())
}

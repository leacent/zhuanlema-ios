/**
 * AI 复盘 Tab 主页面
 * 顶部：写复盘入口 + 每日情绪脉搏（AIReportView）
 * 中部：个人复盘日记入口
 * 底部：AI 对话入口
 */
import SwiftUI

struct AITabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AIViewModel()
    @State private var showChat = false
    @State private var showReviewEditor = false
    @State private var showReviewHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 写复盘入口
                        writeReviewCard
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // 每日大盘报告
                        AIReportView(report: viewModel.dailyReport, isLoading: viewModel.isLoadingReport)
                            .padding(.horizontal, 16)

                        // 复盘日记入口
                        reviewHistoryEntry
                            .padding(.horizontal, 16)

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
            .navigationDestination(isPresented: $showReviewHistory) {
                TradingReviewHistoryView()
            }
            .sheet(isPresented: $showReviewEditor) {
                TradingReviewEditorView()
            }
        }
    }

    // MARK: - 写复盘入口

    private var writeReviewCard: some View {
        Button(action: { showReviewEditor = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(uiColor: ColorPalette.brandPrimary), .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "pencil.line")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("写今日复盘")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    Text("30 秒记录操作、情绪和心得")
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color(uiColor: ColorPalette.brandPrimary).opacity(0.06),
                        Color.orange.opacity(0.04),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(uiColor: ColorPalette.brandPrimary).opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 复盘日记入口

    private var reviewHistoryEntry: some View {
        Button(action: { showReviewHistory = true }) {
            HStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))

                Text("我的复盘日记")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(14)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
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

/**
 * 复盘日记历史列表
 * 展示用户所有复盘记录，支持查看和编辑
 */
import SwiftUI

struct TradingReviewHistoryView: View {
    @StateObject private var viewModel = TradingReviewViewModel()
    @State private var selectedReviewDate: String?
    @State private var showEditor = false

    var body: some View {
        ZStack {
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()

            if viewModel.isLoadingHistory {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
            } else if viewModel.reviews.isEmpty {
                emptyState
            } else {
                reviewList
            }
        }
        .navigationTitle("复盘日记")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    selectedReviewDate = nil
                    showEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: { viewModel.loadHistory() }) {
            TradingReviewEditorView(initialDate: selectedReviewDate)
        }
        .onAppear {
            viewModel.loadHistory()
        }
    }

    // MARK: - 列表

    private var reviewList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.reviews) { review in
                    Button(action: {
                        selectedReviewDate = review.date
                        showEditor = true
                    }) {
                        TradingReviewCardView(review: review)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            viewModel.loadHistory()
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(uiColor: ColorPalette.brandPrimary).opacity(0.1), Color.orange.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary).opacity(0.6))
            }

            Text("还没有复盘记录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))

            Text("每天花 30 秒记录操作和心态\n积累下来就是最好的交易日志")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                .multilineTextAlignment(.center)

            Button(action: { showEditor = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 14))
                    Text("写第一篇复盘")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [Color(uiColor: ColorPalette.brandPrimary), Color(uiColor: ColorPalette.brandSecondary)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        TradingReviewHistoryView()
    }
}

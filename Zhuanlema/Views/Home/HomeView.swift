/**
 * 首页视图（三段式布局）
 * ┌──────────────────────────┐
 * │  [打卡卡片]  1/5 屏       │
 * ├──────────────────────────┤
 * │  [AI 一句话复盘]  1/5 屏  │
 * ├──────────────────────────┤
 * │  [社区信息流]  3/5 屏     │
 * │  排序切换（最新/热度）     │
 * │  帖子卡片列表             │
 * └──────────────────────────┘
 */
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var communityViewModel = CommunityViewModel()
    @State private var showLoginAlert = false
    @State private var showLoginSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                if communityViewModel.posts.isEmpty && communityViewModel.isLoading {
                    skeletonView
                } else {
                    contentView
                }
            }
            .navigationTitle("首页")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handlePublishTap) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    }
                }
            }
            .sheet(isPresented: $communityViewModel.showComposePage) {
                ComposePostView(onPublished: { _ in
                    communityViewModel.onPostPublished()
                })
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView(isPresented: $showLoginSheet)
                    .environmentObject(appState)
            }
            .alert("需要登录", isPresented: $showLoginAlert) {
                Button("取消", role: .cancel) {}
                Button("去登录") { showLoginSheet = true }
            } message: {
                Text("登录后可以点赞、评论和发布心得")
            }
            .alert("加载失败", isPresented: Binding(
                get: { communityViewModel.errorMessage != nil },
                set: { if !$0 { communityViewModel.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) { communityViewModel.errorMessage = nil }
            } message: {
                if let error = communityViewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .confetti(type: .gold, isActive: $homeViewModel.showGoldConfetti)
        .confetti(type: .gray, isActive: $homeViewModel.showGrayConfetti)
    }

    // MARK: - 主内容

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 第一段：打卡卡片
                CheckInCardView(viewModel: homeViewModel)
                    .environmentObject(appState)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // 第二段：AI 摘要卡片
                AISummaryCardView(
                    summaryText: homeViewModel.aiSummaryText,
                    isLoading: homeViewModel.isAISummaryLoading,
                    isReportToday: homeViewModel.isAIReportToday
                )
                .environmentObject(appState)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // 第三段：社区信息流
                communitySection
            }
        }
        .refreshable {
            homeViewModel.loadInitialState()
            communityViewModel.refresh()
        }
    }

    // MARK: - 社区信息流

    private var communitySection: some View {
        VStack(spacing: 0) {
            sortToggleBar

            if communityViewModel.posts.isEmpty && !communityViewModel.isLoading {
                emptyPostsHint
            } else {
                postList
            }
        }
    }

    private var sortToggleBar: some View {
        HStack(spacing: 0) {
            ForEach(PostSortMode.allCases, id: \.self) { mode in
                Button(action: { communityViewModel.switchSort(mode) }) {
                    Text(mode.title)
                        .font(.system(size: 14, weight: communityViewModel.sortMode == mode ? .semibold : .regular))
                        .foregroundColor(
                            communityViewModel.sortMode == mode
                                ? Color(uiColor: ColorPalette.brandPrimary)
                                : Color(uiColor: ColorPalette.textSecondary)
                        )
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            communityViewModel.sortMode == mode
                                ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.1)
                                : Color.clear
                        )
                        .cornerRadius(16)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var postList: some View {
        VStack(spacing: 12) {
            ForEach(Array(communityViewModel.posts.enumerated()), id: \.element.id) { index, post in
                NavigationLink(destination: PostDetailView(post: post, onCommentCountChanged: { newCount in
                    communityViewModel.updateCommentCount(postId: post.id, count: newCount)
                })) {
                    PostCard(post: post, onLike: { handleLikeTap(post: post) })
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .onAppear {
                    if index == communityViewModel.posts.count - 1 {
                        communityViewModel.loadPosts()
                    }
                }
            }

            if communityViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                    .padding()
            }
        }
        .padding(.vertical, 8)
    }

    private var emptyPostsHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 36))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            Text("还没有交易心得，成为第一个分享的人")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            Button(action: handlePublishTap) {
                Text("发布心得")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: ColorPalette.brandPrimary))
                    .cornerRadius(20)
            }
        }
        .padding(.vertical, 40)
    }

    // MARK: - 骨架屏

    private var skeletonView: some View {
        ScrollView {
            VStack(spacing: 12) {
                skeletonCheckInCard
                skeletonAICard
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonPostCard()
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var skeletonCheckInCard: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(uiColor: ColorPalette.bgSecondary))
            .frame(height: 110)
            .padding(.horizontal, 16)
            .shimmer()
    }

    private var skeletonAICard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(uiColor: ColorPalette.bgSecondary))
            .frame(height: 70)
            .padding(.horizontal, 16)
            .shimmer()
    }

    // MARK: - Actions

    private func handlePublishTap() {
        if appState.isLoggedIn {
            communityViewModel.showComposePage = true
        } else {
            showLoginAlert = true
        }
    }

    private func handleLikeTap(post: Post) {
        if appState.isLoggedIn {
            communityViewModel.likePost(post)
        } else {
            showLoginAlert = true
        }
    }
}

// MARK: - 骨架屏帖子卡片

private struct SkeletonPostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: ColorPalette.bgSecondary))
                        .frame(width: 80, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: ColorPalette.bgSecondary))
                        .frame(width: 50, height: 10)
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: ColorPalette.bgSecondary)).frame(height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: ColorPalette.bgSecondary)).frame(height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: ColorPalette.bgSecondary)).frame(width: 200, height: 14)
            }
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: ColorPalette.bgSecondary)).frame(width: 40, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color(uiColor: ColorPalette.bgSecondary)).frame(width: 40, height: 12)
                Spacer()
            }
        }
        .padding(16)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(16)
        .shimmer()
    }
}

// MARK: - Shimmer 动画修饰器

private struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

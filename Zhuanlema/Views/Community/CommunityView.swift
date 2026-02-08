/**
 * 社区首页
 * - 列表：单列信息流，下拉刷新、上滑加载更多
 * - 详情点击：点击卡片进入 PostDetailView（全文、图片、标签、评论区）
 * - 点赞：列表与详情均支持；未登录点击会提示登录
 * - 评论：在帖子详情页底部查看与发表评论（需登录）
 * 免登录可浏览列表与详情；发布、点赞、评论需登录
 */
import SwiftUI
import Combine
import PhotosUI

struct CommunityView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showLoginAlert = false
    @State private var showLoginSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()
                
                if viewModel.posts.isEmpty && viewModel.isLoading {
                    // 骨架屏加载
                    skeletonView
                } else if viewModel.posts.isEmpty && !viewModel.isLoading {
                    // 空状态
                    emptyStateView
                } else {
                    // 帖子列表
                    postListView
                }
            }
            .navigationTitle("社区")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handlePublishTap) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showComposePage) {
                ComposePostView(onPublished: { _ in
                    viewModel.onPostPublished()
                })
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView(isPresented: $showLoginSheet)
                    .environmentObject(appState)
            }
            .alert("需要登录", isPresented: $showLoginAlert) {
                Button("取消", role: .cancel) {}
                Button("去登录") {
                    showLoginSheet = true
                }
            } message: {
                Text("登录后可以点赞、评论和发布心得")
            }
            .alert("加载失败", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    /// 骨架屏加载视图
    private var skeletonView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonPostCard()
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // 插图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(uiColor: ColorPalette.brandPrimary).opacity(0.1),
                                Color(uiColor: ColorPalette.brandPrimary).opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            }
            .padding(.top, 60)
            
            VStack(spacing: 8) {
                Text("还没有交易心得")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Text("成为第一个分享投资见解的人")
                    .font(.system(size: 15))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
            
            Button(action: handlePublishTap) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("发布第一条心得")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(minWidth: 200)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(uiColor: ColorPalette.brandPrimary),
                            Color(uiColor: ColorPalette.brandSecondary)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(
                    color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 5
                )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 排序切换栏
    private var sortToggleBar: some View {
        HStack(spacing: 0) {
            ForEach(PostSortMode.allCases, id: \.self) { mode in
                Button(action: { viewModel.switchSort(mode) }) {
                    Text(mode.title)
                        .font(.system(size: 14, weight: viewModel.sortMode == mode ? .semibold : .regular))
                        .foregroundColor(
                            viewModel.sortMode == mode
                                ? Color(uiColor: ColorPalette.brandPrimary)
                                : Color(uiColor: ColorPalette.textSecondary)
                        )
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            viewModel.sortMode == mode
                                ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.1)
                                : Color.clear
                        )
                        .cornerRadius(16)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// 帖子列表视图
    private var postListView: some View {
        ScrollView {
            sortToggleBar

            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.posts.enumerated()), id: \.element.id) { index, post in
                    NavigationLink(destination: PostDetailView(post: post, onCommentCountChanged: { newCount in
                        viewModel.updateCommentCount(postId: post.id, count: newCount)
                    })) {
                        PostCard(post: post, onLike: { handleLikeTap(post: post) })
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .onAppear {
                        if index == viewModel.posts.count - 1 {
                            viewModel.loadPosts()
                        }
                    }
                }
            }
            .padding(.vertical, 12)

            // 加载更多指示器
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                    .padding()
            }
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    /// 处理发布按钮点击
    private func handlePublishTap() {
        if appState.isLoggedIn {
            viewModel.showComposePage = true
        } else {
            showLoginAlert = true
        }
    }

    /// 处理点赞按钮点击（未登录时提示去登录）
    private func handleLikeTap(post: Post) {
        if appState.isLoggedIn {
            viewModel.likePost(post)
        } else {
            showLoginAlert = true
        }
    }
}

/// 骨架屏帖子卡片
private struct SkeletonPostCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
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
            // 内容行
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(width: 200, height: 14)
            }
            // 底部操作栏
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(width: 40, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .frame(width: 40, height: 12)
                Spacer()
            }
        }
        .padding(16)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(16)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

#Preview {
    CommunityView()
        .environmentObject(AppState())
}

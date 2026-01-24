/**
 * 社区页面
 * 展示交易心得列表
 * 免登录浏览，发布/评论需登录
 */
import SwiftUI
import Combine

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
                
                if viewModel.posts.isEmpty && !viewModel.isLoading {
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
                ComposePostView(viewModel: viewModel)
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
                Text("发布心得需要先登录账号")
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
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            
            Text("还没有人发布心得")
                .font(.system(size: 16))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            
            Button(action: handlePublishTap) {
                Text("发布第一条")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: ColorPalette.brandPrimary))
                    .cornerRadius(20)
            }
        }
    }
    
    /// 帖子列表视图
    private var postListView: some View {
        ScrollView {
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.posts) { post in
                    PostCard(post: post) {
                        viewModel.likePost(post)
                    }
                }
            }
            .padding()
            
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
            // 已登录，显示发布页面
            viewModel.showComposePage = true
        } else {
            // 未登录，显示提示
            showLoginAlert = true
        }
    }
}

/// 发布帖子页面
struct ComposePostView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var content: String = ""
    @State private var tags: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 内容输入
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                        .padding()
                        .background(Color(uiColor: ColorPalette.bgSecondary))
                        .cornerRadius(12)
                        .padding()
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("分享你的交易心得...")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                        .padding(.top, 28)
                                        .padding(.leading, 24)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    // 标签输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签（用空格分隔）")
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        
                        TextField("例如：大盘 涨停 价值投资", text: $tags)
                            .padding()
                            .background(Color(uiColor: ColorPalette.bgSecondary))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 发布按钮
                    Button(action: publishPost) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("发布")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canPublish ? Color(uiColor: ColorPalette.brandPrimary) : Color(uiColor: ColorPalette.textDisabled))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
                    .disabled(!canPublish || viewModel.isLoading)
                }
            }
            .navigationTitle("发布心得")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
            }
        }
    }
    
    /// 是否可以发布
    private var canPublish: Bool {
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 发布帖子
    private func publishPost() {
        let tagList = tags
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        viewModel.publishPost(content: content, images: [], tags: tagList)
    }
}

#Preview {
    CommunityView()
        .environmentObject(AppState())
}

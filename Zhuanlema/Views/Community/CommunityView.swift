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
    
    /// 帖子列表视图
    private var postListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    PostCard(post: post) {
                        viewModel.likePost(post)
                    }
                    .padding(.horizontal, 16)
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
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 内容输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("分享你的交易心得")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        
                        ZStack(alignment: .topLeading) {
                            // TextEditor 背景
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(uiColor: ColorPalette.bgSecondary))
                                .stroke(
                                    isContentFocused ? 
                                        Color(uiColor: ColorPalette.brandPrimary) : 
                                        Color(uiColor: ColorPalette.border),
                                    lineWidth: isContentFocused ? 1.5 : 1
                                )
                            
                            // 内容输入
                            TextEditor(text: $content)
                                .focused($isContentFocused)
                                .font(.system(size: 16))
                                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                                .padding(12)
                                .background(Color.clear)
                                .frame(minHeight: 180)
                                .scrollContentBackground(.hidden)
                            
                            // Placeholder
                            if content.isEmpty {
                                Text("今天市场怎么样？聊聊你的操作和想法...")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                                    .padding(.top, 20)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(height: 200)
                        
                        // 字数统计
                        HStack {
                            Spacer()
                            Text("\(content.count)/500")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    content.count > 500 ? 
                                        Color(uiColor: ColorPalette.error) : 
                                        Color(uiColor: ColorPalette.textTertiary)
                                )
                        }
                    }
                    .padding(16)
                    
                    Divider()
                        .background(Color(uiColor: ColorPalette.divider))
                    
                    // 标签输入区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                            
                            Text("添加话题标签")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                            
                            Spacer()
                            
                            Text("用空格分隔")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        }
                        
                        TextField("例如: 大盘 涨停 价值投资", text: $tags)
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                            .padding(12)
                            .background(Color(uiColor: ColorPalette.bgSecondary))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(uiColor: ColorPalette.border), lineWidth: 1)
                            )
                        
                        // 快捷标签
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(parsedTags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(uiColor: ColorPalette.brandLight))
                                            .cornerRadius(14)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    
                    Spacer()
                    
                    // 发布按钮
                    Button(action: publishPost) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("发布心得")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(
                            canPublish ? 
                                Color(uiColor: ColorPalette.brandPrimary) : 
                                Color(uiColor: ColorPalette.textDisabled)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!canPublish || viewModel.isLoading)
                    .padding(16)
                    .animation(.easeOut(duration: 0.2), value: canPublish)
                }
            }
            .navigationTitle("发布心得")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                            Text("取消")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    }
                }
            }
        }
        .onAppear {
            // 自动聚焦输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isContentFocused = true
            }
        }
    }
    
    /// 解析的标签列表
    private var parsedTags: [String] {
        tags
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// 是否可以发布
    private var canPublish: Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && trimmedContent.count <= 500
    }
    
    /// 发布帖子
    private func publishPost() {
        viewModel.publishPost(content: content, images: [], tags: parsedTags)
    }
}

#Preview {
    CommunityView()
        .environmentObject(AppState())
}

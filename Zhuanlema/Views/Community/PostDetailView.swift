/**
 * 帖子详情页
 * 展示完整内容、图片、标签、作者与时间；评论列表与发表评论
 */
import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject var appState: AppState
    @State private var draftComment = ""

    init(post: Post, onCommentCountChanged: ((Int) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post, onCommentCountChanged: onCommentCountChanged))
    }

    private var post: Post { viewModel.post }

    private var displayNickname: String {
        post.nickname ?? post.user?.nickname ?? "匿名用户"
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        if let date = post.createdAtDate {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return "刚刚"
    }

    private var shareableText: String {
        let snippet = post.content.count > 100 ? String(post.content.prefix(100)) + "…" : post.content
        return "【赚了吗】\(snippet)\nzhuanlema://post/\(post.id)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 用户头部
                HStack(spacing: 10) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(uiColor: ColorPalette.brandPrimary),
                                    Color(uiColor: ColorPalette.brandSecondary)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(displayNickname.prefix(1))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayNickname)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                        Text(formattedDate)
                            .font(.system(size: 13))
                            .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 正文（全文）
                Text(post.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // 图片区域
                if !post.images.isEmpty {
                    PostImageStrip(urls: post.images, style: .fullWidth)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                // 标签
                if !post.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(uiColor: ColorPalette.brandLight))
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                // 评论区
                commentsSection
                Spacer(minLength: 24)
            }
        }
        .background(Color(uiColor: ColorPalette.bgPrimary))
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: shareableText, subject: Text("赚了吗 · 心得分享"), message: Text(String(post.content.prefix(300)))) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
        }
        .onAppear { viewModel.loadInitialComments() }
        .overlay(alignment: .bottom) {
            if appState.isLoggedIn {
                commentInputBar
            }
        }
        .alert("评论失败", isPresented: Binding(
            get: { viewModel.commentErrorMessage != nil },
            set: { if !$0 { viewModel.commentErrorMessage = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.commentErrorMessage = nil }
        } message: {
            if let msg = viewModel.commentErrorMessage { Text(msg) }
        }
        .confirmationDialog("撤回评论？", isPresented: $viewModel.showDeleteConfirm, titleVisibility: .visible) {
            Button("撤回", role: .destructive) {
                if let c = viewModel.pendingDelete { viewModel.retract(comment: c) }
            }
            Button("取消", role: .cancel) { viewModel.pendingDelete = nil }
        } message: {
            Text("撤回后将显示“该评论已删除”")
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("评论")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Text("\(viewModel.commentCount)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                Spacer()
                // 评论排序切换
                HStack(spacing: 0) {
                    Button(action: { viewModel.switchCommentSort("latest") }) {
                        Text("最新")
                            .font(.system(size: 13, weight: viewModel.commentSortMode == "latest" ? .semibold : .regular))
                            .foregroundColor(
                                viewModel.commentSortMode == "latest"
                                    ? Color(uiColor: ColorPalette.brandPrimary)
                                    : Color(uiColor: ColorPalette.textTertiary)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                    Button(action: { viewModel.switchCommentSort("hot") }) {
                        Text("最热")
                            .font(.system(size: 13, weight: viewModel.commentSortMode == "hot" ? .semibold : .regular))
                            .foregroundColor(
                                viewModel.commentSortMode == "hot"
                                    ? Color(uiColor: ColorPalette.brandPrimary)
                                    : Color(uiColor: ColorPalette.textTertiary)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if viewModel.isLoadingComments && viewModel.comments.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                    Spacer()
                }
                .padding(.vertical, 24)
            } else if viewModel.commentErrorMessage != nil && viewModel.comments.isEmpty {
                VStack(spacing: 12) {
                    Text("评论加载失败")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    Button(action: { viewModel.commentErrorMessage = nil; viewModel.loadInitialComments() }) {
                        Text("重试")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else if viewModel.comments.isEmpty {
                Text("暂无评论，来说一句吧")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.topLevelComments) { comment in
                    VStack(spacing: 6) {
                        CommentRow(
                            comment: comment,
                            isReply: false,
                            onReply: { viewModel.replyingTo = comment },
                            onLike: { viewModel.toggleLike(comment: comment) },
                            onCopy: { viewModel.copy(comment: comment) },
                            onDelete: { viewModel.requestDelete(comment: comment) },
                            canDelete: viewModel.canDelete(comment: comment, isLoggedIn: appState.isLoggedIn)
                        )
                        ForEach(viewModel.replies(for: comment)) { reply in
                            CommentRow(
                                comment: reply,
                                isReply: true,
                                onReply: { viewModel.replyingTo = reply },
                                onLike: { viewModel.toggleLike(comment: reply) },
                                onCopy: { viewModel.copy(comment: reply) },
                                onDelete: { viewModel.requestDelete(comment: reply) },
                                canDelete: viewModel.canDelete(comment: reply, isLoggedIn: appState.isLoggedIn)
                            )
                            .padding(.leading, 20)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .onAppear {
                        if comment.id == viewModel.topLevelComments.last?.id {
                            viewModel.loadMoreComments()
                        }
                    }
                }

                if viewModel.isLoadingMoreComments {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: ColorPalette.brandPrimary)))
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.bottom, appState.isLoggedIn ? 56 : 0)
    }

    private var commentInputBar: some View {
        VStack(spacing: 8) {
            if let replying = viewModel.replyingTo {
                HStack(spacing: 8) {
                    Text("回复 \(replying.nickname ?? "用户")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    Spacer()
                    Button("取消") { viewModel.replyingTo = nil }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                TextField("写一条评论...", text: $draftComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(20)
                Button(action: {
                    let text = draftComment
                    draftComment = ""
                    viewModel.sendComment(text: text)
                }) {
                    if viewModel.isSendingComment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                    }
                }
                .background(
                    draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color(uiColor: ColorPalette.textDisabled)
                        : Color(uiColor: ColorPalette.brandPrimary)
                )
                .clipShape(Circle())
                .disabled(draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingComment)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: ColorPalette.bgPrimary))
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: -2)
    }
}

/// 单条评论行
struct CommentRow: View {
    let comment: Comment
    let isReply: Bool
    let onReply: () -> Void
    let onLike: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    let canDelete: Bool

    private var displayName: String { comment.nickname ?? "用户" }

    private var timeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        if let date = comment.createdAtDate {
            return formatter.localizedString(for: date, relativeTo: Date())
        }
        return "刚刚"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Text(timeText)
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                if isReply, let to = comment.replyToNickname, !to.isEmpty {
                    Text("回复 \(to)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
                Spacer()
                if !comment.isDeleted {
                    Button(action: onLike) {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(comment.isLiked ? Color(uiColor: ColorPalette.brandPrimary) : Color(uiColor: ColorPalette.textSecondary))
                            if comment.likeCount > 0 {
                                Text("\(comment.likeCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                            }
                        }
                    }
                }
            }
            if comment.isDeleted {
                Text("该评论已删除")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            } else {
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                Button("回复", action: onReply)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(10)
        .contextMenu {
            Button("复制", action: onCopy)
            if canDelete {
                Button("撤回", role: .destructive, action: onDelete)
            }
        }
    }
}

/// 帖子图片展示：列表用小缩略条，详情用全宽
enum PostImageStripStyle {
    case thumbnails  // 列表卡片：横向小图
    case fullWidth   // 详情：竖向全宽
}

struct PostImageStrip: View {
    let urls: [String]
    var style: PostImageStripStyle = .thumbnails
    
    var body: some View {
        if urls.isEmpty { EmptyView() }
        else if style == .thumbnails {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(urls.prefix(4), id: \.self) { url in
                        thumbnailView(url: url, size: 64)
                    }
                }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(urls, id: \.self) { url in
                    FullWidthPostImage(url: url)
                }
            }
        }
    }
    
    private func thumbnailView(url: String, size: CGFloat) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            case .empty:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .cornerRadius(8)
    }
}

private struct FullWidthPostImage: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    .frame(height: 120)
            case .empty:
                ProgressView()
                    .frame(height: 120)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
}

/// 简单流式布局，用于标签
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var positions: [CGPoint] = []
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        PostDetailView(post: Post(
            id: "1",
            userId: "u1",
            content: "今日复盘：大盘震荡，坚守价值仓位。",
            nickname: "投资小白",
            images: [],
            tags: ["大盘", "价值投资"],
            likeCount: 10,
            commentCount: 2,
            createdAt: Date().timeIntervalSince1970 * 1000
        ))
        .environmentObject(AppState())
    }
}

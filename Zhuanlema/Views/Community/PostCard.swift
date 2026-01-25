/**
 * 帖子卡片组件 - 金融社区风格
 * 展示交易心得，专业简洁的卡片布局
 */
import SwiftUI

struct PostCard: View {
    let post: Post
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 用户头部信息
            HStack(spacing: 10) {
                // 用户头像
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(uiColor: ColorPalette.brandPrimary),
                                Color(uiColor: ColorPalette.brandSecondary)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(displayNickname.prefix(1))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // 用户名和时间
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayNickname)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // 内容文本
            Text(post.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                .lineLimit(4)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            // 图片缩略条
            if !post.images.isEmpty {
                PostImageStrip(urls: post.images, style: .thumbnails)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            // 标签
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Color(uiColor: ColorPalette.brandLight)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
            }
            
            // 底部操作栏
            HStack(spacing: 20) {
                // 点赞按钮
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(
                                post.isLiked ? 
                                Color(uiColor: ColorPalette.brandPrimary) : 
                                Color(uiColor: ColorPalette.textSecondary)
                            )
                        
                        if post.likeCount > 0 {
                            Text("\(post.likeCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        }
                    }
                }
                
                // 评论按钮
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    }
                }
                
                Spacer()

                // 分享按钮
                ShareLink(item: shareableText, subject: Text("赚了吗 · 心得分享"), message: Text(String(post.content.prefix(300)))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: ColorPalette.bgSecondary).opacity(0.5))
        }
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    /// 显示昵称（优先级：post.nickname > post.user?.nickname > "匿名用户"）
    private var displayNickname: String {
        return post.nickname ?? post.user?.nickname ?? "匿名用户"
    }

    /// 分享用文案（链接为应用 scheme，无 web 页时可分享纯文本）
    private var shareableText: String {
        let snippet = post.content.count > 100 ? String(post.content.prefix(100)) + "…" : post.content
        return "【赚了吗】\(snippet)\nzhuanlema://post/\(post.id)"
    }
    
    /// 格式化时间显示
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        
        if let createdAtDate = post.createdAtDate {
            return formatter.localizedString(for: createdAtDate, relativeTo: Date())
        }
        return "刚刚"
    }
}


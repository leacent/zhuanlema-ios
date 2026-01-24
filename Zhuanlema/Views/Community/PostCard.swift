/**
 * 帖子卡片组件 - 小红书风格
 * 展示帖子封面图、标题、用户信息、点赞等信息
 */
import SwiftUI

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图 (小红书风格核心)
            ZStack(alignment: .topTrailing) {
                if post.images.first != nil {
                    // 实际项目中这里应该用 AsyncImage 或图片缓存库
                    Rectangle()
                        .fill(Color(uiColor: ColorPalette.surfaceLight))
                        .aspectRatio(0.8, contentMode: .fill) // 稍微长一点的比例更符合小红书
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        )
                } else {
                    // 无图片时显示占位色块
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(uiColor: ColorPalette.brandPrimary).opacity(0.1),
                                Color(uiColor: ColorPalette.brandPrimary).opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(0.8, contentMode: .fill)
                }
                
                // 图片数量标识
                if post.images.count > 1 {
                    Image(systemName: "square.fill.on.square.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            .cornerRadius(8)
            .clipped()
            
            // 内容摘要 (小红书标题)
            Text(post.content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                .lineLimit(2)
                .padding(.horizontal, 4)
            
            // 用户信息和点赞
            HStack {
                // 用户信息
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(uiColor: ColorPalette.brandPrimary))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(displayNickname.prefix(1))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(displayNickname)
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 点赞
                Button(action: onLike) {
                    HStack(spacing: 2) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(post.likeCount)")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    /// 显示昵称（优先级：post.nickname > post.user?.nickname > "匿名用户"）
    var displayNickname: String {
        return post.nickname ?? post.user?.nickname ?? "匿名用户"
    }
}


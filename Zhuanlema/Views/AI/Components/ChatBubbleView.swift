/**
 * 对话气泡组件
 * 用户消息靠右（品牌色背景），AI 回复靠左（灰色背景）
 */
import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                aiAvatar
            }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(message.isUser ? .white : Color(uiColor: ColorPalette.textPrimary))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.isUser
                        ? AnyShapeStyle(Color(uiColor: ColorPalette.brandPrimary))
                        : AnyShapeStyle(Color(uiColor: ColorPalette.bgSecondary))
                )
                .cornerRadius(16)

            if !message.isUser { Spacer(minLength: 48) }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(uiColor: ColorPalette.brandPrimary), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)

            Image(systemName: "brain.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubbleView(message: ChatMessage(role: "user", content: "今天该不该割肉？", timestamp: 1))
        ChatBubbleView(message: ChatMessage(role: "assistant", content: "我看了你最近7天的打卡，连续5天觉得亏了。先别急着做决定，情绪激动时的操作往往不是最优解。", timestamp: 2))
    }
    .padding()
}

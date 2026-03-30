/**
 * 对话气泡组件
 * 用户消息靠右（品牌色背景），AI 回复靠左（灰色背景）+ 反馈按钮
 * 支持流式打字机光标效果
 */
import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    var feedback: MessageFeedback = .none
    var isStreaming: Bool = false
    var onFeedback: ((Bool) -> Void)?

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                aiAvatar
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                bubbleContent
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isUser
                            ? AnyShapeStyle(Color(uiColor: ColorPalette.brandPrimary))
                            : AnyShapeStyle(Color(uiColor: ColorPalette.bgSecondary))
                    )
                    .cornerRadius(16)

                if !message.isUser, !isStreaming, onFeedback != nil {
                    feedbackButtons
                }
            }

            if !message.isUser { Spacer(minLength: 48) }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        if isStreaming && !message.isUser {
            (Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            + Text("▍")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            )
        } else {
            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(message.isUser ? .white : Color(uiColor: ColorPalette.textPrimary))
        }
    }

    private var feedbackButtons: some View {
        HStack(spacing: 12) {
            Button(action: { onFeedback?(true) }) {
                Image(systemName: feedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 13))
                    .foregroundColor(feedback == .positive ? Color(uiColor: ColorPalette.brandPrimary) : Color(uiColor: ColorPalette.textTertiary))
            }
            .disabled(feedback != .none)

            Button(action: { onFeedback?(false) }) {
                Image(systemName: feedback == .negative ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 13))
                    .foregroundColor(feedback == .negative ? .orange : Color(uiColor: ColorPalette.textTertiary))
            }
            .disabled(feedback != .none)
        }
        .padding(.leading, 4)
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
        ChatBubbleView(
            message: ChatMessage(role: "assistant", content: "我看了你最近7天的打卡，连续5天觉得亏了。先别急着做决定，情绪激动时的操作往往不是最优解。", timestamp: 2),
            feedback: .none,
            onFeedback: { _ in }
        )
        ChatBubbleView(
            message: ChatMessage(role: "assistant", content: "正在输入的流式效果演示", timestamp: 4),
            isStreaming: true,
            onFeedback: { _ in }
        )
    }
    .padding()
}

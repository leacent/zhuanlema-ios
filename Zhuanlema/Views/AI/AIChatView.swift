/**
 * AI 追问对话视图
 * 气泡布局 + 输入框 + 发送按钮
 */
import SwiftUI

struct AIChatView: View {
    @ObservedObject var viewModel: AIViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .navigationTitle("向赚哥提问")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.startNewConversation() }) {
                    Image(systemName: "plus.bubble")
                        .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
        }
        .alert("对话出错", isPresented: Binding(
            get: { viewModel.chatError != nil },
            set: { if !$0 { viewModel.chatError = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.chatError = nil }
        } message: {
            if let err = viewModel.chatError { Text(err) }
        }
    }

    // MARK: - 消息列表

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        welcomeView
                    }

                    ForEach(viewModel.messages) { msg in
                        ChatBubbleView(message: msg)
                            .id(msg.id)
                    }

                    if viewModel.isGenerating {
                        typingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isGenerating) { generating in
                if generating {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(uiColor: ColorPalette.brandPrimary), .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "brain.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            Text("我是赚哥，你的 AI 投资教练")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))

            Text("我了解你的打卡记录和情绪状态\n有什么投资困惑尽管问我")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                .multilineTextAlignment(.center)

            // 快捷问题
            VStack(spacing: 8) {
                quickQuestionButton("今天该不该割肉？")
                quickQuestionButton("帮我复盘一下这周")
                quickQuestionButton("我最近心态不太好")
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    private func quickQuestionButton(_ text: String) -> some View {
        Button(action: {
            viewModel.inputText = text
            viewModel.sendMessage()
        }) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: ColorPalette.brandPrimary).opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: ColorPalette.brandPrimary).opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
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

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(uiColor: ColorPalette.textTertiary))
                        .frame(width: 6, height: 6)
                        .opacity(0.6)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                            value: viewModel.isGenerating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(16)

            Spacer()
        }
        .id("typing")
    }

    // MARK: - 输入栏

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("问点什么…", text: $viewModel.inputText, axis: .vertical)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(uiColor: ColorPalette.bgSecondary))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit { viewModel.sendMessage() }

            Button(action: { viewModel.sendMessage() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        canSend
                            ? Color(uiColor: ColorPalette.brandPrimary)
                            : Color(uiColor: ColorPalette.textTertiary)
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: ColorPalette.bgPrimary))
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isGenerating
    }
}

#Preview {
    NavigationStack {
        AIChatView(viewModel: AIViewModel())
    }
}

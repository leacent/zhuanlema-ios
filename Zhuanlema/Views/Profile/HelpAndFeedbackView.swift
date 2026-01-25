/**
 * 帮助与反馈页面
 * 帮助说明 + 反馈表单
 */
import SwiftUI

struct HelpAndFeedbackView: View {
    @State private var feedbackText = ""
    @State private var contactText = ""
    @State private var submitting = false
    @State private var submitted = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let databaseService = CloudBaseDatabaseService.shared
    
    var body: some View {
        ZStack {
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 帮助
                    VStack(alignment: .leading, spacing: 12) {
                        Label("帮助", systemImage: "questionmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                        Text("赚了吗是一款记录每日盈亏、交流投资心得的应用。您可以：\n• 在首页进行每日打卡（今天赚了还是亏了）\n• 在社区浏览、发布帖子\n• 在行情页查看市场概览与自选")
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(12)
                    
                    // 反馈
                    VStack(alignment: .leading, spacing: 12) {
                        Label("反馈", systemImage: "envelope.fill")
                            .font(.headline)
                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                        TextField("请描述您的问题或建议", text: $feedbackText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...8)
                        TextField("联系方式（选填）", text: $contactText)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        Button {
                            Task { await submit() }
                        } label: {
                            Text(submitted ? "已提交" : "提交反馈")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(submitted ? Color(uiColor: ColorPalette.textTertiary) : Color(uiColor: ColorPalette.brandPrimary))
                                .cornerRadius(12)
                        }
                        .disabled(submitting || feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || submitted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(uiColor: ColorPalette.bgSecondary))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("帮助与反馈")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }
    
    private func submit() async {
        let content = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        submitting = true
        errorMessage = nil
        defer { submitting = false }
        do {
            try await databaseService.submitFeedback(content: content, contact: contactText.isEmpty ? nil : contactText)
            submitted = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    NavigationView {
        HelpAndFeedbackView()
    }
}

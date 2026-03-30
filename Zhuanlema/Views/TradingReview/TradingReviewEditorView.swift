/**
 * 个人复盘日记编辑页
 * 标签化快速记录 + 自由文本 + 满意度评分
 */
import SwiftUI

struct TradingReviewEditorView: View {
    @StateObject private var viewModel = TradingReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFocused: Bool

    var initialDate: String?
    var checkInResult: String?
    var checkInMagnitude: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        dateHeader
                        actionSection
                        driverSection
                        emotionSection
                        diarySection
                        satisfactionSection
                        saveButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("今日复盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
            }
            .onAppear {
                if let date = initialDate {
                    viewModel.reviewDate = date
                }
                viewModel.checkInResult = checkInResult
                viewModel.checkInMagnitude = checkInMagnitude
                viewModel.loadExistingReview()
            }
            .onChange(of: viewModel.didSaveSuccessfully) { success in
                if success { dismiss() }
            }
            .alert("保存失败", isPresented: .init(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(viewModel.saveError ?? "")
            }
        }
    }

    // MARK: - 日期

    private var dateHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
            Text(formatDisplayDate(viewModel.reviewDate))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            Spacer()
        }
    }

    // MARK: - 今天做了什么

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("今天做了什么？")

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ReviewAction.allCases) { action in
                    TagButton(
                        label: action.label,
                        icon: action.icon,
                        isSelected: viewModel.selectedActions.contains(action.rawValue)
                    ) {
                        viewModel.toggleAction(action.rawValue)
                    }
                }
            }
        }
    }

    // MARK: - 决策驱动

    private var driverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("什么驱动了决策？")

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ReviewDriver.allCases) { driver in
                    TagButton(
                        label: driver.label,
                        isSelected: viewModel.selectedDrivers.contains(driver.rawValue)
                    ) {
                        viewModel.toggleDriver(driver.rawValue)
                    }
                }
            }
        }
    }

    // MARK: - 情绪

    private var emotionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("此刻心情？")

            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ReviewEmotion.allCases) { emotion in
                    TagButton(
                        label: "\(emotion.emoji) \(emotion.label)",
                        isSelected: viewModel.selectedEmotions.contains(emotion.rawValue)
                    ) {
                        viewModel.toggleEmotion(emotion.rawValue)
                    }
                }
            }
        }
    }

    // MARK: - 自由日记

    private var diarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("写点什么…")

            ZStack(alignment: .topLeading) {
                if viewModel.content.isEmpty {
                    Text("今天的操作思路、得失、教训…随便写")
                        .font(.system(size: 14))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $viewModel.content)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    .focused($isTextFocused)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            }
            .frame(minHeight: 120)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isTextFocused
                            ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.5)
                            : Color(uiColor: ColorPalette.bgSecondary),
                        lineWidth: 1.5
                    )
            )

            HStack {
                Spacer()
                Text("\(viewModel.content.count)/2000")
                    .font(.system(size: 11))
                    .foregroundColor(
                        viewModel.content.count > 1800
                            ? Color(uiColor: ColorPalette.brandPrimary)
                            : Color(uiColor: ColorPalette.textTertiary)
                    )
            }
        }
    }

    // MARK: - 满意度

    private var satisfactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("今天操作满意吗？")

            HStack(spacing: 0) {
                ForEach(ReviewSatisfaction.allCases) { level in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.satisfaction = level.rawValue
                        }
                    }) {
                        Text(level.emoji)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.satisfaction == level.rawValue
                                    ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.12)
                                    : Color.clear
                            )
                            .cornerRadius(10)
                            .scaleEffect(viewModel.satisfaction == level.rawValue ? 1.15 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(6)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .cornerRadius(14)
        }
    }

    // MARK: - 保存按钮

    private var saveButton: some View {
        Button(action: { viewModel.save() }) {
            HStack(spacing: 8) {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
                Text("保存复盘")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: viewModel.canSave
                        ? [Color(uiColor: ColorPalette.brandPrimary), Color(uiColor: ColorPalette.brandSecondary)]
                        : [Color(uiColor: ColorPalette.textTertiary).opacity(0.4), Color(uiColor: ColorPalette.textTertiary).opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .padding(.bottom, 20)
    }

    // MARK: - 辅助

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
    }

    private func formatDisplayDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let weekday = Calendar.current.component(.weekday, from: date)
        let names = ["", "日", "一", "二", "三", "四", "五", "六"]
        return "\(parts[0])年\(parts[1])月\(parts[2])日 周\(names[weekday])"
    }
}

// MARK: - 标签按钮组件

private struct TagButton: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .foregroundColor(
                isSelected
                    ? Color(uiColor: ColorPalette.brandPrimary)
                    : Color(uiColor: ColorPalette.textSecondary)
            )
            .background(
                isSelected
                    ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.1)
                    : Color(uiColor: ColorPalette.bgSecondary)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? Color(uiColor: ColorPalette.brandPrimary).opacity(0.3)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TradingReviewEditorView()
}

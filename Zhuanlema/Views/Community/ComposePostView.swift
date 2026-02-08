/**
 * 发布帖子页面
 * 支持文字、图片、标签发布，带草稿保存、上传进度、错误/成功反馈
 */
import SwiftUI
import PhotosUI

struct ComposePostView: View {
    /// 发布成功后的回调（传回 postId，供列表乐观插入）
    var onPublished: ((String) -> Void)?

    @StateObject private var viewModel = ComposePostViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showDiscardConfirm = false
    @FocusState private var isContentFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        contentInputSection
                        Divider().background(Color(uiColor: ColorPalette.divider))
                        imagePickerSection
                        Divider().background(Color(uiColor: ColorPalette.divider))
                        tagInputSection
                    }
                }

                // 底部发布按钮
                VStack {
                    Spacer()
                    publishButton
                }
            }
            .navigationTitle("发布心得")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleDismiss) {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isContentFocused = true
            }
        }
        .onChange(of: viewModel.publishSucceeded) { succeeded in
            if succeeded {
                // Haptic 反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }
        // 发布错误 alert
        .alert("发布失败", isPresented: Binding(
            get: { viewModel.publishError != nil },
            set: { if !$0 { viewModel.publishError = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.publishError = nil }
        } message: {
            if let msg = viewModel.publishError { Text(msg) }
        }
        // 关闭确认
        .confirmationDialog("放弃编辑？", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("放弃", role: .destructive) {
                viewModel.clearDraft()
                dismiss()
            }
            Button("继续编辑", role: .cancel) {}
        } message: {
            Text("已输入的内容将不会保存")
        }
    }

    // MARK: - Dismiss Guard

    private func handleDismiss() {
        if viewModel.hasUnsavedContent {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    // MARK: - Content Input

    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分享你的交易心得")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: ColorPalette.bgSecondary))
                    .stroke(
                        isContentFocused ?
                            Color(uiColor: ColorPalette.brandPrimary) :
                            Color(uiColor: ColorPalette.border),
                        lineWidth: isContentFocused ? 1.5 : 1
                    )

                TextEditor(text: $viewModel.content)
                    .focused($isContentFocused)
                    .font(.system(size: 16))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    .padding(12)
                    .background(Color.clear)
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)

                if viewModel.content.isEmpty {
                    Text("今天市场怎么样？聊聊你的操作和想法...")
                        .font(.system(size: 16))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 200)

            HStack {
                Spacer()
                Text("\(viewModel.content.count)/\(viewModel.maxContentLength)")
                    .font(.system(size: 12))
                    .foregroundColor(
                        viewModel.content.count > viewModel.maxContentLength ?
                            Color(uiColor: ColorPalette.error) :
                            Color(uiColor: ColorPalette.textTertiary)
                    )
            }
        }
        .padding(16)
    }

    // MARK: - Image Picker

    private var imagePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                Text("添加图片")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                Spacer()
                Text("\(viewModel.selectedImages.count)/\(viewModel.maxImages)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: viewModel.selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)

                        Button(action: { viewModel.selectedImages.remove(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .offset(x: 4, y: -4)
                    }
                }

                if viewModel.selectedImages.count < viewModel.maxImages {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: viewModel.maxImages - viewModel.selectedImages.count,
                        matching: .images
                    ) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                            Text("添加")
                                .font(.system(size: 12))
                                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(uiColor: ColorPalette.bgSecondary))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(uiColor: ColorPalette.border), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                    .onChange(of: selectedPhotos) { _ in
                        loadSelectedPhotos()
                    }
                }
            }
        }
        .padding(16)
    }

    // MARK: - Tag Input

    private var tagInputSection: some View {
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

            TextField("例如: 大盘 涨停 价值投资", text: $viewModel.tagInput)
                .font(.system(size: 15))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                .padding(12)
                .background(Color(uiColor: ColorPalette.bgSecondary))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: ColorPalette.border), lineWidth: 1)
                )

            if !viewModel.parsedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.parsedTags, id: \.self) { tag in
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
    }

    // MARK: - Publish Button

    private var publishButton: some View {
        Button(action: { viewModel.publish() }) {
            HStack {
                if viewModel.isPublishing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    if let progress = viewModel.progressText {
                        Text(progress)
                            .font(.system(size: 15, weight: .medium))
                    }
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
                viewModel.canPublish ?
                    Color(uiColor: ColorPalette.brandPrimary) :
                    Color(uiColor: ColorPalette.textDisabled)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.canPublish)
        .padding(16)
        .background(Color(uiColor: ColorPalette.bgPrimary))
        .animation(.easeOut(duration: 0.2), value: viewModel.canPublish)
    }

    // MARK: - Helpers

    private func loadSelectedPhotos() {
        Task {
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   viewModel.selectedImages.count < viewModel.maxImages {
                    viewModel.selectedImages.append(uiImage)
                }
            }
            selectedPhotos = []
        }
    }
}

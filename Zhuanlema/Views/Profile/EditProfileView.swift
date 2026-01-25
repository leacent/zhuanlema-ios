/**
 * 编辑资料页面
 * 通过云函数 updateProfile / uploadAvatar 更新昵称与头像
 */
import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @State private var avatar: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var saving = false
    @State private var uploadingAvatar = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var dismissOnAlertClose = false
    @State private var showSuccessTip = false
    /// 仅用于编辑页内展示（上传后为临时 URL）；提交时用 avatar（fileID 或旧 URL）
    @State private var avatarDisplayURL: String = ""

    let initialUser: User
    /// 保存成功后调用（异步），在此回调中刷新「我的」页后再关闭
    var onSaved: ((User) async -> Void)?

    private let userRepository = UserRepository()
    private let databaseService = CloudBaseDatabaseService.shared
    private let storageService = CloudBaseStorageService.shared

    private let nicknameMaxLength = 20

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(uiColor: ColorPalette.bgPrimary)
                    .ignoresSafeArea()

                Form {
                    Section {
                        TextField("昵称", text: $nickname)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: nickname) { _, newValue in
                                if newValue.count > nicknameMaxLength {
                                    nickname = String(newValue.prefix(nicknameMaxLength))
                                }
                            }

                        HStack(spacing: 16) {
                            avatarView
                            VStack(alignment: .leading, spacing: 8) {
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    if uploadingAvatar {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                        Text("上传中…")
                                            .font(.subheadline)
                                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                                    } else {
                                        Text("更换头像")
                                            .font(.subheadline)
                                            .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                    }
                                }
                                .disabled(uploadingAvatar || saving)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("资料")
                    }
                }
                .scrollContentBackground(.hidden)

                if showSuccessTip {
                    successTipView
                        .transition(.opacity)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await save() } }
                        .disabled(saving || nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                        .foregroundColor(saving ? Color(uiColor: ColorPalette.textTertiary) : Color(uiColor: ColorPalette.brandPrimary))
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("确定", role: .cancel) {
                    if dismissOnAlertClose { dismiss() }
                }
            } message: {
                Text(errorMessage ?? "未知错误")
            }
        }
        .onAppear {
            nickname = initialUser.nickname
            if nickname.count > nicknameMaxLength {
                nickname = String(nickname.prefix(nicknameMaxLength))
            }
            avatar = initialUser.avatar
            avatarDisplayURL = initialUser.avatar.hasPrefix("http") ? initialUser.avatar : ""
        }
        .onChange(of: selectedItem) { _, newItem in
            Task { await uploadSelectedPhoto(newItem) }
        }
    }

    /// 编辑页内展示用：优先用上传后的临时 URL，否则用 avatar（若为 https）
    private var avatarDisplayValue: String {
        if !avatarDisplayURL.isEmpty { return avatarDisplayURL }
        if avatar.hasPrefix("http") { return avatar }
        return ""
    }

    @ViewBuilder
    private var avatarView: some View {
        Group {
            if let url = URL(string: avatarDisplayValue), !avatarDisplayValue.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        avatarPlaceholderCircle
                    @unknown default:
                        avatarPlaceholderCircle
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            } else {
                avatarPlaceholderCircle
            }
        }
        .frame(width: 64, height: 64)
    }

    private var avatarPlaceholderCircle: some View {
        Circle()
            .fill(Color(uiColor: ColorPalette.brandPrimary))
            .overlay(
                Text(String(nickname.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var successTipView: some View {
        Text("保存成功")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(uiColor: ColorPalette.success))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(uiColor: SemanticColors.alertSuccessBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(uiColor: ColorPalette.success).opacity(0.3), lineWidth: 1)
            )
            .padding(.top, 12)
    }

    /// 选择图片后：压缩为 base64，调用云函数 uploadAvatar，拿到 URL 后更新本地 avatar
    private func uploadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item,
              let token = userRepository.getCurrentAccessToken() else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            await MainActor.run {
                errorMessage = "无法读取图片"
                showError = true
                selectedItem = nil
            }
            return
        }
        await MainActor.run { uploadingAvatar = true; selectedItem = nil }
        defer { Task { @MainActor in uploadingAvatar = false } }
        guard let base64 = storageService.compressAndEncodeForAvatar(image) else {
            await MainActor.run {
                errorMessage = "图片处理失败"
                showError = true
            }
            return
        }
        do {
            let (url, fileID) = try await databaseService.uploadAvatar(accessToken: token, imageBase64: base64)
            await MainActor.run {
                avatar = fileID
                avatarDisplayURL = url
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// 保存：调用云函数 updateProfile 更新昵称/头像，成功后拉取最新资料并回调 onSaved
    private func save() async {
        await MainActor.run {
            saving = true
            errorMessage = nil
            dismissOnAlertClose = false
        }
        defer { Task { @MainActor in saving = false } }
        do {
            let n = nickname.trimmingCharacters(in: .whitespaces)
            let a = avatar.trimmingCharacters(in: .whitespaces)
            try await userRepository.updateProfile(nickname: n.isEmpty ? nil : n, avatar: a.isEmpty ? nil : a)
            let updated = (try? await userRepository.refreshProfile()) ?? userRepository.getCurrentUser() ?? initialUser
            await onSaved?(updated)
            await MainActor.run { showSuccessTip = true }
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                showSuccessTip = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                if let e = error as? UserRepositoryError, case .sessionExpired = e {
                    dismissOnAlertClose = true
                }
                showError = true
            }
        }
    }
}

#Preview {
    EditProfileView(initialUser: User(
        id: "preview",
        phoneNumber: nil,
        nickname: "测试用户",
        avatar: "",
        createdAt: Date()
    ))
}

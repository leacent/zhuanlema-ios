/**
 * 消息通知页面
 */
import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    @State private var loading = false
    @State private var errorMessage: String?
    
    private let userRepository = UserRepository()
    private let databaseService = CloudBaseDatabaseService.shared
    
    var body: some View {
        ZStack {
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()
            
            if loading && notifications.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    Text(err)
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if notifications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell")
                        .font(.system(size: 48))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    Text("暂无消息通知")
                        .font(.subheadline)
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(notifications) { item in
                        NotificationRow(item: item) {
                            Task { await markRead(item) }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("消息通知")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }
    
    private func load() async {
        guard let userId = userRepository.getCurrentUser()?.id else { return }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            notifications = try await databaseService.getNotifications(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func markRead(_ item: NotificationItem) async {
        guard let userId = userRepository.getCurrentUser()?.id else { return }
        guard !item.read else { return }
        do {
            try await databaseService.markNotificationRead(notificationId: item.id, userId: userId)
            if let idx = notifications.firstIndex(where: { $0.id == item.id }) {
                notifications[idx].read = true
            }
        } catch {
            // silent fail
        }
    }
}

private struct NotificationRow: View {
    let item: NotificationItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    if !item.read {
                        Circle()
                            .fill(Color(uiColor: ColorPalette.brandPrimary))
                            .frame(width: 8, height: 8)
                    }
                    Spacer()
                }
                Text(item.body)
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    .lineLimit(2)
                Text(item.createdAtDate, style: .date)
                    .font(.caption)
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color(uiColor: ColorPalette.bgSecondary))
    }
}

#Preview {
    NavigationView {
        NotificationsView()
    }
}

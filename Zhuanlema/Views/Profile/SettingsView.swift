/**
 * 设置页面
 * 本地选项：清除缓存、关于
 */
import SwiftUI

struct SettingsView: View {
    @State private var showClearCacheAlert = false
    @State private var cacheCleared = false
    
    private let checkInRepository = CheckInRepository()
    
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: ColorPalette.bgPrimary)
                .ignoresSafeArea()
            
            Form {
                Section {
                    Button {
                        showClearCacheAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                                .frame(width: 24)
                            Text("清除打卡本地缓存")
                                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                            Spacer()
                            if cacheCleared {
                                Text("已清除")
                                    .font(.caption)
                                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                            }
                        }
                    }
                } footer: {
                    Text("仅清除本机打卡记录缓存，不影响云端数据。")
                }
                
                Section {
                    HStack {
                        Text("版本")
                            .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                    }
                } header: {
                    Text("关于")
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("清除缓存", isPresented: $showClearCacheAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                checkInRepository.clearLocalCheckInCache()
                cacheCleared = true
            }
        } message: {
            Text("确定要清除本机打卡缓存吗？云端数据不会受影响。")
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

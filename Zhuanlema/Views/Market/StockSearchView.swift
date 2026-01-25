/**
 * 股票搜索页
 * 支持按名称或代码搜索（代码直查 + 远程联想 + 本地回退），选择后拉取行情并进入详情
 */
import SwiftUI

struct StockSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var results: [WatchlistItem] = []
    @State private var selectedItem: WatchlistItem?
    @State private var loadingDetail = false
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearchFieldPresented = false

    private let marketDataService = MarketDataService.shared
    private let debounceInterval: UInt64 = 300_000_000 // 0.3s

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if searching {
                    searchLoadingView
                } else if results.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyState
                } else if results.isEmpty {
                    hintState
                } else {
                    resultList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: ColorPalette.bgPrimary))
            .navigationTitle("搜索股票")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, isPresented: $isSearchFieldPresented, placement: .toolbar, prompt: "名称或代码，如 贵州茅台、300436、00700、AAPL")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isSearchFieldPresented = true
                }
            }
            .onChange(of: searchText) { _, newValue in
                performSearchDebounced(keyword: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                }
            }
            .fullScreenCover(item: $selectedItem) { item in
                StockDetailView(item: item)
                    .overlay(alignment: .topLeading) {
                        Button {
                            selectedItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
            }
        }
    }

    /// 防抖搜索：延迟 0.3s 后执行，避免每键触发
    private func performSearchDebounced(keyword: String) {
        searchTask?.cancel()
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            results = []
            searching = false
            return
        }
        searchTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceInterval)
            } catch { return }
            guard !Task.isCancelled else { return }
            await MainActor.run { searching = true }
            let list = await marketDataService.searchStocks(keyword: trimmed)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                results = list
                searching = false
            }
        }
    }

    private var searchLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.1)
            Text("搜索中…")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            Text("未找到「\(searchText.trimmingCharacters(in: .whitespaces))」")
                .font(.headline)
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            Text("可尝试其他名称或代码")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hintState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            Text("输入股票名称或代码")
                .font(.headline)
                .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            Text("例如：贵州茅台、300436、00700、AAPL")
                .font(.subheadline)
                .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(results) { item in
                    resultRow(item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func resultRow(_ item: WatchlistItem) -> some View {
        Button {
            loadAndOpenDetail(item)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                    Text(item.displayCode)
                        .font(.system(size: 13))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
                Spacer(minLength: 8)
                if let change = item.changePercent {
                    Text(String(format: "%+.2f%%", change))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(change >= 0 ? Color(uiColor: ColorPalette.tradingUp) : Color(uiColor: ColorPalette.tradingDown))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(uiColor: ColorPalette.bgSecondary))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadAndOpenDetail(_ item: WatchlistItem) {
        loadingDetail = true
        Task {
            do {
                let list = try await marketDataService.fetchStockData(codes: [item.code])
                await MainActor.run {
                    loadingDetail = false
                    selectedItem = list.first ?? item
                }
            } catch {
                await MainActor.run {
                    loadingDetail = false
                    selectedItem = item
                }
            }
        }
    }
}

#Preview {
    StockSearchView()
}

/**
 * 打卡日历页
 * 按月份展示每日打卡情况：赚了 / 亏了
 */
import SwiftUI

struct CheckInCalendarView: View {
    @State private var displayYear: Int
    @State private var displayMonth: Int
    @State private var records: [CheckIn] = []
    @State private var loading = false

    private let checkInRepository = CheckInRepository()
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    init(initialYear: Int? = nil, initialMonth: Int? = nil) {
        let calendar = Calendar.current
        let now = Date()
        _displayYear = State(initialValue: initialYear ?? calendar.component(.year, from: now))
        _displayMonth = State(initialValue: initialMonth ?? calendar.component(.month, from: now))
    }

    /// 记录按日期查找：date (yyyy-MM-dd) -> "yes" | "no"
    private var resultByDate: [String: String] {
        Dictionary(uniqueKeysWithValues: records.map { ($0.date, $0.result) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                monthNavigator
                calendarGrid
                legend
            }
            .padding()
        }
        .background(Color(uiColor: ColorPalette.bgPrimary))
        .navigationTitle("打卡日历")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(displayYear)-\(displayMonth)") {
            await loadMonth()
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                prevMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("\(displayYear)年\(displayMonth)月")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
            Spacer()
            Button {
                nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
    }

    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // 星期头
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            if loading {
                ProgressView()
                    .padding(.vertical, 40)
            } else {
                let days = daysForDisplay()
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(days, id: \.id) { day in
                        dayCell(day)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private struct DayItem: Identifiable {
        let id: String
        let day: Int?
        let dateString: String?
    }

    private func daysForDisplay() -> [DayItem] {
        let calendar = Calendar.current
        guard let first = calendar.date(from: DateComponents(year: displayYear, month: displayMonth, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: first)
        let leadingBlanks = firstWeekday - 1
        let daysInMonth = range.count
        var items: [DayItem] = []
        for _ in 0..<leadingBlanks {
            items.append(DayItem(id: "blank-\(items.count)", day: nil, dateString: nil))
        }
        for d in 1...daysInMonth {
            let dateStr = String(format: "%04d-%02d-%02d", displayYear, displayMonth, d)
            items.append(DayItem(id: dateStr, day: d, dateString: dateStr))
        }
        return items
    }

    @ViewBuilder
    private func dayCell(_ day: DayItem) -> some View {
        if let d = day.day, let dateStr = day.dateString {
            let result = resultByDate[dateStr]
            VStack(spacing: 4) {
                Text("\(d)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                if result == "yes" {
                    Text("赚")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: ColorPalette.success))
                        .cornerRadius(4)
                } else if result == "no" {
                    Text("亏")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: ColorPalette.error))
                        .cornerRadius(4)
                } else {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: ColorPalette.bgPrimary))
            )
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private var legend: some View {
        HStack(spacing: 24) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.success))
                    .frame(width: 16, height: 16)
                Text("赚了")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: ColorPalette.error))
                    .frame(width: 16, height: 16)
                Text("亏了")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textSecondary))
            }
        }
    }

    private func prevMonth() {
        if displayMonth == 1 {
            displayYear -= 1
            displayMonth = 12
        } else {
            displayMonth -= 1
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        if displayYear == currentYear && displayMonth == currentMonth { return }
        if displayMonth == 12 {
            displayYear += 1
            displayMonth = 1
        } else {
            displayMonth += 1
        }
    }

    private func loadMonth() async {
        loading = true
        defer { loading = false }
        do {
            records = try await checkInRepository.getCheckInHistory(year: displayYear, month: displayMonth)
        } catch {
            records = []
        }
    }
}

#Preview {
    NavigationView {
        CheckInCalendarView()
    }
}

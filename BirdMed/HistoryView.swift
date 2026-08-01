import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: DataStore
    @State private var filterType: HistoryRecord.HistoryType? = nil
    @State private var searchText = ""

    var displayed: [HistoryRecord] {
        var result = store.history
        if let f = filterType { result = result.filter { $0.type == f } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.action.localizedCaseInsensitiveContains(searchText) ||
                $0.target.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(.textInactive)
                TextField("Search history...", text: $searchText)
                    .font(.system(size: 16)).foregroundColor(.textPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.textInactive)
                    }
                }
            }
            .padding(12)
            .background(Color.cardBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.cardBg)

            // Type filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    HistFilterChip(label: "All", isSelected: filterType == nil, color: .primaryGreen) {
                        withAnimation(.appSpring) { filterType = nil }
                    }
                    ForEach(HistoryRecord.HistoryType.allCases, id: \.rawValue) { t in
                        HistFilterChip(label: t.rawValue, isSelected: filterType == t, color: t.color) {
                            withAnimation(.appSpring) { filterType = filterType == t ? nil : t }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
            }
            .background(Color.cardBg)

            if displayed.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath", title: "No history",
                               message: "Actions on your farm will appear here.")
                    .padding(.top, 60)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedByDay.keys.sorted(by: >), id: \.self) { day in
                            Section(header: DayHeader(date: day)) {
                                ForEach(groupedByDay[day]!) { record in
                                    HistoryRow(record: record)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .tabBarBottomPadding()
                }
            }

            Spacer(minLength: 0)
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    var groupedByDay: [Date: [HistoryRecord]] {
        let cal = Calendar.current
        var dict: [Date: [HistoryRecord]] = [:]
        for r in displayed {
            let day = cal.startOfDay(for: r.date)
            dict[day, default: []].append(r)
        }
        return dict
    }
}

private struct HistFilterChip: View {
    let label: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? color : Color.freshBg).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.dividerGreen, lineWidth: 1))
        }
    }
}

private struct DayHeader: View {
    let date: Date
    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(date) }
    var label: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(LinearGradient.appBg)
    }
}

private struct HistoryRow: View {
    let record: HistoryRecord

    var body: some View {
        HStack(spacing: 14) {
            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(record.type.color)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.dividerGreen)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 10)

            HStack(spacing: 12) {
                IconBadge(icon: record.type.icon, color: record.type.color, size: 34)
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.action)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                    Text(record.target)
                        .font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(2)
                }
                Spacer()
                Text(record.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 11)).foregroundColor(.textInactive)
            }
            .padding(10)
            .background(Color.cardBg)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(minHeight: 52)
    }
}

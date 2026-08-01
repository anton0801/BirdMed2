import SwiftUI

enum AppTab: Int, CaseIterable {
    case dashboard, birds, vaccination, calendar, more
    var label: String {
        switch self {
        case .dashboard:  return "Dashboard"
        case .birds:      return "Birds"
        case .vaccination:return "Vaccines"
        case .calendar:   return "Calendar"
        case .more:       return "More"
        }
    }
    var icon: String {
        switch self {
        case .dashboard:  return "house.fill"
        case .birds:      return "pawprint.fill"
        case .vaccination:return "staroflife.fill"
        case .calendar:   return "calendar"
        case .more:       return "ellipsis.circle.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var tabBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:   DashboardView(selectedTab: $selectedTab)
                case .birds:       BirdGroupsView()
                case .vaccination: VaccinationView()
                case .calendar:    CalendarView()
                case .more:        MoreMenuView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Scrollable screens read this to reserve room for the bar.
            .environment(\.tabBarInset, tabBarHeight)

            // The bar sits inside the safe area; only its background bleeds
            // into the home-indicator strip, so the measured height is exactly
            // what content needs to clear.
            CustomTabBar(selectedTab: $selectedTab)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: TabBarHeightKey.self, value: proxy.size.height)
                    }
                )
        }
        .onPreferenceChange(TabBarHeightKey.self) { tabBarHeight = $0 }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var store: DataStore

    private func badgeCount(for tab: AppTab) -> Int {
        switch tab {
        case .vaccination: return store.overdueVaccinations.count
        case .more:        return store.pendingAlerts.count
        default:           return 0
        }
    }

    private func badgeColor(for tab: AppTab) -> Color {
        tab == .vaccination ? .statusDanger : .statusRisk
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                let isSelected = tab == selectedTab
                let badge = badgeCount(for: tab)

                Button {
                    withAnimation(.appSpring) { selectedTab = tab }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Color.primaryGreen.opacity(0.15))
                                    .frame(width: 48, height: 32)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .primaryGreen : .textInactive)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                        }
                        .frame(width: 48, height: 32)
                        .overlay(alignment: .topTrailing) {
                            if badge > 0 {
                                Circle()
                                    .fill(badgeColor(for: tab))
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }

                        Text(tab.label)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .primaryGreen : .textInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(badge > 0 ? "\(tab.label), \(badge) needing attention" : tab.label)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .animation(.appSpring, value: selectedTab)
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            ZStack {
                Color.cardBg
                Rectangle()
                    .fill(Color.dividerGreen)
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
        )
    }
}

// MARK: - More Menu
struct MoreMenuView: View {
    @EnvironmentObject var store: DataStore

    private struct MenuItem: Identifiable {
        let id: String
        let title: String
        let icon: String
        let color: Color
    }

    private let menuItems: [MenuItem] = [
        MenuItem(id: "coops",    title: "Coops & Housing", icon: "building.2.fill",       color: .actionOrange),
        MenuItem(id: "meds",     title: "Medications",     icon: "pills.fill",            color: .statusDanger),
        MenuItem(id: "tasks",    title: "Tasks",           icon: "checklist",             color: .primaryBlue),
        MenuItem(id: "alerts",   title: "Alerts",          icon: "bell.badge.fill",       color: .statusRisk),
        MenuItem(id: "recs",     title: "Recommendations", icon: "lightbulb.fill",        color: .primaryGreen),
        MenuItem(id: "notes",    title: "Notes & Photos",  icon: "note.text",             color: .accentCyan),
        MenuItem(id: "reports",  title: "Reports",         icon: "chart.bar.fill",        color: .primaryBlue),
        MenuItem(id: "expenses", title: "Expenses",        icon: "dollarsign.circle.fill", color: .actionOrange),
        MenuItem(id: "history",  title: "History",         icon: "clock.arrow.circlepath", color: .textSecondary),
        MenuItem(id: "settings", title: "Settings",        icon: "gearshape.fill",        color: .textInactive),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(menuItems) { item in
                        NavigationLink(destination: destinationView(for: item.id)) {
                            HStack(spacing: 16) {
                                IconBadge(icon: item.icon, color: item.color, size: 44)
                                Text(item.title)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                if item.id == "alerts" && !store.pendingAlerts.isEmpty {
                                    Text("\(store.pendingAlerts.count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.statusRisk)
                                        .cornerRadius(10)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.textInactive)
                            }
                            .padding(14)
                            .background(Color.cardBg)
                            .cornerRadius(16)
                            .appShadow()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .tabBarBottomPadding()
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func destinationView(for id: String) -> some View {
        switch id {
        case "coops":    CoopsView()
        case "meds":     MedicationsView()
        case "tasks":    TasksView()
        case "alerts":   AlertsView()
        case "recs":     RecommendationsView()
        case "notes":    NotesView()
        case "reports":  ReportsView()
        case "expenses": ExpensesView()
        case "history":  HistoryView()
        case "settings": SettingsView()
        default:         EmptyView()
        }
    }
}

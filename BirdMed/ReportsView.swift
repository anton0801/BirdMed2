import SwiftUI

/// Reporting window. Previously the picker only re-ran an animation; it now
/// actually scopes every dated figure on the screen.
enum ReportPeriod: Int, CaseIterable, Identifiable {
    case week, month, quarter

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .week:    return "7 Days"
        case .month:   return "30 Days"
        case .quarter: return "90 Days"
        }
    }
    var days: Int {
        switch self {
        case .week:    return 7
        case .month:   return 30
        case .quarter: return 90
        }
    }
    var phrase: String { "the last \(days) days" }

    func start(from now: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now) ?? now
    }
}

struct ReportsView: View {
    @EnvironmentObject var store: DataStore
    @State private var period: ReportPeriod = .month
    @State private var animBars = false
    @State private var sharePayload: SharePayload? = nil

    private var periodStart: Date { period.start() }

    /// Vaccinations whose scheduled date falls inside the window, plus anything
    /// still overdue — an overdue entry from four months ago is exactly what a
    /// keeper needs to see, so it is never filtered out.
    private var periodVaccinations: [Vaccination] {
        store.vaccinations.filter { $0.scheduledDate >= periodStart || $0.isOverdue }
    }
    private var periodMedications: [Medication] {
        store.medications.filter { $0.endDate >= periodStart }
    }
    private var periodExpenses: [Expense] {
        store.expenses.filter { $0.date >= periodStart }
    }
    private var periodTotal: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Picker("Period", selection: $period) {
                    ForEach(ReportPeriod.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: period) { _ in
                    animBars = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { animBars = true }
                    }
                }

                Text("Showing \(period.phrase). Totals below cover this window only.")
                    .font(.system(size: 12))
                    .foregroundColor(.textInactive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                DisclaimerBanner()
                    .padding(.horizontal, 16)

                OverallStatsCard(vaccinations: periodVaccinations, medications: periodMedications)
                VaccinationChartCard(vaccinations: periodVaccinations, animBars: $animBars)
                GroupStatusCard(animBars: $animBars)
                ExpenseBreakdownCard(expenses: periodExpenses, total: periodTotal, animBars: $animBars)
                AttentionCard()

                Button {
                    sharePayload = SharePayload(text: generateReportText())
                } label: {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { animBars = true }
            }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(text: payload.text)
        }
    }

    private func generateReportText() -> String {
        """
        BirdMed report — \(Date().formatted(.dateTime.month(.wide).day().year()))
        Window: \(period.phrase)

        FLOCK (current)
        Total birds: \(store.totalBirds)
        Groups: \(store.birdGroups.count)
        Coops: \(store.coops.count)

        STATUS AS RECORDED BY THE KEEPER
        Healthy: \(store.birdGroups.filter { $0.status == .healthy }.count) groups
        At risk: \(store.birdGroups.filter { $0.status == .atRisk }.count) groups
        Sick or under treatment: \(store.birdGroups.filter { $0.status == .sick || $0.status == .underTreatment }.count) groups

        VACCINATION ENTRIES (\(period.phrase))
        Completed: \(periodVaccinations.filter { $0.isCompleted }.count)
        Upcoming: \(periodVaccinations.filter { $0.isUpcoming }.count)
        Overdue: \(store.overdueVaccinations.count)

        MEDICATION ENTRIES (\(period.phrase))
        Active: \(store.activeMedications.count)
        Completed: \(periodMedications.filter { $0.isCompleted }.count)

        EXPENSES (\(period.phrase))
        Total: \(Formatters.currency(periodTotal))

        OPEN ALERTS
        \(store.pendingAlerts.count)

        Generated by BirdMed, a record-keeping journal.
        Every figure above is derived from entries made by the keeper.
        This report is not veterinary advice and is not a health assessment.
        """
    }
}

// MARK: - Overall Stats
private struct OverallStatsCard: View {
    @EnvironmentObject var store: DataStore
    let vaccinations: [Vaccination]
    let medications: [Medication]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Summary")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MiniStatCard(icon: "bird.fill", value: "\(store.totalBirds)",
                             label: "Total Birds", color: .primaryGreen)
                MiniStatCard(icon: "syringe.fill", value: "\(vaccinations.filter { $0.isCompleted }.count)",
                             label: "Vaccinations Marked Done", color: .accentCyan)
                MiniStatCard(icon: "pills.fill", value: "\(store.activeMedications.count)",
                             label: "Active Courses", color: .actionOrange)
                MiniStatCard(icon: "bell.badge", value: "\(store.pendingAlerts.count)",
                             label: "Open Alerts",
                             color: store.pendingAlerts.isEmpty ? .statusNormal : .statusDanger)
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

private struct MiniStatCard: View {
    let icon, value, label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Vaccination Chart
private struct VaccinationChartCard: View {
    @EnvironmentObject var store: DataStore
    let vaccinations: [Vaccination]
    @Binding var animBars: Bool

    private var counts: [(String, Int, Color)] {
        [("Done",     vaccinations.filter { $0.isCompleted }.count, Color.statusNormal),
         ("Upcoming", vaccinations.filter { $0.isUpcoming  }.count, Color.accentCyan),
         ("Overdue",  vaccinations.filter { $0.isOverdue   }.count, Color.statusDanger)]
    }
    private var total: Int { max(1, counts.reduce(0) { $0 + $1.1 }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Vaccination Entries")

            if vaccinations.isEmpty {
                Text("No vaccination entries in this window.")
                    .font(.system(size: 14)).foregroundColor(.textInactive)
            } else {
                ForEach(counts, id: \.0) { (label, count, color) in
                    let fraction = Double(count) / Double(total)
                    HStack(spacing: 10) {
                        Text(label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 74, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.freshBg)
                                Capsule()
                                    .fill(color)
                                    .frame(width: animBars ? geo.size.width * fraction : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: animBars)
                            }
                        }
                        .frame(height: 12)
                        // Counts, not percentages — a percentage of three records misleads.
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(color)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(label): \(count)")
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Group status
private struct GroupStatusCard: View {
    @EnvironmentObject var store: DataStore
    @Binding var animBars: Bool

    private var buckets: [(BirdGroup.HealthStatus, Int)] {
        BirdGroup.HealthStatus.allCases.map { status in
            (status, store.birdGroups.filter { $0.status == status }.count)
        }
    }
    private var total: Int { max(1, store.birdGroups.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Status You Recorded")

            if store.birdGroups.isEmpty {
                Text("No groups yet.").font(.system(size: 14)).foregroundColor(.textInactive)
            } else {
                ForEach(buckets, id: \.0.rawValue) { (status, count) in
                    let fraction = Double(count) / Double(total)
                    HStack(spacing: 10) {
                        Text(status.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 104, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.freshBg)
                                Capsule()
                                    .fill(status.color)
                                    .frame(width: animBars ? geo.size.width * fraction : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: animBars)
                            }
                        }
                        .frame(height: 10)
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(status.color)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(status.rawValue): \(count) groups")
                }

                Text("These are the statuses you selected for each group. BirdMed never scores or infers them.")
                    .font(.system(size: 11))
                    .foregroundColor(.textInactive)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Expense Breakdown
private struct ExpenseBreakdownCard: View {
    let expenses: [Expense]
    let total: Double
    @Binding var animBars: Bool

    private var breakdown: [(Expense.ExpenseCategory, Double)] {
        var dict: [Expense.ExpenseCategory: Double] = [:]
        for e in expenses { dict[e.category, default: 0] += e.amount }
        return dict.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Expenses")
                Spacer(minLength: 8)
                Text(Formatters.currency(total))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            if breakdown.isEmpty {
                Text("No expenses in this window.").font(.system(size: 14)).foregroundColor(.textInactive)
            } else {
                ForEach(breakdown, id: \.0.rawValue) { (cat, amount) in
                    let pct = total > 0 ? amount / total : 0
                    HStack(spacing: 10) {
                        Image(systemName: cat.icon).font(.system(size: 14)).foregroundColor(cat.color).frame(width: 20)
                        Text(cat.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .frame(width: 74, alignment: .leading)
                            .lineLimit(1)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.freshBg)
                                Capsule()
                                    .fill(cat.color)
                                    .frame(width: animBars ? max(6, geo.size.width * pct) : 0)
                                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: animBars)
                            }
                        }
                        .frame(height: 10)
                        Text(Formatters.currencyCompact(amount))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(cat.color)
                            .frame(width: 56, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(cat.rawValue): \(Formatters.currency(amount))")
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Attention indicator
//
// Deliberately NOT called a risk or health score: it is a weighted count of
// bookkeeping items, and the exact formula is stated on screen and in
// MedicalSafety.methodology.
private struct AttentionCard: View {
    @EnvironmentObject var store: DataStore
    @State private var animRing = false
    @State private var showFormula = false

    private var overdue: Int { store.overdueVaccinations.count }
    private var openAlerts: Int { store.pendingAlerts.count }
    private var flagged: Int { store.birdGroups.filter { $0.status != .healthy }.count }

    private var score: Double {
        min(Double(overdue) * 0.20 + Double(openAlerts) * 0.15 + Double(flagged) * 0.10, 1.0)
    }
    private var label: String {
        if score < 0.2 { return "Low" }
        if score < 0.5 { return "Medium" }
        return "High"
    }
    private var color: Color {
        if score < 0.2 { return .statusNormal }
        if score < 0.5 { return .statusRisk }
        return .statusDanger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Needs Your Attention")

            HStack(spacing: 24) {
                ZStack {
                    ProgressRing(progress: animRing ? score : 0, color: color, size: 90)
                    VStack(spacing: 2) {
                        Text(label)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                        Text("backlog")
                            .font(.system(size: 11)).foregroundColor(.textInactive)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) { animRing = true }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Outstanding bookkeeping: \(label)")

                VStack(alignment: .leading, spacing: 8) {
                    AttentionRow(label: "Overdue vaccinations", value: overdue,    color: .statusDanger)
                    AttentionRow(label: "Open alerts",          value: openAlerts, color: .statusRisk)
                    AttentionRow(label: "Groups you flagged",   value: flagged,    color: .actionOrange)
                }
            }

            Button {
                withAnimation(.appSpring) { showFormula.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(showFormula ? "Hide how this is calculated" : "How is this calculated?")
                    Image(systemName: showFormula ? "chevron.up" : "chevron.down").font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primaryGreen)
            }
            .buttonStyle(.plain)

            if showFormula {
                Text("0.20 × overdue vaccinations + 0.15 × open alerts + 0.10 × groups you flagged, capped at 1.00. It measures how much of your own record-keeping is outstanding. It is not a veterinary risk assessment and says nothing about the health of your birds.")
                    .font(.system(size: 11))
                    .foregroundColor(.textInactive)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

private struct AttentionRow: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(value > 0 ? color : Color.statusNormal).frame(width: 8, height: 8)
            Text(label).font(.system(size: 12)).foregroundColor(.textSecondary)
            Spacer(minLength: 6)
            Text("\(value)").font(.system(size: 12, weight: .bold)).foregroundColor(value > 0 ? color : .statusNormal)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

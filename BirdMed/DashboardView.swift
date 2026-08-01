import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var appVM: AppViewModel
    @Binding var selectedTab: AppTab

    @State private var showAddGroup  = false
    @State private var showAddRecord = false
    @State private var animMetric    = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Good \(timeOfDay) 👋")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                            Text(appVM.farmName)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer()
                        NavigationLink(destination: AlertsView()) {
                            ZStack(alignment: .topTrailing) {
                                IconBadge(icon: "bell.fill", color: .statusRisk, size: 42)
                                if !store.pendingAlerts.isEmpty {
                                    Circle()
                                        .fill(Color.statusDanger)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(store.pendingAlerts.isEmpty
                                            ? "Alerts"
                                            : "Alerts, \(store.pendingAlerts.count) active")
                    }
                    .padding(.horizontal, 16)

                    DisclaimerBanner()
                        .padding(.horizontal, 16)

                    if store.isEmpty {
                        GetStartedCard(showAddGroup: $showAddGroup)
                    } else {
                        MetricCard(animMetric: $animMetric)

                        // Quick actions
                        HStack(spacing: 12) {
                            ActionButton(icon: "plus.circle.fill", label: "Add Group", color: .primaryGreen) {
                                showAddGroup = true
                            }
                            ActionButton(icon: "doc.badge.plus", label: "Add Record", color: .primaryBlue) {
                                showAddRecord = true
                            }
                            NavigationLink(destination: AlertsView()) {
                                ActionButtonLabel(icon: "bell.badge.fill", label: "Alerts", color: .statusRisk)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)

                        TodayTasksCard()
                        UpcomingVaccinationsCard(selectedTab: $selectedTab)
                        ActiveMedicationsCard()
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            .tabBarBottomPadding()
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddGroup) { AddGroupView(isPresented: $showAddGroup) }
        .sheet(isPresented: $showAddRecord) { AddCalendarEventView(isPresented: $showAddRecord) }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { animMetric = true }
            }
        }
    }

    private var timeOfDay: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Morning" } else if h < 17 { return "Afternoon" } else { return "Evening" }
    }
}

// MARK: - First-run card
//
// The only two ways records ever appear: the user creates one, or the user
// explicitly asks for the clearly-labelled demo set.
private struct GetStartedCard: View {
    @EnvironmentObject var store: DataStore
    @Binding var showAddGroup: Bool
    @State private var confirmDemo = false

    var body: some View {
        VStack(spacing: 14) {
            IconBadge(icon: "square.and.pencil", color: .primaryGreen, size: 54)

            Text("Nothing recorded yet")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("BirdMed starts empty on purpose — everything you see from here on is what you enter yourself.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Add your first bird group") { showAddGroup = true }
                .buttonStyle(PrimaryButtonStyle())

            Button("Load demo data") { confirmDemo = true }
                .buttonStyle(SecondaryButtonStyle())

            Text("Demo records are prefixed “Demo:”, contain no real prescription, and can be removed from Settings.")
                .font(.system(size: 11))
                .foregroundColor(.textInactive)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard()
        .padding(.horizontal, 16)
        .alert("Load demo data?", isPresented: $confirmDemo) {
            Button("Cancel", role: .cancel) {}
            Button("Load") { withAnimation(.appSpring) { store.loadDemoData() } }
        } message: {
            Text("Adds a small set of fictional sample records so you can see how the app works. They are labelled “Demo:”, contain no real medicine or dosage, and can be removed at any time.")
        }
    }
}

// MARK: - Metric Card
private struct MetricCard: View {
    @EnvironmentObject var store: DataStore
    @Binding var animMetric: Bool

    var healthyCount: Int { store.birdGroups.filter { $0.status == .healthy }.count }
    var atRiskCount:  Int { store.birdGroups.filter { $0.status == .atRisk  }.count }
    var sickCount:    Int { store.birdGroups.filter { $0.status == .sick || $0.status == .underTreatment }.count }
    var total: Int { store.birdGroups.count }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flock Overview")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(store.totalBirds)")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .scaleEffect(animMetric ? 1.0 : 0.5)
                        Text("birds")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    Text("\(store.birdGroups.count) groups · \(store.coops.count) coops")
                        .font(.system(size: 13))
                        .foregroundColor(.textInactive)
                }
                Spacer()
                // Distribution of the statuses you assigned — not an assessment.
                ZStack {
                    if total > 0 {
                        DonutChart(
                            values: [Double(healthyCount), Double(atRiskCount), Double(sickCount)],
                            colors: [.statusNormal, .statusRisk, .statusDanger],
                            size: 72
                        )
                        .scaleEffect(animMetric ? 1.0 : 0.3)
                    } else {
                        Circle().stroke(Color.dividerGreen, lineWidth: 6).frame(width: 72, height: 72)
                    }
                    VStack(spacing: 0) {
                        Text(total > 0 ? "\(Int((Double(healthyCount) / Double(total) * 100).rounded()))%" : "--")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.statusNormal)
                        Text("OK")
                            .font(.system(size: 10))
                            .foregroundColor(.textInactive)
                    }
                }
                .animation(.spring(response: 0.7, dampingFraction: 0.7), value: animMetric)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(healthyCount) of \(total) groups marked healthy")
            }

            HStack(spacing: 0) {
                StatPill(value: healthyCount, label: "Healthy", color: .statusNormal)
                Divider().frame(height: 30)
                StatPill(value: atRiskCount,  label: "At Risk", color: .statusRisk)
                Divider().frame(height: 30)
                StatPill(value: sickCount,    label: "Sick",    color: .statusDanger)
            }
            .padding(.vertical, 4)
            .background(Color.freshBg)
            .cornerRadius(12)
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

private struct StatPill: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Donut Chart
private struct DonutChart: View {
    let values: [Double]; let colors: [Color]; let size: CGFloat
    var total: Double { values.reduce(0, +) }
    var body: some View {
        Canvas { ctx, canvasSize in
            guard total > 0 else { return }
            let center = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
            let radius = min(canvasSize.width, canvasSize.height)/2
            let lineW: CGFloat = 8
            var start: Double = -90
            for (i, v) in values.enumerated() where v > 0 {
                let sweep = 360 * v / total
                let end = start + sweep
                var path = Path()
                path.addArc(center: center, radius: radius - lineW/2,
                            startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
                ctx.stroke(path, with: .color(colors[i % colors.count]),
                           style: StrokeStyle(lineWidth: lineW, lineCap: .butt))
                start = end
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Today Tasks Card
private struct TodayTasksCard: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLink(title: "Today's Tasks") { TasksView() }

            if store.todayTasks.isEmpty {
                Text("Nothing due today ✅")
                    .font(.system(size: 15))
                    .foregroundColor(.textInactive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(store.todayTasks.prefix(3)) { task in
                    HStack(spacing: 12) {
                        Button { withAnimation(.appSpring) { store.toggleTask(task) } } label: {
                            ZStack {
                                Circle()
                                    .stroke(task.priority.color, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                if task.isDone {
                                    Circle().fill(task.priority.color).frame(width: 18, height: 18)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(task.isDone ? "Mark \(task.title) not done" : "Mark \(task.title) done")

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(task.isDone ? .textInactive : .textPrimary)
                                .strikethrough(task.isDone)
                            Text(task.category.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.textInactive)
                        }
                        Spacer()
                        IconBadge(icon: task.category.icon, color: task.category.color, size: 28)
                    }
                }
                if store.todayTasks.count > 3 {
                    NavigationLink(destination: TasksView()) {
                        Text("See \(store.todayTasks.count - 3) more…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primaryGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Upcoming Vaccinations Card
private struct UpcomingVaccinationsCard: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming Vaccines") {
                withAnimation(.appSpring) { selectedTab = .vaccination }
            }

            if store.overdueVaccinations.isEmpty && store.upcomingVaccinations.isEmpty {
                EmptyStateView(icon: "syringe.fill", title: "No vaccines scheduled",
                               message: "Record the plan your veterinarian gave you for each group.")
            } else {
                ForEach(store.overdueVaccinations.prefix(2)) { v in
                    VaccinationRowSmall(v: v, color: .statusDanger, label: "OVERDUE")
                }
                ForEach(store.upcomingVaccinations.prefix(2)) { v in
                    let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: v.scheduledDate).day ?? 0
                    VaccinationRowSmall(v: v, color: .accentCyan,
                                        label: daysLeft <= 0 ? "TODAY" : "In \(daysLeft)d")
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

private struct VaccinationRowSmall: View {
    @EnvironmentObject var store: DataStore
    let v: Vaccination; let color: Color; let label: String
    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: "syringe.fill", color: color, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(v.vaccineName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(store.groupName(v.groupId))
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            StatusBadge(text: label, color: color)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Active Medications Card
private struct ActiveMedicationsCard: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderLink(title: "Active Medications") { MedicationsView() }

            if store.activeMedications.isEmpty {
                Text("No medication courses recorded")
                    .font(.system(size: 15))
                    .foregroundColor(.textInactive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.activeMedications.prefix(2)) { m in
                    HStack(spacing: 12) {
                        IconBadge(icon: m.category.icon, color: m.category.color, size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            Text("\(store.groupName(m.groupId)) · \(m.daysLeft)d left")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        ProgressRing(progress: m.progress, color: m.category.color, size: 32)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .appCard()
        .padding(.horizontal, 16)
    }
}

// MARK: - Action Button

private struct ActionButtonLabel: View {
    let icon: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.2), lineWidth: 1))
        .contentShape(Rectangle())
    }
}

private struct ActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            ActionButtonLabel(icon: icon, label: label, color: color)
        }
        .buttonStyle(.plain)
    }
}

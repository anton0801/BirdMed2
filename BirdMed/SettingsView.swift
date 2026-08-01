import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var store: DataStore

    @State private var showDataClear = false
    @State private var confirmLoadDemo = false
    @State private var confirmRemoveDemo = false
    @State private var savedBannerVisible = false
    @State private var farmNameTemp: String = ""
    @State private var notifPermissionStatus: String = ""
    @State private var sharePayload: SharePayload? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: Farm profile
                VStack(spacing: 14) {
                    SectionHeader(title: "Farm Profile")
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color.primaryGreen.opacity(0.15)).frame(width: 56, height: 56)
                            Text("🌾").font(.system(size: 28))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Farm Name")
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.textSecondary)
                            TextField("Farm name", text: $farmNameTemp)
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.textPrimary)
                                .submitLabel(.done)
                                .onSubmit { commitFarmName() }
                        }
                    }
                    .appCard(padding: 14)
                }
                .padding(.horizontal, 16)

                // MARK: Appearance
                VStack(spacing: 14) {
                    SectionHeader(title: "Appearance")
                    VStack(spacing: 0) {
                        SettingsRow(icon: "sun.max.fill", iconColor: .actionOrange, label: "App Theme") {
                            Picker("Theme", selection: $appVM.appTheme) {
                                Text("System").tag("system")
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 14)).foregroundColor(.primaryGreen)
                        }
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()
                }
                .padding(.horizontal, 16)

                // MARK: Safety
                VStack(spacing: 14) {
                    SectionHeader(title: "Safety & Transparency")
                    VStack(spacing: 0) {
                        NavigationLink(destination: MedicalDisclaimerView()) {
                            SettingsRowLink(icon: "exclamationmark.shield.fill", iconColor: .statusDanger,
                                            label: "Veterinary Disclaimer")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 52)
                        NavigationLink(destination: MethodologyView()) {
                            SettingsRowLink(icon: "function", iconColor: .primaryBlue,
                                            label: "How Numbers Are Calculated")
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()
                }
                .padding(.horizontal, 16)

                // MARK: Notifications
                VStack(spacing: 14) {
                    SectionHeader(title: "Notifications")
                    VStack(spacing: 0) {
                        SettingsRow(icon: "bell.fill", iconColor: .primaryGreen, label: "Daily Care Reminders") {
                            Toggle("", isOn: $appVM.dailyCareNotif)
                                .labelsHidden()
                                .tint(.primaryGreen)
                                .onChange(of: appVM.dailyCareNotif) { _ in scheduleNotifications() }
                        }
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "heart.fill", iconColor: .statusDanger, label: "Weekly Health Check") {
                            Toggle("", isOn: $appVM.healthCheckNotif)
                                .labelsHidden()
                                .tint(.primaryGreen)
                                .onChange(of: appVM.healthCheckNotif) { _ in scheduleNotifications() }
                        }
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "cart.fill", iconColor: .actionOrange, label: "Weekly Supply Check") {
                            Toggle("", isOn: $appVM.lowStockNotif)
                                .labelsHidden()
                                .tint(.primaryGreen)
                                .onChange(of: appVM.lowStockNotif) { _ in scheduleNotifications() }
                        }
                        Divider().padding(.leading, 52)
                        NavigationLink(destination: NotificationsSettingsView()) {
                            SettingsRowLink(icon: "clock.fill", iconColor: .primaryBlue, label: "Notification Time")
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()

                    Text(notifPermissionStatus.isEmpty
                         ? "Reminders are local to this device and can be delayed or missed. Don't rely on them alone for a time-critical treatment."
                         : notifPermissionStatus)
                        .font(.system(size: 11))
                        .foregroundColor(.textInactive)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // MARK: Demo data
                VStack(spacing: 14) {
                    SectionHeader(title: "Demo Data")
                    VStack(spacing: 0) {
                        if store.isDemoDataLoaded {
                            Button { confirmRemoveDemo = true } label: {
                                SettingsRowAction(icon: "trash.slash.fill", iconColor: .actionOrange,
                                                  label: "Remove Demo Data", tint: .actionOrange)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button { confirmLoadDemo = true } label: {
                                SettingsRowAction(icon: "wand.and.stars", iconColor: .primaryBlue,
                                                  label: "Load Demo Data", tint: .textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()

                    Text("BirdMed never adds records on its own. Demo records are fictional, prefixed “Demo:”, contain no real medicine or dosage, and removing them leaves anything you added untouched.")
                        .font(.system(size: 11))
                        .foregroundColor(.textInactive)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // MARK: Data
                VStack(spacing: 14) {
                    SectionHeader(title: "Your Data")
                    VStack(spacing: 0) {
                        Button { sharePayload = SharePayload(text: exportText()) } label: {
                            SettingsRowLink(icon: "square.and.arrow.up", iconColor: .primaryGreen, label: "Export Summary")
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 52)
                        Button { showDataClear = true } label: {
                            SettingsRowAction(icon: "trash.fill", iconColor: .statusDanger,
                                              label: "Clear All Data", tint: .statusDanger)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()

                    Text("Records are stored only on this device. There is no account, no server and no backup — export or back up anything you rely on.")
                        .font(.system(size: 11))
                        .foregroundColor(.textInactive)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                // MARK: About
                VStack(spacing: 6) {
                    Text("BirdMed \(appVersion)")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.textInactive)
                    Text("A record-keeping journal for poultry keepers")
                        .font(.system(size: 12)).foregroundColor(.textInactive)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            farmNameTemp = appVM.farmName
            checkNotifStatus()
        }
        .onDisappear { commitFarmName() }
        .overlay(alignment: .top) {
            if savedBannerVisible {
                SavedBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        // Presented as a sheet rather than pushed onto the key window's root
        // controller, which crashed on iPad for want of a popover anchor.
        .sheet(item: $sharePayload) { payload in
            ShareSheet(text: payload.text)
        }
        .alert("Clear all data?", isPresented: $showDataClear) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                withAnimation(.appSpring) { store.clearAll() }
                showSavedBanner()
            }
        } message: {
            Text("This permanently deletes every bird group, record, note and history entry on this device. It cannot be undone.")
        }
        .alert("Load demo data?", isPresented: $confirmLoadDemo) {
            Button("Cancel", role: .cancel) {}
            Button("Load") {
                withAnimation(.appSpring) { store.loadDemoData() }
                showSavedBanner()
            }
        } message: {
            Text("Adds a small set of fictional sample records labelled “Demo:” so you can see how the app works. They contain no real medicine or dosage.")
        }
        .alert("Remove demo data?", isPresented: $confirmRemoveDemo) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                withAnimation(.appSpring) { store.removeDemoData() }
                showSavedBanner()
            }
        } message: {
            Text("Deletes only the records the demo added. Anything you entered yourself is kept.")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    private func commitFarmName() {
        let trimmed = farmNameTemp.trimmingCharacters(in: .whitespacesAndNewlines)
        // An empty title would leave the dashboard with no heading at all.
        if trimmed.isEmpty {
            farmNameTemp = appVM.farmName
        } else if trimmed != appVM.farmName {
            appVM.farmName = trimmed
            farmNameTemp = trimmed
            showSavedBanner()
        }
    }

    // MARK: - Notifications

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    notifPermissionStatus = "⚠️ Notifications are turned off for BirdMed in iOS Settings."
                    return
                }
                center.removeAllPendingNotificationRequests()
                if appVM.dailyCareNotif   { scheduleDailyCare(center) }
                if appVM.healthCheckNotif { scheduleHealthCheck(center) }
                if appVM.lowStockNotif    { scheduleLowStock(center) }
                notifPermissionStatus = "✓ Reminders updated."
                showSavedBanner()
            }
        }
    }

    private func scheduleDailyCare(_ center: UNUserNotificationCenter) {
        var comp = DateComponents()
        comp.hour = appVM.notifHour; comp.minute = appVM.notifMinute
        let content = UNMutableNotificationContent()
        content.title = "BirdMed"
        content.body = "Time to check today's tasks for your flock."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "dailyCare", content: content,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)))
    }

    private func scheduleHealthCheck(_ center: UNUserNotificationCenter) {
        var comp = DateComponents(); comp.weekday = 2; comp.hour = 9
        let content = UNMutableNotificationContent()
        content.title = "Weekly check"
        content.body = "A good moment to walk the coops and write down what you see."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "healthCheck", content: content,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)))
    }

    private func scheduleLowStock(_ center: UNUserNotificationCenter) {
        var comp = DateComponents(); comp.weekday = 6; comp.hour = 10
        let content = UNMutableNotificationContent()
        content.title = "Supplies"
        content.body = "Review feed and medicine stock for the week ahead."
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "lowStock", content: content,
                                         trigger: UNCalendarNotificationTrigger(dateMatching: comp, repeats: true)))
    }

    private func checkNotifStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    notifPermissionStatus = "⚠️ Notifications are turned off for BirdMed in iOS Settings."
                }
            }
        }
    }

    // MARK: - Export

    private func exportText() -> String {
        """
        BirdMed summary — \(Date().formatted(.dateTime.month(.wide).day().year()))
        Farm: \(appVM.farmName)

        Bird groups: \(store.birdGroups.count)
        Total birds: \(store.totalBirds)
        Coops: \(store.coops.count)
        Vaccination entries: \(store.vaccinations.count)
        Medication entries: \(store.medications.count)
        Notes: \(store.notes.count)
        Expenses total: \(Formatters.currency(store.totalExpenses))

        Exported from BirdMed, a record-keeping journal.
        These are the keeper's own entries and are not veterinary advice.
        """
    }

    private func showSavedBanner() {
        withAnimation(.appSpring) { savedBannerVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.appSpring) { savedBannerVisible = false }
        }
    }
}

/// Wrapper so the export text can drive `.sheet(item:)` without a retroactive
/// `Identifiable` conformance on `String`.
struct SharePayload: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Notifications Settings
struct NotificationsSettingsView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Reminders")
                    VStack(spacing: 0) {
                        SettingsRow(icon: "bell.fill", iconColor: .primaryGreen, label: "Daily Care") {
                            Toggle("", isOn: $appVM.dailyCareNotif).labelsHidden().tint(.primaryGreen)
                        }
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "heart.fill", iconColor: .statusDanger, label: "Weekly Health Check") {
                            Toggle("", isOn: $appVM.healthCheckNotif).labelsHidden().tint(.primaryGreen)
                        }
                        Divider().padding(.leading, 52)
                        SettingsRow(icon: "cart.fill", iconColor: .actionOrange, label: "Weekly Supply Check") {
                            Toggle("", isOn: $appVM.lowStockNotif).labelsHidden().tint(.primaryGreen)
                        }
                    }
                    .background(Color.cardBg).cornerRadius(14).appShadow()
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Daily Reminder Time")
                    VStack(spacing: 12) {
                        DatePicker("Time", selection: Binding(
                            get: {
                                var c = DateComponents()
                                c.hour = appVM.notifHour; c.minute = appVM.notifMinute
                                return Calendar.current.date(from: c) ?? Date()
                            },
                            set: { d in
                                appVM.notifHour   = Calendar.current.component(.hour,   from: d)
                                appVM.notifMinute = Calendar.current.component(.minute, from: d)
                            }
                        ), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                    .appCard()
                }
                .padding(.horizontal, 16)

                Button("Save Reminder Settings") {
                    scheduleAllNotifications()
                    withAnimation(.appSpring) { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.appSpring) { saved = false }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 16)

                if saved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.statusNormal)
                        Text("Saved").font(.system(size: 14, weight: .semibold)).foregroundColor(.statusNormal)
                    }
                    .transition(.opacity)
                }

                Text("Reminders are scheduled locally by iOS. They can be delayed or missed if the device is off or notifications are disabled — never rely on them alone for a time-critical treatment.")
                    .font(.system(size: 11))
                    .foregroundColor(.textInactive)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func scheduleAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: ["dailyCare"])
            guard appVM.dailyCareNotif else { return }
            var c = DateComponents(); c.hour = appVM.notifHour; c.minute = appVM.notifMinute
            let content = UNMutableNotificationContent()
            content.title = "BirdMed"
            content.body = "Time to check today's tasks for your flock."
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "dailyCare", content: content,
                                             trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: true)))
        }
    }
}

// MARK: - Settings helpers
struct SettingsRow<Content: View>: View {
    let icon: String; let iconColor: Color; let label: String; let content: Content
    init(icon: String, iconColor: Color, label: String, @ViewBuilder content: () -> Content) {
        self.icon = icon; self.iconColor = iconColor; self.label = label; self.content = content()
    }
    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: iconColor, size: 32)
            Text(label).font(.system(size: 15)).foregroundColor(.textPrimary)
            Spacer(minLength: 8)
            content
        }
        .padding(12)
    }
}

struct SettingsRowLink: View {
    let icon: String; let iconColor: Color; let label: String
    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: iconColor, size: 32)
            Text(label).font(.system(size: 15)).foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(.textInactive)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

struct SettingsRowAction: View {
    let icon: String; let iconColor: Color; let label: String; let tint: Color
    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: icon, color: iconColor, size: 32)
            Text(label).font(.system(size: 15)).foregroundColor(tint)
            Spacer()
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

struct SavedBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
            Text("Saved").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.activeGreen)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 2)
        .padding(.top, 8)
    }
}

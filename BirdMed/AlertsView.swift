import SwiftUI

// Pushed, never presented modally, so it must not carry its own NavigationView —
// nesting one inside the caller's produced a double navigation bar.
struct AlertsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showResolved = false

    var active:   [BirdAlert] { store.alerts.filter { !$0.isResolved && !$0.isSnoozed } }
    var snoozed:  [BirdAlert] { store.alerts.filter { $0.isSnoozed && !$0.isResolved } }
    var resolved: [BirdAlert] { store.alerts.filter { $0.isResolved } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                DisclaimerBanner()
                    .padding(.horizontal, 16)

                // Summary
                HStack(spacing: 0) {
                    AlertTile(value: active.count,   label: "Active",   color: .statusDanger)
                    Divider().frame(height: 40)
                    AlertTile(value: snoozed.count,  label: "Snoozed",  color: .statusRisk)
                    Divider().frame(height: 40)
                    AlertTile(value: resolved.count, label: "Resolved", color: .statusNormal)
                }
                .appCard()
                .padding(.horizontal, 16)

                if active.isEmpty && snoozed.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.statusNormal)
                        Text("Nothing outstanding")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("No recorded date has passed and no course is ending. This reflects your entries only — it is not a health check.")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 24)
                } else {
                    if !active.isEmpty {
                        AlertSection(title: "Active Alerts (\(active.count))", alerts: active, isSnoozed: false)
                            .padding(.horizontal, 16)
                    }
                    if !snoozed.isEmpty {
                        AlertSection(title: "Snoozed (\(snoozed.count))", alerts: snoozed, isSnoozed: true)
                            .padding(.horizontal, 16)
                    }
                }

                if !resolved.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.appSpring) { showResolved.toggle() }
                        } label: {
                            HStack {
                                Text("Resolved (\(resolved.count))")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.textSecondary)
                                Spacer()
                                Image(systemName: showResolved ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12)).foregroundColor(.textInactive)
                            }
                        }
                        .padding(.horizontal, 16)

                        if showResolved {
                            ForEach(resolved.prefix(10)) { a in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18)).foregroundColor(.statusNormal.opacity(0.6))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(a.title).font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.textInactive).strikethrough()
                                        Text(a.date.formatted(.dateTime.month().day()))
                                            .font(.system(size: 11)).foregroundColor(.textInactive)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.freshBg)
                                .cornerRadius(12)
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }

            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.appSpring) { store.checkAutoAlerts() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16)).foregroundColor(.primaryGreen)
                }
                .accessibilityLabel("Re-check recorded dates")
            }
        }
    }
}

private struct AlertTile: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }.frame(maxWidth: .infinity)
    }
}

private struct AlertSection: View {
    @EnvironmentObject var store: DataStore
    let title: String; let alerts: [BirdAlert]; let isSnoozed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
            ForEach(alerts) { alert in
                AlertCard(alert: alert, isSnoozed: isSnoozed)
            }
        }
    }
}

struct AlertCard: View {
    @EnvironmentObject var store: DataStore
    let alert: BirdAlert
    let isSnoozed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(alert.severity.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: alert.severity.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(alert.severity.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(alert.alertDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                StatusBadge(text: alert.severity.rawValue, color: alert.severity.color)
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.appSpring) { store.resolveAlert(alert) }
                } label: {
                    Label("Resolve", systemImage: "checkmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.statusNormal)
                        .cornerRadius(10)
                }

                if !isSnoozed {
                    Button {
                        withAnimation(.appSpring) { store.snoozeAlert(alert) }
                    } label: {
                        Label("Snooze", systemImage: "clock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.actionOrange)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.actionOrange.opacity(0.1))
                            .cornerRadius(10)
                    }
                }

                Spacer()
                Text(alert.date.formatted(.dateTime.month().day()))
                    .font(.system(size: 11)).foregroundColor(.textInactive)
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(alert.severity.color.opacity(0.3), lineWidth: 1.5))
        .appShadow()
    }
}

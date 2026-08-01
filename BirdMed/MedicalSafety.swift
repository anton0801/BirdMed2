import SwiftUI

// MARK: - Static copy
//
// BirdMed ships with no medical database. It never proposes a medicine, a dose,
// a vaccine or a schedule — every clinical value in the app is text the user
// typed in from their own veterinarian's prescription. Everything in this file
// exists to make that contract explicit and to document, in the app itself,
// how each derived number on screen is calculated.

enum MedicalSafety {

    static let bannerText = "Record-keeping only — not veterinary advice"

    static let headline = "BirdMed is a record-keeping journal, not a medical device."

    struct Section: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let body: String
    }

    // MARK: Disclaimer

    static let disclaimer: [Section] = [
        Section(
            icon: "stethoscope",
            color: .statusDanger,
            title: "Always consult a veterinarian",
            body: """
            Consult a licensed veterinarian before you start, change or stop any \
            treatment. Follow the dose, the route of administration and the \
            withdrawal period printed on the product label and on your \
            veterinarian's prescription — not what is convenient to type here.
            """
        ),
        Section(
            icon: "keyboard",
            color: .primaryBlue,
            title: "Every clinical value is yours",
            body: """
            The app contains no drug database, no vaccination calendar and no \
            dosage tables. Medicine names, doses, frequencies, vaccines and \
            dates exist in BirdMed only because you entered them. The app never \
            suggests, completes or validates a treatment.
            """
        ),
        Section(
            icon: "brain",
            color: .actionOrange,
            title: "No diagnosis, no advice",
            body: """
            BirdMed does not analyse symptoms, does not diagnose disease and \
            does not evaluate whether a treatment is appropriate, safe or \
            effective. Counters, charts and progress bars only re-describe the \
            records you keep.
            """
        ),
        Section(
            icon: "bell.badge",
            color: .statusRisk,
            title: "Reminders can fail",
            body: """
            Reminders are local notifications built from the dates you enter. \
            They can be delayed or lost if the device is off, out of battery, in \
            Focus mode, or if notifications are denied. Never let this app be \
            the only reminder for a time-critical treatment.
            """
        ),
        Section(
            icon: "cross.case.fill",
            color: .statusDanger,
            title: "In an emergency",
            body: """
            If birds are sick or dying, or you suspect a notifiable disease, \
            contact your veterinarian or your national animal-health authority \
            immediately. Do not wait for a reminder from this app.
            """
        ),
        Section(
            icon: "lock.shield",
            color: .primaryGreen,
            title: "Your records stay on this device",
            body: """
            Records are stored locally on this iPhone or iPad. There is no \
            account, no server, no analytics and no third-party SDK. Uninstalling \
            the app or clearing its data deletes your records permanently — keep \
            your own backup of anything you rely on.
            """
        ),
    ]

    // MARK: Methodology
    //
    // One entry per derived figure the UI displays, so any number on screen can
    // be traced back to the records it came from.

    static let methodology: [Section] = [
        Section(
            icon: "sum",
            color: .primaryGreen,
            title: "Flock totals",
            body: """
            Total birds is the sum of the count you entered for every group. \
            Group and coop tallies are simply how many records exist. Coop \
            occupancy is the sum of counts of the groups you assigned to that \
            coop, over the capacity you typed in.
            """
        ),
        Section(
            icon: "calendar.badge.clock",
            color: .accentCyan,
            title: "Overdue and upcoming",
            body: """
            An entry counts as overdue when its scheduled date is in the past \
            and you have not marked it done; upcoming when the date is today or \
            later. This is a calendar comparison against your own dates — it is \
            not a judgement about whether a treatment is late in clinical terms.
            """
        ),
        Section(
            icon: "chart.bar.fill",
            color: .actionOrange,
            title: "Course progress",
            body: """
            Progress is elapsed time divided by the span between the start and \
            end dates you entered, clamped to 0–100 %. Days left is the number of \
            whole days from now until the end date, never below zero. Both are \
            countdowns between two dates, and say nothing about how a course is \
            working.
            """
        ),
        Section(
            icon: "bell.fill",
            color: .statusRisk,
            title: "How alerts are raised",
            body: """
            Alerts are raised in exactly two cases: a vaccination entry whose \
            scheduled date has passed while still unmarked, and a medication \
            entry that ends within one day. Nothing else generates an alert, and \
            no symptom is ever interpreted.
            """
        ),
        Section(
            icon: "eye.fill",
            color: .primaryBlue,
            title: "The attention indicator",
            body: """
            The Reports screen shows an attention indicator, not a health or \
            risk assessment. It is a weighted count: 0.20 for each overdue \
            vaccination, 0.15 for each open alert, and 0.10 for each group you \
            yourself flagged as something other than Healthy, capped at 1.00. \
            Those weights are an arbitrary display convention chosen to sort \
            your to-do list — they are not derived from any veterinary model.
            """
        ),
        Section(
            icon: "heart.text.square",
            color: .statusNormal,
            title: "Health status",
            body: """
            The status shown for a group — Healthy, At Risk, Sick, Under \
            Treatment — is the value you selected when creating or editing that \
            group. The app never infers, changes or second-guesses it.
            """
        ),
        Section(
            icon: "dollarsign.circle.fill",
            color: .actionOrange,
            title: "Expenses",
            body: """
            Expense figures are plain sums of the amounts you entered, grouped \
            by category and by calendar month in your device's time zone. No \
            currency conversion, tax handling or price estimation is applied.
            """
        ),
        Section(
            icon: "externaldrive.fill",
            color: .textInactive,
            title: "Storage",
            body: """
            All records are kept in this app's own local storage (UserDefaults) \
            on this device, which is also what the bundled privacy manifest \
            declares. Export produces a plain-text summary that you choose where \
            to send.
            """
        ),
    ]
}

// MARK: - Compact banner
//
// Sits at the top of every screen that displays clinical records.

struct DisclaimerBanner: View {
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.actionOrange)
                Text(MedicalSafety.bannerText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.actionOrange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.actionOrange.opacity(0.09))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.actionOrange.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the veterinary disclaimer")
        .sheet(isPresented: $showDetail) { MedicalDisclaimerSheet() }
    }
}

// MARK: - Form helpers
//
// Shown at the top of any form that captures clinical values, so the "you type
// it, we only store it" contract is restated exactly where it matters.

struct PrescriptionNote: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryBlue)
            VStack(alignment: .leading, spacing: 3) {
                Text("Copy from your prescription")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("BirdMed records what you enter. It never recommends, completes or verifies a medicine, dose or schedule — ask your veterinarian.")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.primaryBlue.opacity(0.07))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FieldHint: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(.textInactive)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Section card

private struct SafetySectionCard: View {
    let section: MedicalSafety.Section

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(icon: section.icon, color: section.color, size: 38)
            VStack(alignment: .leading, spacing: 5) {
                Text(section.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(section.body)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .appCard(padding: 14)
    }
}

// MARK: - Full disclaimer (pushed)

struct MedicalDisclaimerView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 10) {
                    IconBadge(icon: "exclamationmark.shield.fill", color: .statusDanger, size: 54)
                    Text(MedicalSafety.headline)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .appCard()

                ForEach(MedicalSafety.disclaimer) { SafetySectionCard(section: $0) }

                NavigationLink(destination: MethodologyView()) {
                    HStack(spacing: 12) {
                        IconBadge(icon: "function", color: .primaryBlue, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("How every number is calculated")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Text("Methodology for each figure on screen")
                                .font(.system(size: 12))
                                .foregroundColor(.textInactive)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textInactive)
                    }
                    .appCard(padding: 14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Veterinary Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Full disclaimer (modal)

struct MedicalDisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            MedicalDisclaimerView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") { dismiss() }.foregroundColor(.primaryGreen)
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Methodology

struct MethodologyView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    IconBadge(icon: "function", color: .primaryBlue, size: 50)
                    Text("Every figure comes from your own records")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Nothing on screen is estimated, predicted or downloaded. Each figure is listed below with the exact rule used to produce it.")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .appCard()

                ForEach(MedicalSafety.methodology) { SafetySectionCard(section: $0) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Methodology")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mandatory acceptance gate
//
// Shown once after onboarding, before the user can reach any medical screen.

struct MedicalDisclaimerGate: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var acknowledged = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    VStack(spacing: 12) {
                        IconBadge(icon: "exclamationmark.shield.fill", color: .statusDanger, size: 60)
                        Text("Before you start")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text(MedicalSafety.headline)
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .appCard()

                    ForEach(MedicalSafety.disclaimer) { SafetySectionCard(section: $0) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            .tabBarBottomPadding()
            }

            // Acceptance controls, pinned so they are always reachable.
            VStack(spacing: 12) {
                Button {
                    withAnimation(.appSpring) { acknowledged.toggle() }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(acknowledged ? Color.primaryGreen : Color.textInactive, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            if acknowledged {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.primaryGreen)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text("I understand that BirdMed only stores what I enter, gives no veterinary advice, and does not replace a veterinarian.")
                            .font(.system(size: 13))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(acknowledged ? [.isButton, .isSelected] : .isButton)

                Button("Continue") {
                    appVM.hasAcceptedMedicalDisclaimer = true
                }
                .buttonStyle(PrimaryButtonStyle(color: acknowledged ? .primaryGreen : .textInactive))
                .disabled(!acknowledged)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(
                Color.cardBg
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
    }
}

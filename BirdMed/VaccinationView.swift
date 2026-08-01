import SwiftUI

struct VaccinationView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var selected: Vaccination? = nil

    var upcomingList: [Vaccination] { store.upcomingVaccinations }
    var overdueList:  [Vaccination] { store.overdueVaccinations }
    var doneList:     [Vaccination] { store.vaccinations.filter { $0.isCompleted }.sorted { ($0.completedDate ?? $0.scheduledDate) > ($1.completedDate ?? $1.scheduledDate) } }
    var activeList:   [Vaccination] { store.vaccinations.filter { !$0.isCompleted }.sorted { $0.scheduledDate < $1.scheduledDate } }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    DisclaimerBanner()
                        .padding(.horizontal, 16)

                    // Summary bar
                    HStack(spacing: 0) {
                        SummaryTile(value: overdueList.count, label: "Missed", color: .statusDanger)
                        Divider().frame(height: 40)
                        SummaryTile(value: upcomingList.count, label: "Upcoming", color: .accentCyan)
                        Divider().frame(height: 40)
                        SummaryTile(value: doneList.count, label: "Completed", color: .statusNormal)
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    if !overdueList.isEmpty {
                        VacSection(title: "⚠️ Missed Doses (\(overdueList.count))", vaccs: overdueList,
                                   accentColor: .statusDanger, selected: $selected)
                            .padding(.horizontal, 16)
                    }

                    if !upcomingList.isEmpty {
                        VacSection(title: "Upcoming (\(upcomingList.count))", vaccs: upcomingList,
                                   accentColor: .accentCyan, selected: $selected)
                            .padding(.horizontal, 16)
                    }

                    if !doneList.isEmpty {
                        VacSection(title: "Completed (\(doneList.count))", vaccs: doneList,
                                   accentColor: .primaryGreen, selected: $selected)
                            .padding(.horizontal, 16)
                    }

                    if store.vaccinations.isEmpty {
                        EmptyStateView(icon: "syringe.fill", title: "No vaccinations recorded",
                                       message: "Record the plan your veterinarian prescribed so BirdMed can remind you of the dates.")
                            .padding(.top, 20)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            .tabBarBottomPadding()
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Vaccination Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.primaryGreen)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAdd) { AddVaccineView(isPresented: $showAdd) }
        .sheet(item: $selected) { v in VaccineDetailView(vaccination: v) }
    }
}

private struct SummaryTile: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }.frame(maxWidth: .infinity)
    }
}

private struct VacSection: View {
    let title: String
    let vaccs: [Vaccination]
    let accentColor: Color
    @Binding var selected: Vaccination?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textPrimary)
            ForEach(vaccs) { v in
                VaccineCard(v: v, accentColor: accentColor)
                    .onTapGesture { selected = v }
            }
        }
    }
}

struct VaccineCard: View {
    @EnvironmentObject var store: DataStore
    let v: Vaccination
    let accentColor: Color

    var daysText: String {
        if v.isCompleted { return "Done" }
        let d = Calendar.current.dateComponents([.day], from: Date(), to: v.scheduledDate).day ?? 0
        if d < 0 { return "\(-d)d overdue" }
        if d == 0 { return "Today!" }
        return "In \(d) days"
    }

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(icon: "syringe.fill", color: accentColor, size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text(v.vaccineName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                HStack(spacing: 8) {
                    InfoTag(icon: "bird.fill",   text: store.groupName(v.groupId))
                    InfoTag(icon: "drop.fill",   text: v.dose)
                }
                HStack(spacing: 8) {
                    InfoTag(icon: "calendar",    text: v.scheduledDate.formatted(.dateTime.month().day().year()))
                    if v.durationDays > 0 { InfoTag(icon: "clock", text: "\(v.durationDays)d course") }
                }
                if !v.notes.isEmpty { Text(v.notes).font(.system(size: 12)).foregroundColor(.textInactive).lineLimit(1) }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 4) {
                Text(daysText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(v.isCompleted ? .statusNormal : accentColor)
                    .multilineTextAlignment(.trailing)
                if !v.isCompleted {
                    Button {
                        withAnimation(.appSpring) { store.markVaccineDone(v) }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primaryGreen)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.statusNormal)
                }
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(16)
        .appShadow()
    }
}

private struct InfoTag: View {
    let icon, text: String
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.textInactive)
            // Truncate rather than wrap: a long group name used to push these
            // tags onto three lines and squash the card.
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Add Vaccine
struct AddVaccineView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var vaccineName = ""; @State private var dose = ""
    @State private var scheduledDate = Date(); @State private var durationDays = ""
    @State private var notes = ""; @State private var selectedGroupId: UUID?
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PrescriptionNote()

                    FormRow("Vaccine Name") {
                        AppTextField(placeholder: "Name on the prescription", text: $vaccineName, icon: "syringe.fill")
                        if showValidation && vaccineName.isEmpty { ValidationMsg("Vaccine name required") }
                    }
                    FormRow("Bird Group") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("Select Group…").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }
                        .pickerStyle(.menu)
                        .appFieldBox()
                        if showValidation && selectedGroupId == nil { ValidationMsg("Select a group") }
                    }
                    FormRow("Dose") {
                        AppTextField(placeholder: "Copy the dose from the prescription", text: $dose, icon: "drop.fill")
                        FieldHint("BirdMed does not suggest or check doses — enter exactly what your veterinarian prescribed.")
                    }
                    FormRow("Scheduled Date") {
                        DatePicker("", selection: $scheduledDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .appFieldBox()
                    }
                    FormRow("Course Duration (days)") {
                        AppTextField(placeholder: "Leave blank for a single dose", text: $durationDays,
                                     icon: "clock", keyboardType: .numberPad)
                    }
                    FormRow("Notes") { AppTextField(placeholder: "Optional notes", text: $notes) }
                    Button("Add Vaccine") {
                        guard !vaccineName.isEmpty, let gid = selectedGroupId else { showValidation = true; return }
                        let v = Vaccination(groupId: gid, vaccineName: vaccineName, dose: dose,
                                            scheduledDate: scheduledDate, durationDays: Int(durationDays) ?? 0,
                                            isCompleted: false, completedDate: nil, notes: notes,
                                            isMissed: scheduledDate < Date())
                        store.addVaccination(v)
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Vaccine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }.foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct ValidationMsg: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.system(size: 12)).foregroundColor(.statusDanger) }
}

// MARK: - Vaccine Detail
struct VaccineDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let vaccination: Vaccination

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        IconBadge(icon: "syringe.fill", color: vaccination.isCompleted ? .statusNormal : .accentCyan, size: 64)
                        Text(vaccination.vaccineName)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                        StatusBadge(
                            text: vaccination.isCompleted ? "Completed" : vaccination.isOverdue ? "Overdue" : "Scheduled",
                            color: vaccination.isCompleted ? .statusNormal : vaccination.isOverdue ? .statusDanger : .accentCyan
                        )

                        VStack(spacing: 8) {
                            DetailRow(label: "Group",     value: store.groupName(vaccination.groupId))
                            DetailRow(label: "Dose",      value: vaccination.dose.isEmpty ? "—" : vaccination.dose)
                            DetailRow(label: "Scheduled", value: vaccination.scheduledDate.formatted(.dateTime.month(.wide).day().year()))
                            if vaccination.durationDays > 0 { DetailRow(label: "Course", value: "\(vaccination.durationDays) days") }
                            if let d = vaccination.completedDate { DetailRow(label: "Completed", value: d.formatted(.dateTime.month(.wide).day().year())) }
                            if !vaccination.notes.isEmpty { DetailRow(label: "Notes", value: vaccination.notes) }
                        }
                        .padding(.top, 8)
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    if !vaccination.isCompleted {
                        Button("Mark as Done") {
                            store.markVaccineDone(vaccination)
                            dismiss()
                        }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 16)
                    }

                    Button("Delete") {
                        store.deleteVaccination(vaccination)
                        dismiss()
                    }.buttonStyle(DestructiveButtonStyle()).padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Vaccine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct DetailRow: View {
    let label, value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.textInactive).frame(width: 90, alignment: .leading)
            Text(value).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
        }
    }
}

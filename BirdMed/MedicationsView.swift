import SwiftUI

struct MedicationsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var selected: Medication? = nil
    @State private var showCompleted = false

    var activeMeds: [Medication] {
        store.medications.filter { !$0.isCompleted && $0.endDate >= Date() }
    }
    var completedMeds: [Medication] {
        store.medications.filter { $0.isCompleted || $0.endDate < Date() }
            .sorted { $0.endDate > $1.endDate }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                DisclaimerBanner()
                    .padding(.horizontal, 16)

                // Summary
                HStack(spacing: 0) {
                    SummaryTile2(value: activeMeds.count,    label: "Active",    color: .actionOrange)
                    Divider().frame(height: 40)
                    SummaryTile2(value: completedMeds.count, label: "Completed", color: .statusNormal)
                    Divider().frame(height: 40)
                    SummaryTile2(value: store.medications.count, label: "Total", color: .primaryBlue)
                }
                .appCard()
                .padding(.horizontal, 16)

                // Active
                if activeMeds.isEmpty {
                    EmptyStateView(icon: "pills.fill", title: "No active courses",
                                   message: "Record a course your veterinarian prescribed to track its dates here.")
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Courses (\(activeMeds.count))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 16)
                        ForEach(activeMeds) { m in
                            MedicationCard(med: m)
                                .onTapGesture { selected = m }
                                .padding(.horizontal, 16)
                        }
                    }
                }

                // Completed (collapsible)
                if !completedMeds.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.appSpring) { showCompleted.toggle() }
                        } label: {
                            HStack {
                                Text("Completed (\(completedMeds.count))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.textInactive)
                            }
                        }
                        .padding(.horizontal, 16)

                        if showCompleted {
                            ForEach(completedMeds.prefix(10)) { m in
                                CompletedMedRow(med: m)
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
        .navigationTitle("Medications")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22)).foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddMedicationView(isPresented: $showAdd) }
        .sheet(item: $selected) { m in MedicationDetailView(med: m) }
    }
}

private struct SummaryTile2: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - Medication Card
struct MedicationCard: View {
    @EnvironmentObject var store: DataStore
    let med: Medication

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                IconBadge(icon: med.category.icon, color: med.category.color, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(med.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        StatusBadge(text: med.category.rawValue, color: med.category.color)
                    }
                    Text(store.groupName(med.groupId))
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                    Text("\(med.dose) · \(med.frequency.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(.textInactive)
                }
            }
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(med.daysLeft) days remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text(med.endDate.formatted(.dateTime.month().day()))
                        .font(.system(size: 12))
                        .foregroundColor(.textInactive)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.freshBg)
                        Capsule()
                            .fill(med.category.color)
                            .frame(width: geo.size.width * med.progress)
                    }
                }
                .frame(height: 8)
                .animation(.softSpring, value: med.progress)
            }
        }
        .appCard()
    }
}

private struct CompletedMedRow: View {
    @EnvironmentObject var store: DataStore
    let med: Medication
    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: med.category.icon, color: Color.textInactive, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(med.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.textInactive)
                Text("\(store.groupName(med.groupId)) · Ended \(med.endDate.formatted(.dateTime.month().day()))")
                    .font(.system(size: 12)).foregroundColor(.textInactive)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.statusNormal.opacity(0.6))
        }
        .padding(12)
        .background(Color.freshBg)
        .cornerRadius(12)
    }
}

// MARK: - Add Medication
struct AddMedicationView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var name = ""; @State private var dose = ""
    @State private var frequency = Medication.FrequencyType.daily
    @State private var category = Medication.MedCategory.other
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var selectedGroupId: UUID?
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    PrescriptionNote()

                    FormRow("Medication Name") {
                        AppTextField(placeholder: "Name on the prescription", text: $name, icon: "pills.fill")
                        if showValidation && name.isEmpty { Text("Name required").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }
                    FormRow("Bird Group") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("Select Group…").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }
                        .pickerStyle(.menu).appFieldBox()
                        if showValidation && selectedGroupId == nil { Text("Select a group").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }
                    FormRow("Dose") {
                        AppTextField(placeholder: "Copy the dose from the prescription", text: $dose, icon: "drop.fill")
                        FieldHint("BirdMed does not suggest or check doses — enter exactly what your veterinarian prescribed, and observe any withdrawal period.")
                    }
                    FormRow("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(Medication.MedCategory.allCases, id: \.rawValue) { c in Text(c.rawValue).tag(c) }
                        }.pickerStyle(.menu).appFieldBox()
                    }
                    FormRow("Frequency") {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(Medication.FrequencyType.allCases, id: \.rawValue) { f in Text(f.rawValue).tag(f) }
                        }.pickerStyle(.segmented)
                    }
                    HStack(spacing: 12) {
                        FormRow("Start Date") {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact).padding(10).background(Color.freshBg).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                        }
                        FormRow("End Date") {
                            DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(.compact).padding(10).background(Color.freshBg).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                        }
                    }
                    FormRow("Notes") { AppTextField(placeholder: "Optional notes", text: $notes) }
                    Button("Start Medication Course") {
                        guard !name.isEmpty, let gid = selectedGroupId else { showValidation = true; return }
                        let m = Medication(groupId: gid, name: name, dose: dose, frequency: frequency,
                                           startDate: startDate, endDate: endDate, isCompleted: false,
                                           notes: notes, category: category)
                        store.addMedication(m)
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Medication")
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

// MARK: - Medication Detail
struct MedicationDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let med: Medication

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        IconBadge(icon: med.category.icon, color: med.category.color, size: 64)
                        Text(med.name)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                        StatusBadge(text: med.category.rawValue, color: med.category.color)

                        ProgressRing(progress: med.progress, color: med.category.color, size: 80)
                            .overlay(VStack {
                                Text("\(Int(med.progress * 100))%")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(med.category.color)
                                Text("done")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textInactive)
                            })
                            .padding(.top, 4)

                        VStack(spacing: 8) {
                            DetailRow2(label: "Group",     value: store.groupName(med.groupId))
                            DetailRow2(label: "Dose",      value: med.dose)
                            DetailRow2(label: "Frequency", value: med.frequency.rawValue)
                            DetailRow2(label: "Start",     value: med.startDate.formatted(.dateTime.month().day().year()))
                            DetailRow2(label: "End",       value: med.endDate.formatted(.dateTime.month().day().year()))
                            DetailRow2(label: "Days Left", value: med.isCompleted ? "Completed" : "\(med.daysLeft)")
                            if !med.notes.isEmpty { DetailRow2(label: "Notes", value: med.notes) }
                        }
                    }
                    .appCard().padding(.horizontal, 16)

                    if !med.isCompleted {
                        Button("Mark as Completed") {
                            store.markMedicationDone(med); dismiss()
                        }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 16)
                    }

                    Button("Delete") { store.deleteMedication(med); dismiss() }
                        .buttonStyle(DestructiveButtonStyle()).padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Medication Details")
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

private struct DetailRow2: View {
    let label, value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.textInactive).frame(width: 90, alignment: .leading)
            Text(value).font(.system(size: 14)).foregroundColor(.textPrimary)
            Spacer()
        }
    }
}

import SwiftUI

struct BirdGroupsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAddGroup   = false
    @State private var selectedGroup: BirdGroup? = nil
    @State private var filterStatus: BirdGroup.HealthStatus? = nil
    @State private var pendingDelete: BirdGroup? = nil

    var filteredGroups: [BirdGroup] {
        guard let f = filterStatus else { return store.birdGroups }
        return store.birdGroups.filter { $0.status == f }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: filterStatus == nil) {
                            withAnimation(.appSpring) { filterStatus = nil }
                        }
                        ForEach(BirdGroup.HealthStatus.allCases, id: \.rawValue) { s in
                            FilterChip(label: s.rawValue, isSelected: filterStatus == s, color: s.color) {
                                withAnimation(.appSpring) {
                                    filterStatus = filterStatus == s ? nil : s
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.cardBg)

                if filteredGroups.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "bird.fill",
                                   title: filterStatus == nil ? "No bird groups" : "No groups match this filter",
                                   message: filterStatus == nil
                                        ? "Tap ＋ in the top right to register your first flock."
                                        : "No group is currently marked as \(filterStatus?.rawValue ?? "").")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredGroups) { group in
                                BirdGroupCard(group: group)
                                    .onTapGesture { selectedGroup = group }
                                    // swipeActions only works inside a List; in a
                                    // LazyVStack it silently does nothing, so the
                                    // delete affordance is a long-press menu.
                                    .contextMenu {
                                        Button { selectedGroup = group } label: {
                                            Label("Open", systemImage: "arrow.up.forward.square")
                                        }
                                        Button(role: .destructive) { pendingDelete = group } label: {
                                            Label("Delete Group", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(16)
                        .tabBarBottomPadding()
                    }
                }
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Bird Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddGroup = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryGreen)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddGroup) { AddGroupView(isPresented: $showAddGroup) }
        .sheet(item: $selectedGroup) { g in GroupDetailView(group: g) }
        .alert("Delete this group?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        ), presenting: pendingDelete) { group in
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                withAnimation(.appSpring) { store.deleteGroup(group) }
                pendingDelete = nil
            }
        } message: { group in
            Text("“\(group.name)” will be removed. Its vaccination, medication and note records stay in the app but will no longer be linked to a group.")
        }
    }
}

// MARK: - Bird Group Card
struct BirdGroupCard: View {
    @EnvironmentObject var store: DataStore
    let group: BirdGroup
    @State private var appear = false

    var body: some View {
        HStack(spacing: 14) {
            // Emoji + type badge
            ZStack {
                Circle()
                    .fill(group.status.color.opacity(0.12))
                    .frame(width: 58, height: 58)
                Text(group.type.emoji)
                    .font(.system(size: 30))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    StatusBadge(text: group.status.rawValue, color: group.status.color)
                }
                HStack(spacing: 12) {
                    InfoPill(icon: "number", value: "\(group.count) birds")
                    InfoPill(icon: "clock", value: group.ageText)
                }
                HStack(spacing: 12) {
                    InfoPill(icon: "building.2", value: store.coopName(group.coopId))
                    InfoPill(icon: "bird", value: group.type.rawValue)
                }
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(18)
        .appShadow()
        .scaleEffect(appear ? 1.0 : 0.95)
        .opacity(appear ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                appear = true
            }
        }
    }
}

private struct InfoPill: View {
    let icon: String; let value: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.textInactive)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
        }
    }
}

private struct FilterChip: View {
    let label: String; let isSelected: Bool
    var color: Color = .primaryGreen
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.freshBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.dividerGreen, lineWidth: 1))
        }
    }
}

// MARK: - Add Group View
struct AddGroupView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var name      = ""
    @State private var type      = BirdGroup.BirdType.chicken
    @State private var count     = ""
    @State private var ageMonths = ""
    @State private var selectedCoopId: UUID? = nil
    @State private var notes     = ""
    @State private var status    = BirdGroup.HealthStatus.healthy
    @State private var showValidation = false

    var isValid: Bool { !name.isEmpty && !count.isEmpty }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Type selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Bird Type")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(BirdGroup.BirdType.allCases, id: \.rawValue) { t in
                                    Button {
                                        withAnimation(.appSpring) { type = t }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(t.emoji).font(.system(size: 28))
                                            Text(t.rawValue).font(.system(size: 11)).foregroundColor(type == t ? .primaryGreen : .textSecondary)
                                        }
                                        .padding(10)
                                        .background(type == t ? Color.primaryGreen.opacity(0.1) : Color.freshBg)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(type == t ? Color.primaryGreen : Color.dividerGreen, lineWidth: 1.5))
                                    }
                                }
                            }
                        }
                    }

                    FormRow("Group Name") {
                        AppTextField(placeholder: "e.g. Layer Hens #1", text: $name, icon: "bird.fill")
                        if showValidation && name.isEmpty {
                            Text("Name is required").font(.system(size: 12)).foregroundColor(.statusDanger)
                        }
                    }

                    HStack(spacing: 12) {
                        FormRow("Count") {
                            AppTextField(placeholder: "0", text: $count,
                                         icon: "number", keyboardType: .numberPad)
                        }
                        FormRow("Age (months)") {
                            AppTextField(placeholder: "0", text: $ageMonths,
                                         icon: "clock", keyboardType: .numberPad)
                        }
                    }

                    FormRow("Coop") {
                        Picker("Select Coop", selection: $selectedCoopId) {
                            Text("No Coop").tag(UUID?.none)
                            ForEach(store.coops) { c in
                                Text(c.name).tag(UUID?.some(c.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .appFieldBox()
                    }

                    FormRow("Health Status") {
                        Picker("Status", selection: $status) {
                            ForEach(BirdGroup.HealthStatus.allCases, id: \.rawValue) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    FormRow("Notes (optional)") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(10)
                                .background(Color.freshBg)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                            if notes.isEmpty {
                                Text("Additional observations...")
                                    .foregroundColor(.textInactive)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                    }

                    Button("Save Group") {
                        if isValid {
                            let g = BirdGroup(
                                name: name, type: type,
                                count: Int(count) ?? 0,
                                ageMonths: Int(ageMonths) ?? 0,
                                coopId: selectedCoopId,
                                notes: notes, status: status,
                                createdAt: Date()
                            )
                            store.addGroup(g)
                            isPresented = false
                        } else { showValidation = true }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Bird Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Group Detail View
struct GroupDetailView: View {
    @EnvironmentObject var store: DataStore
    let group: BirdGroup
    @Environment(\.dismiss) var dismiss
    @State private var showEdit = false
    @State private var editedGroup: BirdGroup

    init(group: BirdGroup) {
        self.group = group
        _editedGroup = State(initialValue: group)
    }

    var groupVaccinations: [Vaccination] { store.vaccinations.filter { $0.groupId == group.id } }
    var groupMedications:  [Medication]  { store.medications.filter  { $0.groupId == group.id } }
    var groupNotes:        [BirdNote]    { store.notes.filter         { $0.groupId == group.id } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header card
                    VStack(spacing: 12) {
                        Text(group.type.emoji).font(.system(size: 60))
                        Text(group.name)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.textPrimary)
                        StatusBadge(text: group.status.rawValue, color: group.status.color)

                        HStack(spacing: 24) {
                            DetailStat(icon: "number", value: "\(group.count)", label: "Birds")
                            DetailStat(icon: "clock", value: group.ageText, label: "Age")
                            DetailStat(icon: "building.2", value: store.coopName(group.coopId), label: "Coop")
                        }
                        .padding(.top, 4)

                        if !group.notes.isEmpty {
                            Text(group.notes)
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    // Vaccinations
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Vaccinations (\(groupVaccinations.count))")
                        if groupVaccinations.isEmpty {
                            Text("No vaccinations scheduled").font(.system(size: 14)).foregroundColor(.textInactive)
                        } else {
                            ForEach(groupVaccinations.prefix(3)) { v in
                                HStack {
                                    IconBadge(icon: "syringe.fill", color: v.isCompleted ? .primaryGreen : .accentCyan, size: 30)
                                    Text(v.vaccineName).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(v.isCompleted ? "Done" : v.scheduledDate.formatted(.dateTime.month().day()))
                                        .font(.system(size: 12))
                                        .foregroundColor(v.isCompleted ? .statusNormal : .textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    // Medications
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Medications (\(groupMedications.count))")
                        if groupMedications.isEmpty {
                            Text("No medications recorded").font(.system(size: 14)).foregroundColor(.textInactive)
                        } else {
                            ForEach(groupMedications.prefix(3)) { m in
                                HStack {
                                    IconBadge(icon: m.category.icon, color: m.category.color, size: 30)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(m.name).font(.system(size: 14, weight: .medium)).foregroundColor(.textPrimary)
                                        Text(m.frequency.rawValue).font(.system(size: 12)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    if m.isCompleted {
                                        StatusBadge(text: "Done", color: .statusNormal)
                                    } else {
                                        Text("\(m.daysLeft)d left").font(.system(size: 12)).foregroundColor(.actionOrange)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Notes (\(groupNotes.count))")
                        if groupNotes.isEmpty {
                            Text("No notes for this group").font(.system(size: 14)).foregroundColor(.textInactive)
                        } else {
                            ForEach(groupNotes.prefix(2)) { n in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(n.content).font(.system(size: 14)).foregroundColor(.textPrimary).lineLimit(2)
                                    Text(n.date.formatted(.dateTime.month().day().hour().minute()))
                                        .font(.system(size: 11)).foregroundColor(.textInactive)
                                }
                                .padding(.vertical, 4)
                                AppDivider()
                            }
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    // Delete button
                    Button("Delete Group") {
                        store.deleteGroup(group)
                        dismiss()
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .padding(.horizontal, 16)

                    Spacer(minLength: 60)
                }
                .padding(.top, 16)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Group Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showEdit = true }
                        .foregroundColor(.primaryGreen)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showEdit) { EditGroupView(group: group) }
    }
}

private struct DetailStat: View {
    let icon, value, label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.primaryGreen)
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.textPrimary)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }
    }
}

// MARK: - Edit Group View
private struct EditGroupView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let group: BirdGroup

    @State private var name: String
    @State private var count: String
    @State private var ageMonths: String
    @State private var status: BirdGroup.HealthStatus
    @State private var notes: String
    @State private var selectedCoopId: UUID?
    @State private var type: BirdGroup.BirdType

    init(group: BirdGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _count = State(initialValue: "\(group.count)")
        _ageMonths = State(initialValue: "\(group.ageMonths)")
        _status = State(initialValue: group.status)
        _notes = State(initialValue: group.notes)
        _selectedCoopId = State(initialValue: group.coopId)
        _type = State(initialValue: group.type)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FormRow("Group Name") { AppTextField(placeholder: "Group name", text: $name) }
                    HStack(spacing: 12) {
                        FormRow("Count") {
                            AppTextField(placeholder: "Count", text: $count, keyboardType: .numberPad)
                        }
                        FormRow("Age (months)") {
                            AppTextField(placeholder: "Age", text: $ageMonths, keyboardType: .numberPad)
                        }
                    }
                    FormRow("Bird Type") {
                        Picker("Type", selection: $type) {
                            ForEach(BirdGroup.BirdType.allCases, id: \.rawValue) { t in
                                Text("\(t.emoji) \(t.rawValue)").tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .appFieldBox()
                    }
                    FormRow("Health Status") {
                        Picker("Status", selection: $status) {
                            ForEach(BirdGroup.HealthStatus.allCases, id: \.rawValue) { s in Text(s.rawValue).tag(s) }
                        }.pickerStyle(.segmented)
                    }
                    FormRow("Coop") {
                        Picker("Coop", selection: $selectedCoopId) {
                            Text("No Coop").tag(UUID?.none)
                            ForEach(store.coops) { c in Text(c.name).tag(UUID?.some(c.id)) }
                        }
                        .pickerStyle(.menu)
                        .appFieldBox()
                    }
                    FormRow("Notes") {
                        AppTextField(placeholder: "Notes", text: $notes)
                    }
                    Button("Save Changes") {
                        var updated = group
                        updated.name = name; updated.count = Int(count) ?? group.count
                        updated.ageMonths = Int(ageMonths) ?? group.ageMonths
                        updated.status = status; updated.notes = notes
                        updated.coopId = selectedCoopId; updated.type = type
                        store.updateGroup(updated)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.primaryGreen)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

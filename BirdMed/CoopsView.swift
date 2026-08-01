import SwiftUI

struct CoopsView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var selected: Coop? = nil
    @State private var pendingDelete: Coop? = nil

    var body: some View {
        ScrollView {
            if store.coops.isEmpty {
                EmptyStateView(icon: "building.2.fill", title: "No coops recorded",
                               message: "Add a coop to track its capacity and see how many birds it holds.")
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(store.coops) { coop in
                        CoopCard(coop: coop)
                            .onTapGesture { selected = coop }
                            // Long-press menu, because swipeActions is inert
                            // outside a List.
                            .contextMenu {
                                Button { selected = coop } label: {
                                    Label("Open", systemImage: "arrow.up.forward.square")
                                }
                                Button(role: .destructive) { pendingDelete = coop } label: {
                                    Label("Delete Coop", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(16)
                .tabBarBottomPadding()
            }
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Coops & Housing")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primaryGreen)
                }
                .accessibilityLabel("Add coop")
            }
        }
        .sheet(isPresented: $showAdd) { AddCoopView(isPresented: $showAdd) }
        .sheet(item: $selected) { c in CoopDetailView(coop: c) }
        .alert("Delete this coop?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        ), presenting: pendingDelete) { coop in
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                withAnimation(.appSpring) { store.deleteCoop(coop) }
                pendingDelete = nil
            }
        } message: { coop in
            Text("“\(coop.name)” will be removed. Groups assigned to it are kept, but will show as having no coop.")
        }
    }
}

// MARK: - Coop Card
struct CoopCard: View {
    @EnvironmentObject var store: DataStore
    let coop: Coop

    var occupied: Int { store.occupancy(for: coop) }
    /// Clamped so an over-filled coop can't draw a bar past the track.
    var utilization: Double {
        guard coop.capacity > 0 else { return 0 }
        return min(Double(occupied) / Double(coop.capacity), 1.0)
    }
    var isOverCapacity: Bool { coop.capacity > 0 && occupied > coop.capacity }
    var utilizationColor: Color {
        utilization > 0.9 ? .statusDanger : utilization > 0.7 ? .statusRisk : .statusNormal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                IconBadge(icon: "building.2.fill", color: .actionOrange, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(coop.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.textPrimary)
                    StatusBadge(text: coop.condition.rawValue, color: coop.condition.color)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing) {
                    Text("\(occupied)/\(coop.capacity)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isOverCapacity ? .statusDanger : utilizationColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(isOverCapacity ? "over capacity" : "occupied")
                        .font(.system(size: 11))
                        .foregroundColor(isOverCapacity ? .statusDanger : .textInactive)
                }
            }

            // Capacity bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Capacity")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(Int(utilization * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(utilizationColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.freshBg)
                        Capsule()
                            .fill(utilizationColor)
                            .frame(width: geo.size.width * utilization)
                    }
                }
                .frame(height: 8)
            }

            if !coop.notes.isEmpty {
                Text(coop.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
        }
        .appCard()
    }
}

// MARK: - Add Coop
struct AddCoopView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool
    @State private var name = ""; @State private var capacity = ""; @State private var notes = ""
    @State private var condition = Coop.CoopCondition.good
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FormRow("Coop Name") {
                        AppTextField(placeholder: "e.g. Main Coop A", text: $name, icon: "building.2.fill")
                        if showValidation && name.isEmpty { Text("Name required").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }
                    FormRow("Capacity (birds)") {
                        AppTextField(placeholder: "0", text: $capacity,
                                     icon: "number", keyboardType: .numberPad)
                    }
                    FormRow("Condition") {
                        Picker("Condition", selection: $condition) {
                            ForEach(Coop.CoopCondition.allCases, id: \.rawValue) { c in Text(c.rawValue).tag(c) }
                        }.pickerStyle(.segmented)
                    }
                    FormRow("Notes") { AppTextField(placeholder: "Additional notes", text: $notes) }
                    Button("Save Coop") {
                        guard !name.isEmpty else { showValidation = true; return }
                        store.addCoop(Coop(name: name, capacity: Int(capacity) ?? 0, condition: condition, notes: notes))
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Coop")
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

// MARK: - Coop Detail
struct CoopDetailView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss
    let coop: Coop
    var groups: [BirdGroup] { store.birdGroups.filter { $0.coopId == coop.id } }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CoopCard(coop: coop).padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Bird Groups (\(groups.count))")
                        if groups.isEmpty {
                            Text("No groups assigned to this coop")
                                .font(.system(size: 14)).foregroundColor(.textInactive)
                        } else {
                            ForEach(groups) { g in
                                HStack(spacing: 12) {
                                    Text(g.type.emoji).font(.system(size: 28))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(g.name).font(.system(size: 15, weight: .semibold)).foregroundColor(.textPrimary)
                                        Text("\(g.count) birds · \(g.ageText)").font(.system(size: 13)).foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    StatusBadge(text: g.status.rawValue, color: g.status.color)
                                }
                                .padding(.vertical, 6)
                                AppDivider()
                            }
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    Button("Delete Coop") { store.deleteCoop(coop); dismiss() }
                        .buttonStyle(DestructiveButtonStyle()).padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle(coop.name)
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

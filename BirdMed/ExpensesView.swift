import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd  = false
    @State private var filterCat: Expense.ExpenseCategory? = nil
    @State private var selectedMonth = Date()

    var monthExpenses: [Expense] {
        store.expenses(for: selectedMonth)
    }

    var filtered: [Expense] {
        guard let c = filterCat else { return monthExpenses }
        return monthExpenses.filter { $0.category == c }
    }

    var monthTotal: Double { monthExpenses.reduce(0) { $0 + $1.amount } }

    var categoryTotals: [(Expense.ExpenseCategory, Double)] {
        var dict: [Expense.ExpenseCategory: Double] = [:]
        for e in monthExpenses { dict[e.category, default: 0] += e.amount }
        return dict.sorted { $0.value > $1.value }
    }

    /// Recording an expense in a month that hasn't happened yet is almost always
    /// a mis-tap, so forward paging stops at the current month.
    private var canGoForward: Bool {
        !Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
            && selectedMonth < Date()
    }

    private func shiftMonth(_ delta: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: delta, to: selectedMonth) else { return }
        withAnimation(.appSpring) { selectedMonth = next }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Month navigator
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left.circle.fill").font(.system(size: 26)).foregroundColor(.primaryGreen)
                    }
                    .accessibilityLabel("Previous month")
                    Spacer()
                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.textPrimary)
                    Spacer()
                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(canGoForward ? .primaryGreen : .textInactive.opacity(0.35))
                    }
                    .disabled(!canGoForward)
                    .accessibilityLabel("Next month")
                }
                .padding(.horizontal, 16)

                // Month total card
                VStack(spacing: 8) {
                    Text("Total Expenses")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary)
                    Text(Formatters.currency(monthTotal))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    // Category pills
                    if !categoryTotals.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categoryTotals, id: \.0.rawValue) { (cat, amt) in
                                    VStack(spacing: 4) {
                                        Image(systemName: cat.icon).font(.system(size: 16)).foregroundColor(cat.color)
                                        Text(Formatters.currencyCompact(amt))
                                            .font(.system(size: 13, weight: .bold)).foregroundColor(cat.color)
                                        Text(cat.rawValue).font(.system(size: 10)).foregroundColor(.textInactive)
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(cat.color.opacity(0.1)).cornerRadius(12)
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                }
                .appCard()
                .padding(.horizontal, 16)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ExpFilterChip(label: "All", isSelected: filterCat == nil, color: .primaryGreen) {
                            withAnimation(.appSpring) { filterCat = nil }
                        }
                        ForEach(Expense.ExpenseCategory.allCases, id: \.rawValue) { c in
                            ExpFilterChip(label: c.rawValue, isSelected: filterCat == c, color: c.color) {
                                withAnimation(.appSpring) { filterCat = filterCat == c ? nil : c }
                            }
                        }
                    }.padding(.horizontal, 16)
                }

                if filtered.isEmpty {
                    EmptyStateView(icon: "dollarsign.circle.fill", title: "No expenses",
                                   message: "Record your first expense for this month.")
                        .padding(.top, 20)
                } else {
                    VStack(spacing: 10) {
                        ForEach(filtered) { e in
                            ExpenseRow(expense: e)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddExpenseView(isPresented: $showAdd) }
    }
}

private struct ExpFilterChip: View {
    let label: String; let isSelected: Bool; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? color : Color.freshBg).cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.dividerGreen, lineWidth: 1))
        }
    }
}

// MARK: - Expense Row
private struct ExpenseRow: View {
    @EnvironmentObject var store: DataStore
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon: expense.category.icon, color: expense.category.color, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.category.rawValue)
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.textPrimary)
                HStack(spacing: 6) {
                    Text(expense.date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.system(size: 12)).foregroundColor(.textInactive)
                    if let gid = expense.groupId {
                        Text("· \(store.groupName(gid))").font(.system(size: 12)).foregroundColor(.textInactive)
                    }
                }
                if !expense.notes.isEmpty {
                    Text(expense.notes).font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.currency(expense.amount))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button { withAnimation(.appSpring) { store.deleteExpense(expense) } } label: {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundColor(.statusDanger.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete expense")
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .cornerRadius(14)
        .appShadow()
    }
}

// MARK: - Add Expense
struct AddExpenseView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var category = Expense.ExpenseCategory.feed
    @State private var amount = ""; @State private var notes = ""
    @State private var date = Date(); @State private var selectedGroupId: UUID?
    @State private var showValidation = false

    private var decimalSeparator: String { Locale.current.decimalSeparator ?? "." }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Category selector grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category").font(.system(size: 13, weight: .semibold)).foregroundColor(.textSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(Expense.ExpenseCategory.allCases, id: \.rawValue) { c in
                                Button { withAnimation(.appSpring) { category = c } } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: c.icon).font(.system(size: 22))
                                            .foregroundColor(category == c ? .white : c.color)
                                        Text(c.rawValue).font(.system(size: 11, weight: .medium))
                                            .foregroundColor(category == c ? .white : .textSecondary)
                                    }
                                    .padding(.vertical, 14).frame(maxWidth: .infinity)
                                    .background(category == c ? c.color : c.color.opacity(0.1)).cornerRadius(12)
                                }
                            }
                        }
                    }
                    FormRow("Amount (\(Formatters.currencySymbol))") {
                        AppTextField(placeholder: "0\(decimalSeparator)00", text: $amount,
                                     icon: "number", keyboardType: .decimalPad)
                        if showValidation {
                            Text("Enter an amount greater than zero")
                                .font(.system(size: 12)).foregroundColor(.statusDanger)
                        }
                    }
                    FormRow("Date") {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact).padding(10).background(Color.freshBg).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                    }
                    FormRow("Bird Group (optional)") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("Not specific").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }.pickerStyle(.menu).appFieldBox()
                    }
                    FormRow("Notes") { AppTextField(placeholder: "Optional notes", text: $notes) }
                    Button("Add Expense") {
                        // Parsed via NumberFormatter so "12,50" works on locales
                        // that use a comma as the decimal separator.
                        guard let amt = Formatters.parseAmount(amount), amt > 0 else {
                            showValidation = true; return
                        }
                        store.addExpense(Expense(category: category, amount: amt, date: date,
                                                 notes: notes, groupId: selectedGroupId))
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Expense")
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

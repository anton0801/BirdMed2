import SwiftUI

struct TasksView: View {
    @EnvironmentObject var store: DataStore
    @State private var showAdd = false
    @State private var filterCategory: BirdTask.TaskCategory? = nil

    var todayTasks: [BirdTask] {
        let all = store.tasks.filter { Calendar.current.isDateInToday($0.dueDate) }
        return filterCategory == nil ? all : all.filter { $0.category == filterCategory }
    }
    var upcomingTasks: [BirdTask] {
        let all = store.tasks.filter { !Calendar.current.isDateInToday($0.dueDate) && $0.dueDate > Date() && !$0.isDone }
        return filterCategory == nil ? all : all.filter { $0.category == filterCategory }
    }
    var overdueTasks: [BirdTask] {
        store.tasks.filter { $0.dueDate < Date() && !Calendar.current.isDateInToday($0.dueDate) && !$0.isDone }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Summary bar
                HStack(spacing: 0) {
                    SummaryTile3(value: todayTasks.filter { !$0.isDone }.count, label: "Today",    color: .primaryBlue)
                    Divider().frame(height: 40)
                    SummaryTile3(value: overdueTasks.count,                      label: "Overdue",  color: .statusDanger)
                    Divider().frame(height: 40)
                    SummaryTile3(value: store.tasks.filter { $0.isDone }.count,  label: "Done",     color: .statusNormal)
                }
                .appCard()
                .padding(.horizontal, 16)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip2(label: "All", isSelected: filterCategory == nil) {
                            withAnimation(.appSpring) { filterCategory = nil }
                        }
                        ForEach(BirdTask.TaskCategory.allCases, id: \.rawValue) { cat in
                            FilterChip2(label: cat.rawValue, isSelected: filterCategory == cat, color: cat.color) {
                                withAnimation(.appSpring) { filterCategory = filterCategory == cat ? nil : cat }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !overdueTasks.isEmpty {
                    TaskSection(title: "⚠️ Overdue", tasks: overdueTasks, emptyMsg: nil)
                        .padding(.horizontal, 16)
                }

                TaskSection(title: "Today (\(todayTasks.count))", tasks: todayTasks, emptyMsg: "Nothing due today – well done! 🎉")
                    .padding(.horizontal, 16)

                if !upcomingTasks.isEmpty {
                    TaskSection(title: "Upcoming (\(upcomingTasks.count))", tasks: upcomingTasks.prefix(10).map{$0}, emptyMsg: nil)
                        .padding(.horizontal, 16)
                }

            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            .tabBarBottomPadding()
        }
        .background(LinearGradient.appBg.ignoresSafeArea())
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddTaskView(isPresented: $showAdd) }
    }
}

private struct SummaryTile3: View {
    let value: Int; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.textInactive)
        }.frame(maxWidth: .infinity)
    }
}

private struct FilterChip2: View {
    let label: String; let isSelected: Bool
    var color: Color = .primaryBlue
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? color : Color.freshBg)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? color : Color.dividerGreen, lineWidth: 1))
        }
    }
}

private struct TaskSection: View {
    @EnvironmentObject var store: DataStore
    let title: String
    let tasks: [BirdTask]
    let emptyMsg: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textPrimary)

            if tasks.isEmpty, let msg = emptyMsg {
                Text(msg).font(.system(size: 14)).foregroundColor(.textInactive).frame(maxWidth: .infinity).padding(.vertical, 8)
            } else {
                ForEach(tasks) { task in
                    TaskCard(task: task)
                }
            }
        }
    }
}

// MARK: - Task Card
struct TaskCard: View {
    @EnvironmentObject var store: DataStore
    let task: BirdTask
    @State private var showDelete = false

    var body: some View {
        HStack(spacing: 12) {
            Button { withAnimation(.appSpring) { store.toggleTask(task) } } label: {
                ZStack {
                    Circle()
                        .stroke(task.isDone ? Color.statusNormal : task.priority.color, lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(task.isDone ? Color.statusNormal : Color.clear))
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(task.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(task.isDone ? .textInactive : .textPrimary)
                        .strikethrough(task.isDone)
                    Spacer()
                    StatusBadge(text: task.priority.rawValue, color: task.priority.color)
                }
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.system(size: 12)).foregroundColor(.textInactive).lineLimit(1)
                }
                HStack(spacing: 8) {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 10)).foregroundColor(task.category.color)
                    Text(task.category.rawValue)
                        .font(.system(size: 11)).foregroundColor(.textSecondary)
                    Text("·")
                    Text(task.dueDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 11)).foregroundColor(.textInactive)
                }
            }

            Button { store.deleteTask(task) } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13)).foregroundColor(.statusDanger.opacity(0.6))
            }
        }
        .padding(12)
        .background(task.isDone ? Color.freshBg : Color.cardBg)
        .cornerRadius(14)
        .appShadow()
        .animation(.appSpring, value: task.isDone)
    }
}

// MARK: - Add Task
struct AddTaskView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var title = ""; @State private var desc = ""
    @State private var dueDate = Date(); @State private var category = BirdTask.TaskCategory.other
    @State private var priority = BirdTask.Priority.medium; @State private var selectedGroupId: UUID?
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FormRow("Task Title") {
                        AppTextField(placeholder: "e.g. Clean Coop A", text: $title, icon: "checklist")
                        if showValidation && title.isEmpty { Text("Title required").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }
                    FormRow("Description") {
                        AppTextField(placeholder: "Optional details", text: $desc)
                    }
                    FormRow("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(BirdTask.TaskCategory.allCases, id: \.rawValue) { c in
                                Label(c.rawValue, systemImage: c.icon).tag(c)
                            }
                        }.pickerStyle(.menu).appFieldBox()
                    }
                    FormRow("Priority") {
                        HStack(spacing: 8) {
                            ForEach(BirdTask.Priority.allCases, id: \.rawValue) { p in
                                Button {
                                    withAnimation(.appSpring) { priority = p }
                                } label: {
                                    Text(p.rawValue)
                                        .font(.system(size: 14, weight: priority == p ? .semibold : .regular))
                                        .foregroundColor(priority == p ? .white : p.color)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(priority == p ? p.color : p.color.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    FormRow("Due Date") {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.compact).padding(10).background(Color.freshBg).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                    }
                    FormRow("Bird Group (optional)") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("All Groups").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }.pickerStyle(.menu).appFieldBox()
                    }
                    Button("Add Task") {
                        guard !title.isEmpty else { showValidation = true; return }
                        let t = BirdTask(title: title, taskDescription: desc, isDone: false,
                                         dueDate: dueDate, category: category, groupId: selectedGroupId, priority: priority)
                        store.addTask(t)
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Task")
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

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: DataStore
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var showAddEvent = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    /// Weekday headers rotated to the locale's first day of the week, so the
    /// grid lines up for keepers whose week starts on Monday.
    private var weekdays: [String] {
        let cal = Calendar.current
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let offset = cal.firstWeekday - 1
        return (0..<7).map { symbols[($0 + offset) % 7] }
    }

    var daysInMonth: [Date?] {
        let cal = Calendar.current
        let start = displayedMonth.startOfMonth
        guard let range = cal.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        // Weekday is 1...7 from the calendar; shift it into the locale's own
        // column order rather than assuming Sunday is column zero.
        let leading = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        for d in range { days.append(cal.date(byAdding: .day, value: d - 1, to: start)) }
        return days
    }

    var selectedEvents: [CalendarEvent] { store.events(on: selectedDate) }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Month nav
                    HStack {
                        Button {
                            withAnimation(.appSpring) {
                                displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)!
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 28)).foregroundColor(.primaryGreen)
                        }
                        Spacer()
                        Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button {
                            withAnimation(.appSpring) {
                                displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)!
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 28)).foregroundColor(.primaryGreen)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Calendar grid
                    VStack(spacing: 8) {
                        // Week day headers
                        HStack(spacing: 0) {
                            // Indexed, because weekday initials repeat ("T", "S")
                            // and would collide as ForEach identities.
                            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, d in
                                Text(d)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.textInactive)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                                if let day = day {
                                    DayCell(day: day, selectedDate: $selectedDate)
                                } else {
                                    Color.clear.frame(height: 44)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                    // Today button
                    HStack {
                        Spacer()
                        Button("Today") {
                            withAnimation(.appSpring) {
                                selectedDate = Date()
                                displayedMonth = Date()
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.primaryGreen.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.trailing, 16)
                    }

                    // Events for selected day
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Button { showAddEvent = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22)).foregroundColor(.primaryGreen)
                            }
                        }

                        if selectedEvents.isEmpty {
                            Text("No events scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(.textInactive)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(selectedEvents) { event in
                                CalendarEventRow(event: event)
                            }
                        }
                    }
                    .appCard()
                    .padding(.horizontal, 16)

                }
                .padding(.top, 12)
                .padding(.bottom, 16)
            .tabBarBottomPadding()
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEvent = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.primaryGreen)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddEvent) {
            AddCalendarEventView(isPresented: $showAddEvent, defaultDate: selectedDate)
        }
    }
}

// MARK: - Day Cell
private struct DayCell: View {
    @EnvironmentObject var store: DataStore
    let day: Date
    @Binding var selectedDate: Date

    var isSelected:   Bool { Calendar.current.isDate(day, inSameDayAs: selectedDate) }
    var isToday:      Bool { Calendar.current.isDateInToday(day) }
    var hasEvents:    Bool { store.hasEvents(on: day) }
    var eventColors: [Color] {
        let events = store.events(on: day)
        return Array(Set(events.map { $0.type.color })).prefix(3).map { $0 }
    }

    var body: some View {
        Button { withAnimation(.appSpring) { selectedDate = day } } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : isToday ? .primaryGreen : .textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Group {
                            if isSelected { Circle().fill(Color.primaryGreen) }
                            else if isToday { Circle().stroke(Color.primaryGreen, lineWidth: 2) }
                            else { Circle().fill(Color.clear) }
                        }
                    )

                if hasEvents {
                    HStack(spacing: 2) {
                        ForEach(Array(eventColors.enumerated()), id: \.offset) { _, c in
                            Circle().fill(c).frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 6)
                }
            }
        }
    }
}

// MARK: - Calendar Event Row
struct CalendarEventRow: View {
    @EnvironmentObject var store: DataStore
    let event: CalendarEvent
    @State private var showConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(event.type.color)
                .frame(width: 4, height: 44)
            IconBadge(icon: event.type.icon, color: event.type.color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(event.isCompleted ? .textInactive : .textPrimary)
                    .strikethrough(event.isCompleted)
                HStack(spacing: 6) {
                    Text(event.type.rawValue)
                        .font(.system(size: 11)).foregroundColor(.textInactive)
                    if let gid = event.groupId {
                        Text("· \(store.groupName(gid))").font(.system(size: 11)).foregroundColor(.textInactive)
                    }
                }
            }
            Spacer()
            Button {
                withAnimation(.appSpring) { store.toggleEventDone(event) }
            } label: {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(event.isCompleted ? .statusNormal : .textInactive)
            }
            Button {
                store.deleteEvent(event)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.statusDanger.opacity(0.7))
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Add Calendar Event
struct AddCalendarEventView: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool
    var defaultDate: Date = Date()

    @State private var title = ""; @State private var eventDate: Date
    @State private var type = CalendarEvent.EventType.care
    @State private var selectedGroupId: UUID?; @State private var notes = ""
    @State private var showValidation = false

    init(isPresented: Binding<Bool>, defaultDate: Date = Date()) {
        self._isPresented = isPresented
        _eventDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FormRow("Event Title") {
                        AppTextField(placeholder: "e.g. Vaccination Day", text: $title, icon: "calendar")
                        if showValidation && title.isEmpty { Text("Title required").font(.system(size: 12)).foregroundColor(.statusDanger) }
                    }
                    FormRow("Type") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(CalendarEvent.EventType.allCases, id: \.rawValue) { t in
                                Button {
                                    withAnimation(.appSpring) { type = t }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: t.icon).font(.system(size: 18)).foregroundColor(type == t ? .white : t.color)
                                        Text(t.rawValue).font(.system(size: 10, weight: .medium)).foregroundColor(type == t ? .white : .textSecondary)
                                    }
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(type == t ? t.color : t.color.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    FormRow("Date & Time") {
                        DatePicker("", selection: $eventDate)
                            .datePickerStyle(.compact).padding(10).background(Color.freshBg).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dividerGreen, lineWidth: 1))
                    }
                    FormRow("Bird Group (optional)") {
                        Picker("Group", selection: $selectedGroupId) {
                            Text("All Groups").tag(UUID?.none)
                            ForEach(store.birdGroups) { g in Text("\(g.type.emoji) \(g.name)").tag(UUID?.some(g.id)) }
                        }
                        .pickerStyle(.menu).appFieldBox()
                    }
                    FormRow("Notes") { AppTextField(placeholder: "Optional notes", text: $notes) }
                    Button("Add Event") {
                        guard !title.isEmpty else { showValidation = true; return }
                        let e = CalendarEvent(title: title, date: eventDate, type: type,
                                              groupId: selectedGroupId, notes: notes, isCompleted: false)
                        store.addEvent(e)
                        isPresented = false
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
            .background(LinearGradient.appBg.ignoresSafeArea())
            .navigationTitle("Add Event")
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

// MARK: - Date extension
extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
    }
}

import Foundation
import Combine

final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var birdGroups:    [BirdGroup]     = []
    @Published var coops:         [Coop]          = []
    @Published var vaccinations:  [Vaccination]   = []
    @Published var medications:   [Medication]    = []
    @Published var calendarEvents:[CalendarEvent] = []
    @Published var tasks:         [BirdTask]      = []
    @Published var alerts:        [BirdAlert]     = []
    @Published var notes:         [BirdNote]      = []
    @Published var expenses:      [Expense]       = []
    @Published var history:       [HistoryRecord] = []

    /// Derived from the records above on every change — never persisted, so a
    /// stale suggestion can't outlive the record that produced it.
    @Published private(set) var recommendations: [Recommendation] = []

    @Published private(set) var isDemoDataLoaded = false

    private var savedRecKeys: Set<String> = []
    private var addedRecKeys: Set<String> = []
    private var demoIDs:      Set<UUID>   = []

    private let enc = JSONEncoder()
    private let dec = JSONDecoder()

    private enum Key {
        static let birdGroups     = "birdGroups"
        static let coops          = "coops"
        static let vaccinations   = "vaccinations"
        static let medications    = "medications"
        static let calendarEvents = "calendarEvents"
        static let tasks          = "tasks"
        static let alerts         = "alerts"
        static let notes          = "notes"
        static let expenses       = "expenses"
        static let history        = "historyRecords"
        static let savedRecKeys   = "savedRecommendationKeys"
        static let addedRecKeys   = "addedRecommendationKeys"
        static let demoIDs        = "demoRecordIDs"
        static let demoLoaded     = "isDemoDataLoaded"

        /// Written by builds that shipped app-authored medical tips. Purged on launch.
        static let legacyRecommendations = "recommendations"

        static let all = [birdGroups, coops, vaccinations, medications, calendarEvents,
                          tasks, alerts, notes, expenses, history,
                          savedRecKeys, addedRecKeys, demoIDs, demoLoaded,
                          legacyRecommendations]
    }

    init() {
        // Earlier versions persisted a hard-coded list of medical suggestions
        // (specific vaccines and supplements). Drop it on sight — this build
        // must never surface app-authored clinical advice.
        UserDefaults.standard.removeObject(forKey: Key.legacyRecommendations)

        load()
        checkAutoAlerts()
        refreshRecommendations()
    }

    // MARK: - Persistence

    func save() {
        persist(birdGroups,     key: Key.birdGroups)
        persist(coops,          key: Key.coops)
        persist(vaccinations,   key: Key.vaccinations)
        persist(medications,    key: Key.medications)
        persist(calendarEvents, key: Key.calendarEvents)
        persist(tasks,          key: Key.tasks)
        persist(alerts,         key: Key.alerts)
        persist(notes,          key: Key.notes)
        persist(expenses,       key: Key.expenses)
        persist(history,        key: Key.history)

        let d = UserDefaults.standard
        d.set(Array(savedRecKeys), forKey: Key.savedRecKeys)
        d.set(Array(addedRecKeys), forKey: Key.addedRecKeys)
        d.set(demoIDs.map(\.uuidString), forKey: Key.demoIDs)
        d.set(isDemoDataLoaded, forKey: Key.demoLoaded)

        refreshRecommendations()
    }

    private func load() {
        birdGroups     = fetch(Key.birdGroups)
        coops          = fetch(Key.coops)
        vaccinations   = fetch(Key.vaccinations)
        medications    = fetch(Key.medications)
        calendarEvents = fetch(Key.calendarEvents)
        tasks          = fetch(Key.tasks)
        alerts         = fetch(Key.alerts)
        notes          = fetch(Key.notes)
        expenses       = fetch(Key.expenses)
        history        = fetch(Key.history)

        let d = UserDefaults.standard
        savedRecKeys    = Set(d.stringArray(forKey: Key.savedRecKeys) ?? [])
        addedRecKeys    = Set(d.stringArray(forKey: Key.addedRecKeys) ?? [])
        demoIDs         = Set((d.stringArray(forKey: Key.demoIDs) ?? []).compactMap(UUID.init(uuidString:)))
        isDemoDataLoaded = d.bool(forKey: Key.demoLoaded)
    }

    private func persist<T: Encodable>(_ val: [T], key: String) {
        if let d = try? enc.encode(val) { UserDefaults.standard.set(d, forKey: key) }
    }

    private func fetch<T: Decodable>(_ key: String) -> [T] {
        guard let d = UserDefaults.standard.data(forKey: key),
              let v = try? dec.decode([T].self, from: d) else { return [] }
        return v
    }

    private func log(_ action: String, target: String, type: HistoryRecord.HistoryType) {
        let r = HistoryRecord(action: action, target: target, date: Date(), type: type)
        history.insert(r, at: 0)
        if history.count > 300 { history = Array(history.prefix(300)) }
    }

    // MARK: - Bird Groups

    func addGroup(_ g: BirdGroup) {
        birdGroups.append(g); log("Added bird group", target: g.name, type: .created); save()
    }
    func updateGroup(_ g: BirdGroup) {
        if let i = birdGroups.firstIndex(where: { $0.id == g.id }) {
            birdGroups[i] = g; log("Updated", target: g.name, type: .updated); save()
        }
    }
    func deleteGroup(_ g: BirdGroup) {
        birdGroups.removeAll { $0.id == g.id }; log("Deleted group", target: g.name, type: .deleted); save()
    }

    // MARK: - Coops

    func addCoop(_ c: Coop) {
        coops.append(c); log("Added coop", target: c.name, type: .created); save()
    }
    func updateCoop(_ c: Coop) {
        if let i = coops.firstIndex(where: { $0.id == c.id }) {
            coops[i] = c; log("Updated coop", target: c.name, type: .updated); save()
        }
    }
    func deleteCoop(_ c: Coop) {
        coops.removeAll { $0.id == c.id }; log("Deleted coop", target: c.name, type: .deleted); save()
    }
    func occupancy(for coop: Coop) -> Int {
        birdGroups.filter { $0.coopId == coop.id }.reduce(0) { $0 + $1.count }
    }

    // MARK: - Vaccinations

    func addVaccination(_ v: Vaccination) {
        vaccinations.append(v)
        log("Scheduled vaccination", target: "\(v.vaccineName) for \(groupName(v.groupId))", type: .created)
        save()
    }
    func updateVaccination(_ v: Vaccination) {
        if let i = vaccinations.firstIndex(where: { $0.id == v.id }) {
            vaccinations[i] = v; save()
        }
    }
    func deleteVaccination(_ v: Vaccination) {
        vaccinations.removeAll { $0.id == v.id }
        resolveAlert(matching: "Missed: \(v.vaccineName)")
        save()
    }
    func markVaccineDone(_ v: Vaccination) {
        if let i = vaccinations.firstIndex(where: { $0.id == v.id }) {
            vaccinations[i].isCompleted = true
            vaccinations[i].completedDate = Date()
            log("Completed vaccination", target: "\(v.vaccineName) for \(groupName(v.groupId))", type: .completed)
            resolveAlert(matching: "Missed: \(v.vaccineName)")
            save()
        }
    }

    // MARK: - Medications

    func addMedication(_ m: Medication) {
        medications.append(m)
        log("Started medication", target: "\(m.name) for \(groupName(m.groupId))", type: .created); save()
    }
    func updateMedication(_ m: Medication) {
        if let i = medications.firstIndex(where: { $0.id == m.id }) {
            medications[i] = m; save()
        }
    }
    func deleteMedication(_ m: Medication) {
        medications.removeAll { $0.id == m.id }
        resolveAlert(matching: "Ending Soon: \(m.name)")
        save()
    }
    func markMedicationDone(_ m: Medication) {
        if let i = medications.firstIndex(where: { $0.id == m.id }) {
            medications[i].isCompleted = true
            log("Completed medication", target: "\(m.name) for \(groupName(m.groupId))", type: .completed)
            resolveAlert(matching: "Ending Soon: \(m.name)")
            save()
        }
    }

    // MARK: - Calendar Events

    func addEvent(_ e: CalendarEvent) {
        calendarEvents.append(e); log("Added event", target: e.title, type: .created); save()
    }
    func updateEvent(_ e: CalendarEvent) {
        if let i = calendarEvents.firstIndex(where: { $0.id == e.id }) {
            calendarEvents[i] = e; save()
        }
    }
    func deleteEvent(_ e: CalendarEvent) {
        calendarEvents.removeAll { $0.id == e.id }; save()
    }
    func toggleEventDone(_ e: CalendarEvent) {
        if let i = calendarEvents.firstIndex(where: { $0.id == e.id }) {
            calendarEvents[i].isCompleted.toggle()
            if calendarEvents[i].isCompleted { log("Completed event", target: e.title, type: .completed) }
            save()
        }
    }
    func events(on date: Date) -> [CalendarEvent] {
        calendarEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                      .sorted { $0.date < $1.date }
    }
    func hasEvents(on date: Date) -> Bool { !events(on: date).isEmpty }

    // MARK: - Tasks

    func addTask(_ t: BirdTask) {
        tasks.append(t); log("Created task", target: t.title, type: .created); save()
    }
    func updateTask(_ t: BirdTask) {
        if let i = tasks.firstIndex(where: { $0.id == t.id }) {
            tasks[i] = t; save()
        }
    }
    func toggleTask(_ t: BirdTask) {
        if let i = tasks.firstIndex(where: { $0.id == t.id }) {
            tasks[i].isDone.toggle()
            if tasks[i].isDone { log("Completed task", target: t.title, type: .completed) }
            save()
        }
    }
    func deleteTask(_ t: BirdTask) {
        tasks.removeAll { $0.id == t.id }; save()
    }
    var todayTasks: [BirdTask] {
        tasks.filter { Calendar.current.isDateInToday($0.dueDate) }
             .sorted { !$0.isDone && $1.isDone }
    }

    // MARK: - Alerts

    func addAlert(_ a: BirdAlert) {
        guard !alerts.contains(where: { $0.title == a.title && !$0.isResolved }) else { return }
        alerts.append(a); save()
    }
    func resolveAlert(_ a: BirdAlert) {
        if let i = alerts.firstIndex(where: { $0.id == a.id }) {
            alerts[i].isResolved = true
            log("Resolved alert", target: a.title, type: .completed); save()
        }
    }
    func snoozeAlert(_ a: BirdAlert) {
        if let i = alerts.firstIndex(where: { $0.id == a.id }) {
            alerts[i].isSnoozed = true; save()
        }
    }
    private func resolveAlert(matching title: String) {
        for i in alerts.indices where alerts[i].title == title && !alerts[i].isResolved {
            alerts[i].isResolved = true
        }
    }
    var pendingAlerts: [BirdAlert] {
        alerts.filter { !$0.isResolved && !$0.isSnoozed }
    }

    // MARK: - Notes

    func addNote(_ n: BirdNote) {
        notes.insert(n, at: 0); log("Added note", target: String(n.content.prefix(30)), type: .created); save()
    }
    func updateNote(_ n: BirdNote) {
        if let i = notes.firstIndex(where: { $0.id == n.id }) {
            notes[i] = n; save()
        }
    }
    func deleteNote(_ n: BirdNote) {
        notes.removeAll { $0.id == n.id }; save()
    }

    // MARK: - Expenses

    func addExpense(_ e: Expense) {
        expenses.insert(e, at: 0)
        log("Added expense", target: "\(e.category.rawValue): \(Formatters.currency(e.amount))", type: .created)
        save()
    }
    func deleteExpense(_ e: Expense) {
        expenses.removeAll { $0.id == e.id }; save()
    }
    var totalExpenses: Double { expenses.reduce(0) { $0 + $1.amount } }
    func expenses(for month: Date) -> [Expense] {
        let cal = Calendar.current
        return expenses.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    // MARK: - Recommendations
    //
    // Purely operational prompts derived from the user's own records. They never
    // name a medicine, a dose or a schedule — where a clinical decision is
    // involved, they point at the veterinarian instead.

    func saveRec(_ r: Recommendation) {
        if savedRecKeys.contains(r.key) { savedRecKeys.remove(r.key) } else { savedRecKeys.insert(r.key) }
        save()
    }

    func addRecToTasks(_ r: Recommendation) {
        guard !addedRecKeys.contains(r.key) else { return }
        let due = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        addTask(BirdTask(title: r.title, taskDescription: r.body, isDone: false,
                         dueDate: due, category: r.taskCategory, groupId: nil, priority: .medium))
        addedRecKeys.insert(r.key)
        save()
    }

    private func refreshRecommendations() {
        recommendations = buildRecommendations().map { rec in
            var r = rec
            r.isSaved = savedRecKeys.contains(r.key)
            r.isAddedToTasks = addedRecKeys.contains(r.key)
            return r
        }
    }

    private func buildRecommendations() -> [Recommendation] {
        var out: [Recommendation] = []
        let cal = Calendar.current
        let now = Date()

        func add(_ key: String, _ type: Recommendation.RecommendationType,
                 _ taskCategory: BirdTask.TaskCategory, _ title: String, _ body: String) {
            out.append(Recommendation(key: key, title: title, body: body, type: type,
                                      taskCategory: taskCategory,
                                      isAddedToTasks: false, isSaved: false, date: now))
        }

        if birdGroups.isEmpty {
            add("add-first-group", .add, .other,
                "Add your first bird group",
                "BirdMed has no records yet. Register a group to start keeping vaccination, medication, observation and cost history in one place.")
            return out
        }

        if coops.isEmpty {
            add("add-coop", .add, .other,
                "Record your coops",
                "No coop is registered, so occupancy and capacity can't be shown. Add each coop and assign your groups to it.")
        }

        let overdue = overdueVaccinations
        if !overdue.isEmpty {
            let one = overdue.count == 1
            add("overdue-vaccinations", .check, .health,
                one ? "1 vaccination entry is past its date"
                    : "\(overdue.count) vaccination entries are past their date",
                "Mark \(one ? "it" : "each one") done if it was already given. If it was missed, contact your veterinarian to agree what happens next — BirdMed only compares dates and cannot tell whether a dose was actually administered.")
        }

        let unvaccinated = birdGroups.filter { g in !vaccinations.contains { $0.groupId == g.id } }
        if !unvaccinated.isEmpty {
            add("groups-without-vaccination", .add, .health,
                "\(unvaccinated.count) \(unvaccinated.count == 1 ? "group has" : "groups have") no vaccination record",
                "\(listNames(unvaccinated.map(\.name))) — nothing is recorded yet. Ask your veterinarian which plan applies to these birds and enter what they prescribe.")
        }

        let flagged = birdGroups.filter { $0.status != .healthy }
        if !flagged.isEmpty {
            add("groups-flagged", .check, .health,
                "\(flagged.count) \(flagged.count == 1 ? "group is" : "groups are") flagged as needing attention",
                "\(listNames(flagged.map(\.name))) — you marked these as something other than Healthy. Review your notes and speak to your veterinarian if the status hasn't improved.")
        }

        let endingSoon = activeMedications.filter { $0.daysLeft <= 3 }
        if !endingSoon.isEmpty {
            add("courses-ending", .check, .medication,
                "\(endingSoon.count) recorded \(endingSoon.count == 1 ? "course ends" : "courses end") within 3 days",
                "Confirm with your veterinarian what should happen when the course finishes, and remember any withdrawal period that applies before eggs or meat re-enter the food chain.")
        }

        if let cutoff = cal.date(byAdding: .day, value: -14, to: now),
           !notes.contains(where: { $0.date >= cutoff }) {
            add("log-observations", .change, .health,
                "No observations recorded in the last 14 days",
                "Regular written notes make it far easier for a veterinarian to see how a situation developed. Record what you see, when you saw it, and what was advised.")
        }

        if expenses.isEmpty {
            add("track-expenses", .add, .other,
                "Start recording costs",
                "No expenses are recorded yet. Logging feed, medicine and equipment costs lets the Reports screen break down where the money goes.")
        }

        return out
    }

    private func listNames(_ names: [String]) -> String {
        let shown = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? "\(shown) and \(names.count - 3) more" : shown
    }

    // MARK: - Computed

    var totalBirds: Int { birdGroups.reduce(0) { $0 + $1.count } }
    var upcomingVaccinations: [Vaccination] {
        vaccinations.filter { $0.isUpcoming }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    var overdueVaccinations: [Vaccination] {
        vaccinations.filter { $0.isOverdue }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    var activeMedications: [Medication] {
        medications.filter { !$0.isCompleted && $0.endDate >= Date() }
    }
    var isEmpty: Bool {
        birdGroups.isEmpty && coops.isEmpty && vaccinations.isEmpty && medications.isEmpty
            && calendarEvents.isEmpty && tasks.isEmpty && notes.isEmpty && expenses.isEmpty
    }

    // MARK: - Helpers

    func groupName(_ id: UUID?) -> String {
        guard let id = id else { return "All Groups" }
        return birdGroups.first(where: { $0.id == id })?.name ?? "Deleted group"
    }
    func coopName(_ id: UUID?) -> String {
        guard let id = id else { return "No Coop" }
        return coops.first(where: { $0.id == id })?.name ?? "Deleted coop"
    }

    // MARK: - Auto alerts
    //
    // Two date rules only — see MedicalSafety.methodology. No symptom is interpreted.

    func checkAutoAlerts() {
        for v in overdueVaccinations {
            addAlert(BirdAlert(title: "Missed: \(v.vaccineName)",
                               alertDescription: "Scheduled date has passed for \(groupName(v.groupId)). Mark it done or contact your veterinarian.",
                               severity: .missed, isResolved: false, isSnoozed: false,
                               date: Date(), groupId: v.groupId))
        }
        for m in activeMedications where m.daysLeft <= 1 {
            addAlert(BirdAlert(title: "Ending Soon: \(m.name)",
                               alertDescription: "This recorded course ends within 24 hours for \(groupName(m.groupId)).",
                               severity: .checkNeeded, isResolved: false, isSnoozed: false,
                               date: Date(), groupId: m.groupId))
        }
    }

    // MARK: - Demo data
    //
    // Only ever runs when the user taps the button for it.

    func loadDemoData() {
        let bundle = DemoData.build()

        coops.append(contentsOf: bundle.coops)
        birdGroups.append(contentsOf: bundle.birdGroups)
        vaccinations.append(contentsOf: bundle.vaccinations)
        medications.append(contentsOf: bundle.medications)
        tasks.append(contentsOf: bundle.tasks)
        calendarEvents.append(contentsOf: bundle.calendarEvents)
        notes.append(contentsOf: bundle.notes)
        expenses.append(contentsOf: bundle.expenses)

        demoIDs.formUnion(bundle.allIDs)
        isDemoDataLoaded = true

        log("Loaded demo data", target: "Sample records for exploring the app", type: .created)
        save()
        checkAutoAlerts()
    }

    /// Removes exactly the records the demo introduced, leaving anything the
    /// user added themselves untouched.
    func removeDemoData() {
        guard !demoIDs.isEmpty else {
            isDemoDataLoaded = false; save(); return
        }
        let ids = demoIDs

        coops.removeAll          { ids.contains($0.id) }
        birdGroups.removeAll     { ids.contains($0.id) }
        vaccinations.removeAll   { ids.contains($0.id) }
        medications.removeAll    { ids.contains($0.id) }
        tasks.removeAll          { ids.contains($0.id) }
        calendarEvents.removeAll { ids.contains($0.id) }
        notes.removeAll          { ids.contains($0.id) }
        expenses.removeAll       { ids.contains($0.id) }
        // Alerts raised for demo groups would otherwise outlive their subject.
        alerts.removeAll         { $0.groupId.map(ids.contains) ?? false }

        demoIDs.removeAll()
        isDemoDataLoaded = false
        log("Removed demo data", target: "Sample records deleted", type: .deleted)
        save()
    }

    // MARK: - Destructive

    func clearAll() {
        birdGroups = []; coops = []; vaccinations = []; medications = []
        calendarEvents = []; tasks = []; alerts = []; notes = []
        expenses = []; history = []
        savedRecKeys = []; addedRecKeys = []; demoIDs = []
        isDemoDataLoaded = false

        Key.all.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        refreshRecommendations()
    }
}

// MARK: - Formatting

enum Formatters {
    /// One place for money so the whole app agrees on the user's locale and
    /// currency instead of hard-coding a dollar sign.
    static func currency(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }

    /// Compact variant for tight spaces (chips, bar labels).
    static func currencyCompact(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
    }

    static var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    /// Parses user-typed amounts, accepting both "12.5" and "12,5".
    static func parseAmount(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = .current
        if let n = f.number(from: trimmed) { return n.doubleValue }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}

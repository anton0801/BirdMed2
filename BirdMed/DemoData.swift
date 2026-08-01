import Foundation

// MARK: - Demo data
//
// Never loaded automatically. The user has to ask for it explicitly from
// Settings or from the empty dashboard, and every record is prefixed "Demo:"
// so it can never be mistaken for a real one.
//
// Deliberately contains no medicine dose, no vaccine dose and no schedule
// interval: doses read "See prescription", because the app must not put a
// clinical number in front of the user that a veterinarian did not.

enum DemoData {

    struct Bundle {
        var coops:          [Coop]
        var birdGroups:     [BirdGroup]
        var vaccinations:   [Vaccination]
        var medications:    [Medication]
        var tasks:          [BirdTask]
        var calendarEvents: [CalendarEvent]
        var notes:          [BirdNote]
        var expenses:       [Expense]

        /// Every id this bundle introduces, so the same records can be removed
        /// later without touching anything the user added themselves.
        var allIDs: Set<UUID> {
            var ids = Set<UUID>()
            coops.forEach          { ids.insert($0.id) }
            birdGroups.forEach     { ids.insert($0.id) }
            vaccinations.forEach   { ids.insert($0.id) }
            medications.forEach    { ids.insert($0.id) }
            tasks.forEach          { ids.insert($0.id) }
            calendarEvents.forEach { ids.insert($0.id) }
            notes.forEach          { ids.insert($0.id) }
            expenses.forEach       { ids.insert($0.id) }
            return ids
        }
    }

    /// Placeholder used everywhere a dose would go. The demo must not teach a dosage.
    private static let dosePlaceholder = "See prescription"

    private static let sampleNote = "Sample record — not a real prescription."

    static func build(now: Date = Date(), calendar: Calendar = .current) -> Bundle {
        func daysAgo(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: now) ?? now }
        func daysAhead(_ n: Int) -> Date { calendar.date(byAdding: .day, value: n, to: now) ?? now }

        let coopA = Coop(name: "Demo: Main Coop", capacity: 100, condition: .good,
                         notes: "Sample coop record.")
        let coopB = Coop(name: "Demo: Second Coop", capacity: 50, condition: .fair,
                         notes: "Sample coop record.")

        let layers = BirdGroup(name: "Demo: Layer Hens", type: .chicken, count: 48, ageMonths: 14,
                               coopId: coopA.id, notes: "Sample group record.",
                               status: .healthy, createdAt: daysAgo(180))
        let broilers = BirdGroup(name: "Demo: Broiler Batch", type: .chicken, count: 32, ageMonths: 3,
                                 coopId: coopB.id, notes: "Sample group record.",
                                 status: .atRisk, createdAt: daysAgo(30))
        let ducks = BirdGroup(name: "Demo: Duck Flock", type: .duck, count: 15, ageMonths: 8,
                              coopId: coopA.id, notes: "Sample group record.",
                              status: .healthy, createdAt: daysAgo(90))

        let vaccinations = [
            Vaccination(groupId: layers.id, vaccineName: "Demo: Vaccine A", dose: dosePlaceholder,
                        scheduledDate: daysAhead(3), durationDays: 0, isCompleted: false,
                        completedDate: nil, notes: sampleNote, isMissed: false),
            Vaccination(groupId: broilers.id, vaccineName: "Demo: Vaccine B", dose: dosePlaceholder,
                        scheduledDate: daysAgo(2), durationDays: 0, isCompleted: false,
                        completedDate: nil, notes: "Sample overdue record — shows how a missed entry looks.",
                        isMissed: true),
            Vaccination(groupId: ducks.id, vaccineName: "Demo: Vaccine C", dose: dosePlaceholder,
                        scheduledDate: daysAgo(20), durationDays: 0, isCompleted: true,
                        completedDate: daysAgo(20), notes: sampleNote, isMissed: false),
        ]

        let medications = [
            Medication(groupId: broilers.id, name: "Demo: Medicine A", dose: dosePlaceholder,
                       frequency: .twiceDaily, startDate: daysAgo(3), endDate: daysAhead(4),
                       isCompleted: false, notes: sampleNote, category: .other),
            Medication(groupId: layers.id, name: "Demo: Supplement B", dose: dosePlaceholder,
                       frequency: .daily, startDate: daysAgo(1), endDate: daysAhead(13),
                       isCompleted: false, notes: sampleNote, category: .vitamin),
        ]

        let tasks = [
            BirdTask(title: "Demo: Clean the main coop", taskDescription: "Sample task record.",
                     isDone: false, dueDate: now, category: .cleaning, groupId: layers.id, priority: .high),
            BirdTask(title: "Demo: Check the drinkers", taskDescription: "Sample task record.",
                     isDone: false, dueDate: now, category: .water, groupId: nil, priority: .medium),
            BirdTask(title: "Demo: Weigh the feed", taskDescription: "Sample task record.",
                     isDone: true, dueDate: daysAgo(1), category: .feed, groupId: broilers.id, priority: .low),
        ]

        let events = [
            CalendarEvent(title: "Demo: Vaccination day", date: daysAhead(3), type: .vaccination,
                          groupId: layers.id, notes: sampleNote, isCompleted: false),
            CalendarEvent(title: "Demo: Coop cleaning", date: daysAhead(1), type: .care,
                          groupId: nil, notes: sampleNote, isCompleted: false),
            CalendarEvent(title: "Demo: Veterinary check-up", date: daysAhead(7), type: .checkup,
                          groupId: broilers.id, notes: sampleNote, isCompleted: false),
        ]

        let notes = [
            BirdNote(groupId: broilers.id,
                     content: "Demo: sample observation entry. Record what you saw and what your veterinarian advised.",
                     date: daysAgo(3), imageData: nil),
            BirdNote(groupId: layers.id,
                     content: "Demo: sample production note. Egg count steady this week.",
                     date: daysAgo(7), imageData: nil),
        ]

        let expenses = [
            Expense(category: .feed, amount: 245.50, date: daysAgo(5),
                    notes: "Demo: sample expense.", groupId: layers.id),
            Expense(category: .medicine, amount: 89.00, date: daysAgo(3),
                    notes: "Demo: sample expense.", groupId: broilers.id),
            Expense(category: .equipment, amount: 35.00, date: daysAgo(10),
                    notes: "Demo: sample expense.", groupId: nil),
        ]

        return Bundle(coops: [coopA, coopB],
                      birdGroups: [layers, broilers, ducks],
                      vaccinations: vaccinations,
                      medications: medications,
                      tasks: tasks,
                      calendarEvents: events,
                      notes: notes,
                      expenses: expenses)
    }
}

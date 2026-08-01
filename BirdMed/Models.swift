import Foundation
import SwiftUI

// MARK: - BirdGroup
struct BirdGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var type: BirdType
    var count: Int
    var ageMonths: Int
    var coopId: UUID?
    var notes: String
    var status: HealthStatus
    var createdAt: Date

    enum BirdType: String, CaseIterable, Codable {
        case chicken = "Chicken"
        case duck = "Duck"
        case turkey = "Turkey"
        case goose = "Goose"
        case quail = "Quail"
        case pigeon = "Pigeon"
        case other = "Other"

        var emoji: String {
            switch self {
            case .chicken: return "🐔"
            case .duck:    return "🦆"
            case .turkey:  return "🦃"
            case .goose:   return "🪿"
            case .quail:   return "🐦"
            case .pigeon:  return "🕊️"
            case .other:   return "🐣"
            }
        }
        var sfSymbol: String { "bird.fill" }
    }

    enum HealthStatus: String, CaseIterable, Codable {
        case healthy         = "Healthy"
        case atRisk          = "At Risk"
        case sick            = "Sick"
        case underTreatment  = "Under Treatment"

        var color: Color {
            switch self {
            case .healthy:        return .statusNormal
            case .atRisk:         return .statusRisk
            case .sick:           return .statusDanger
            case .underTreatment: return .actionOrange
            }
        }
    }

    var ageText: String {
        ageMonths < 12
            ? "\(ageMonths)mo"
            : "\(ageMonths / 12)yr \(ageMonths % 12 > 0 ? "\(ageMonths % 12)mo" : "")"
    }
}

// MARK: - Coop
struct Coop: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var capacity: Int
    var condition: CoopCondition
    var notes: String

    enum CoopCondition: String, CaseIterable, Codable {
        case good        = "Good"
        case fair        = "Fair"
        case needsRepair = "Needs Repair"

        var color: Color {
            switch self {
            case .good:        return .statusNormal
            case .fair:        return .statusRisk
            case .needsRepair: return .statusDanger
            }
        }
    }
}

// MARK: - Vaccination
struct Vaccination: Identifiable, Codable {
    var id: UUID = UUID()
    var groupId: UUID
    var vaccineName: String
    var dose: String
    var scheduledDate: Date
    var durationDays: Int
    var isCompleted: Bool
    var completedDate: Date?
    var notes: String
    var isMissed: Bool

    var isUpcoming: Bool { !isCompleted && scheduledDate >= Date() }
    var isOverdue: Bool  { !isCompleted && scheduledDate < Date() }
}

// MARK: - Medication
struct Medication: Identifiable, Codable {
    var id: UUID = UUID()
    var groupId: UUID
    var name: String
    var dose: String
    var frequency: FrequencyType
    var startDate: Date
    var endDate: Date
    var isCompleted: Bool
    var notes: String
    var category: MedCategory

    enum FrequencyType: String, CaseIterable, Codable {
        case daily      = "Daily"
        case twiceDaily = "Twice Daily"
        case weekly     = "Weekly"
        case asNeeded   = "As Needed"
    }

    enum MedCategory: String, CaseIterable, Codable {
        case antibiotic = "Antibiotic"
        case vitamin    = "Vitamin"
        case parasite   = "Antiparasitic"
        case probiotic  = "Probiotic"
        case other      = "Other"

        var color: Color {
            switch self {
            case .antibiotic: return .statusDanger
            case .vitamin:    return .primaryGreen
            case .parasite:   return .actionOrange
            case .probiotic:  return .accentCyan
            case .other:      return .textInactive
            }
        }
        var icon: String {
            switch self {
            case .antibiotic: return "cross.fill"
            case .vitamin:    return "leaf.fill"
            case .parasite:   return "ladybug.fill"
            case .probiotic:  return "circle.hexagongrid.fill"
            case .other:      return "pills.fill"
            }
        }
    }

    var progress: Double {
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1.0)
    }

    var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
}

// MARK: - CalendarEvent
struct CalendarEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var type: EventType
    var groupId: UUID?
    var notes: String
    var isCompleted: Bool

    enum EventType: String, CaseIterable, Codable {
        case care        = "Care"
        case feeding     = "Feeding"
        case treatment   = "Treatment"
        case transport   = "Transport"
        case vaccination = "Vaccination"
        case checkup     = "Check-up"

        var color: Color {
            switch self {
            case .care:        return .primaryGreen
            case .feeding:     return .actionOrange
            case .treatment:   return .statusDanger
            case .transport:   return .primaryBlue
            case .vaccination: return .accentCyan
            case .checkup:     return .lightGreen
            }
        }
        var icon: String {
            switch self {
            case .care:        return "heart.fill"
            case .feeding:     return "fork.knife"
            case .treatment:   return "cross.case.fill"
            case .transport:   return "car.fill"
            case .vaccination: return "syringe.fill"
            case .checkup:     return "stethoscope"
            }
        }
    }
}

// MARK: - BirdTask
struct BirdTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var taskDescription: String
    var isDone: Bool
    var dueDate: Date
    var category: TaskCategory
    var groupId: UUID?
    var priority: Priority

    enum TaskCategory: String, CaseIterable, Codable {
        case cleaning  = "Clean Coop"
        case water     = "Check Water"
        case feed      = "Prepare Feed"
        case health    = "Health Check"
        case medication = "Medication"
        case other     = "Other"

        var icon: String {
            switch self {
            case .cleaning:   return "sparkles"
            case .water:      return "drop.fill"
            case .feed:       return "leaf.fill"
            case .health:     return "heart.fill"
            case .medication: return "pills.fill"
            case .other:      return "checkmark.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .cleaning:   return .accentCyan
            case .water:      return .primaryBlue
            case .feed:       return .primaryGreen
            case .health:     return .statusDanger
            case .medication: return .actionOrange
            case .other:      return .textInactive
            }
        }
    }

    enum Priority: String, CaseIterable, Codable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"

        var color: Color {
            switch self {
            case .low:    return .statusNormal
            case .medium: return .statusRisk
            case .high:   return .statusDanger
            }
        }
    }
}

// MARK: - BirdAlert
struct BirdAlert: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var alertDescription: String
    var severity: AlertSeverity
    var isResolved: Bool
    var isSnoozed: Bool
    var date: Date
    var groupId: UUID?

    enum AlertSeverity: String, CaseIterable, Codable {
        case risk        = "Risk"
        case missed      = "Missed"
        case checkNeeded = "Check Needed"

        var color: Color {
            switch self {
            case .risk:        return .statusRisk
            case .missed:      return .statusDanger
            case .checkNeeded: return .actionOrange
            }
        }
        var icon: String { "exclamationmark.triangle.fill" }
    }
}

// MARK: - BirdNote
struct BirdNote: Identifiable, Codable {
    var id: UUID = UUID()
    var groupId: UUID?
    var content: String
    var date: Date
    var imageData: Data?
}

// MARK: - Expense
struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var category: ExpenseCategory
    var amount: Double
    var date: Date
    var notes: String
    var groupId: UUID?

    enum ExpenseCategory: String, CaseIterable, Codable {
        case feed      = "Feed"
        case medicine  = "Medicine"
        case transport = "Transport"
        case equipment = "Equipment"
        case other     = "Other"

        var icon: String {
            switch self {
            case .feed:      return "leaf.fill"
            case .medicine:  return "cross.fill"
            case .transport: return "car.fill"
            case .equipment: return "wrench.fill"
            case .other:     return "ellipsis.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .feed:      return .primaryGreen
            case .medicine:  return .statusDanger
            case .transport: return .primaryBlue
            case .equipment: return .actionOrange
            case .other:     return .textInactive
            }
        }
    }
}

// MARK: - HistoryRecord
struct HistoryRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var action: String
    var target: String
    var date: Date
    var type: HistoryType

    enum HistoryType: String, CaseIterable, Codable {
        case created   = "Created"
        case updated   = "Updated"
        case completed = "Completed"
        case deleted   = "Deleted"

        var icon: String {
            switch self {
            case .created:   return "plus.circle.fill"
            case .updated:   return "pencil.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .deleted:   return "trash.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .created:   return .primaryGreen
            case .updated:   return .primaryBlue
            case .completed: return .activeGreen
            case .deleted:   return .statusDanger
            }
        }
    }
}

// MARK: - Recommendation
//
// Derived at runtime from the user's own records (see DataStore). `key` is the
// stable identity used to remember which ones were saved or turned into tasks,
// so those flags survive the list being rebuilt.
struct Recommendation: Identifiable {
    var key: String
    var title: String
    var body: String
    var type: RecommendationType
    /// Category applied when the user turns this into a task.
    var taskCategory: BirdTask.TaskCategory
    var isAddedToTasks: Bool
    var isSaved: Bool
    var date: Date

    var id: String { key }

    enum RecommendationType: String, CaseIterable {
        case change = "What to Change"
        case check  = "What to Check"
        case add    = "What to Add"

        var icon: String {
            switch self {
            case .change: return "arrow.triangle.2.circlepath"
            case .check:  return "magnifyingglass"
            case .add:    return "plus.circle.fill"
            }
        }
        var color: Color {
            switch self {
            case .change: return .actionOrange
            case .check:  return .primaryBlue
            case .add:    return .primaryGreen
            }
        }
    }
}

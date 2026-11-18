import Foundation

/// What money was spent on. Stored by its raw value ("groceries"), so renaming the display
/// name never breaks saved data.
public enum ExpenseCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case groceries, dining, transport, housing, bills, shopping, entertainment, health, other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .groceries: return "Groceries"
        case .dining: return "Eating out"
        case .transport: return "Transport"
        case .housing: return "Housing"
        case .bills: return "Bills"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .health: return "Health"
        case .other: return "Other"
        }
    }

    /// An SF Symbol, so each category has a shape as well as a colour.
    public var symbolName: String {
        switch self {
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .transport: return "tram"
        case .housing: return "house"
        case .bills: return "doc.text"
        case .shopping: return "bag"
        case .entertainment: return "film"
        case .health: return "cross.case"
        case .other: return "square.grid.2x2"
        }
    }

    /// Reads a stored raw value; anything unknown becomes .other instead of crashing.
    public init(storedValue: String) {
        self = ExpenseCategory(rawValue: storedValue) ?? .other
    }
}

/// A plain copy of one expense. The app stores expenses with SwiftData; the maths in this
/// package works on these value types, so it can be tested without a database.
public struct ExpenseRecord: Hashable, Sendable, Identifiable {
    public let id: UUID
    public let amount: Money
    public let category: ExpenseCategory
    public let date: Date
    public let note: String

    public init(id: UUID = UUID(), amount: Money, category: ExpenseCategory, date: Date, note: String = "") {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
    }
}

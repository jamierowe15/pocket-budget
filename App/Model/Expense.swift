import BudgetKit
import Foundation
import SwiftData

/// One thing the person paid for. @Model turns this class into a SwiftData table: every stored
/// property becomes a column and changes are saved and observed automatically.
@Model
final class Expense {
    var amountCents: Int64
    /// Stored as text ("groceries") so adding a category later never breaks old data.
    var categoryRaw: String
    var date: Date
    var note: String
    var createdAt: Date

    init(amount: Money, category: ExpenseCategory, date: Date, note: String = "", createdAt: Date = Date()) {
        self.amountCents = amount.cents
        self.categoryRaw = category.rawValue
        self.date = date
        self.note = note
        self.createdAt = createdAt
    }

    // Computed properties aren't stored; they just make the stored ones easier to use.
    var money: Money {
        get { Money(cents: amountCents) }
        set { amountCents = newValue.cents }
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(storedValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    /// A plain value copy for BudgetKit's maths.
    var record: ExpenseRecord {
        ExpenseRecord(amount: money, category: category, date: date, note: note)
    }
}

/// A monthly limit for one category. `.unique` means at most one row per category.
@Model
final class CategoryBudget {
    @Attribute(.unique) var categoryRaw: String
    var limitCents: Int64

    init(category: ExpenseCategory, limit: Money) {
        self.categoryRaw = category.rawValue
        self.limitCents = limit.cents
    }

    var category: ExpenseCategory { ExpenseCategory(storedValue: categoryRaw) }
    var money: Money { Money(cents: limitCents) }
}

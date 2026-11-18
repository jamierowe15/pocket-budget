import BudgetKit
import Foundation
import Observation

/// The add/edit form's state and rules. @Observable: SwiftUI redraws whatever reads a
/// property when it changes. No SwiftUI import, so it's tested with plain unit tests.
@Observable
final class ExpenseFormModel {
    static let maximum = Money(cents: 10_000_000) // $100,000: anything bigger is probably a typo

    var amountText: String
    var category: ExpenseCategory
    var date: Date
    var note: String

    private let expense: Expense?
    private let decimalSeparator: Character

    init(expense: Expense?, today: Date, locale: Locale = .current) {
        self.expense = expense
        decimalSeparator = locale.decimalSeparator?.first ?? "."
        amountText = expense.map { $0.money.plainString.replacingOccurrences(of: ".", with: String(locale.decimalSeparator?.first ?? ".")) } ?? ""
        category = expense?.category ?? .groceries
        date = expense?.date ?? today
        note = expense?.note ?? ""
    }

    var isEditing: Bool { expense != nil }
    var title: String { isEditing ? "Edit expense" : "New expense" }

    var money: Money? { Money(parsing: amountText, decimalSeparator: decimalSeparator) }

    var isValid: Bool {
        guard let money else { return false }
        return money > .zero && money <= Self.maximum
    }

    /// Shown under the amount. Nothing while the field is still empty.
    var validationMessage: String? {
        guard !amountText.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        guard let money else { return "Enter an amount like 12.50" }
        if money == .zero { return "The amount must be more than zero" }
        if money > Self.maximum { return "That's more than $100,000. Check the amount." }
        return nil
    }

    /// Adds a new expense or updates the one being edited. Returns false if the form isn't valid.
    @MainActor
    @discardableResult
    func save(using repository: ExpenseRepository) -> Bool {
        guard isValid, let money else { return false }
        if let expense {
            repository.update(expense, amount: money, category: category, date: date, note: note)
        } else {
            repository.add(amount: money, category: category, date: date, note: note)
        }
        return true
    }

    @MainActor
    func delete(using repository: ExpenseRepository) {
        if let expense { repository.delete(expense) }
    }
}

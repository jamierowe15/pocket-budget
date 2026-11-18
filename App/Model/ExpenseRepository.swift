import BudgetKit
import Foundation
import SwiftData
import WidgetKit

/// Every write to the database goes through here, so the rules live in one place:
/// save, then refresh the widget. Screens read with @Query and write with this.
@MainActor
struct ExpenseRepository {
    let context: ModelContext
    var calendar: Calendar = .current

    @discardableResult
    func add(amount: Money, category: ExpenseCategory, date: Date, note: String) -> Expense {
        let expense = Expense(amount: amount, category: category, date: date,
                              note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(expense)
        save()
        return expense
    }

    func update(_ expense: Expense, amount: Money, category: ExpenseCategory, date: Date, note: String) {
        expense.money = amount
        expense.category = category
        expense.date = date
        expense.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func delete(_ expense: Expense) {
        context.delete(expense)
        save()
    }

    /// Plain copies of the expenses, oldest first; only one month's if `period` is given.
    func records(in period: MonthPeriod? = nil) -> [ExpenseRecord] {
        var descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date)])
        if let period {
            let start = period.start(in: calendar)
            let end = period.end(in: calendar)
            descriptor.predicate = #Predicate<Expense> { $0.date >= start && $0.date < end }
        }
        return ((try? context.fetch(descriptor)) ?? []).map(\.record)
    }

    func limits() -> [ExpenseCategory: Money] {
        let budgets = (try? context.fetch(FetchDescriptor<CategoryBudget>())) ?? []
        return Dictionary(budgets.map { ($0.category, $0.money) }, uniquingKeysWith: { first, _ in first })
    }

    /// Sets a category's monthly budget. Nil or zero removes it.
    func setLimit(_ amount: Money?, for category: ExpenseCategory) {
        let raw = category.rawValue
        let descriptor = FetchDescriptor<CategoryBudget>(predicate: #Predicate<CategoryBudget> { $0.categoryRaw == raw })
        let existing = (try? context.fetch(descriptor))?.first
        if let amount, amount > .zero {
            if let existing {
                existing.limitCents = amount.cents
            } else {
                context.insert(CategoryBudget(category: category, limit: amount))
            }
        } else if let existing {
            context.delete(existing)
        }
        save()
    }

    func deleteAll() {
        for expense in (try? context.fetch(FetchDescriptor<Expense>())) ?? [] { context.delete(expense) }
        for budget in (try? context.fetch(FetchDescriptor<CategoryBudget>())) ?? [] { context.delete(budget) }
        save()
    }

    func csv() -> String {
        CSVExporter.csv(records(), calendar: calendar)
    }

    func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("Save failed: \(error)")
        }
        publishWidgetSnapshot()
    }

    /// Writes this month's summary where the widget can read it, then asks iOS to redraw widgets.
    func publishWidgetSnapshot(now: Date = AppClock.now) {
        let snapshot = WidgetSnapshot.make(records: records(), limits: limits(), now: now, calendar: calendar)
        if let shared = UserDefaults(suiteName: WidgetSnapshot.appGroup) {
            snapshot.save(to: shared)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

import BudgetKit
import Foundation
import SwiftData

/// Realistic demo data for UI tests, screenshots and previews.
@MainActor
enum SampleData {
    private struct Item {
        let day: Int
        let cents: Int64
        let category: ExpenseCategory
        let note: String
    }

    private static let thisMonth: [Item] = [
        Item(day: 1, cents: 145_000, category: .housing, note: "Rent"),
        Item(day: 2, cents: 6_420, category: .groceries, note: "No Frills"),
        Item(day: 3, cents: 1_250, category: .dining, note: "Tim Hortons"),
        Item(day: 3, cents: 15_600, category: .transport, note: "PRESTO monthly pass"),
        Item(day: 5, cents: 8_975, category: .bills, note: "Phone bill"),
        Item(day: 6, cents: 3_499, category: .entertainment, note: "Cineplex"),
        Item(day: 8, cents: 11_230, category: .groceries, note: "Weekly shop"),
        Item(day: 9, cents: 2_680, category: .dining, note: "Lunch with Sam"),
        Item(day: 10, cents: 4_599, category: .shopping, note: "Winter gloves"),
        Item(day: 11, cents: 2_150, category: .health, note: "Shoppers Drug Mart"),
        Item(day: 12, cents: 9_870, category: .groceries, note: "Costco run"),
        Item(day: 13, cents: 1_895, category: .dining, note: "Pizza night"),
    ]

    private static let lastMonth: [Item] = [
        Item(day: 1, cents: 145_000, category: .housing, note: "Rent"),
        Item(day: 4, cents: 24_310, category: .groceries, note: "Groceries"),
        Item(day: 15, cents: 15_600, category: .transport, note: "PRESTO monthly pass"),
        Item(day: 20, cents: 6_740, category: .dining, note: "Birthday dinner"),
    ]

    static let budgets: [ExpenseCategory: Int64] = [
        .housing: 150_000, .groceries: 40_000, .dining: 7_000, .transport: 16_000,
        .entertainment: 6_000, .shopping: 10_000,
    ]

    static func insert(into context: ModelContext, today: Date = AppClock.now, calendar: Calendar = .current) {
        let period = MonthPeriod(containing: today, calendar: calendar)
        let todayNumber = calendar.component(.day, from: today)
        add(thisMonth.filter { $0.day <= todayNumber }, in: period, to: context, calendar: calendar)
        add(lastMonth, in: period.previous, to: context, calendar: calendar)
        for (category, cents) in budgets {
            context.insert(CategoryBudget(category: category, limit: Money(cents: cents)))
        }
        try? context.save()
    }

    private static func add(_ items: [Item], in period: MonthPeriod, to context: ModelContext, calendar: Calendar) {
        let start = period.start(in: calendar)
        for item in items {
            let day = calendar.date(byAdding: .day, value: item.day - 1, to: start) ?? start
            let date = calendar.date(byAdding: .hour, value: 12, to: day) ?? day
            context.insert(Expense(amount: Money(cents: item.cents), category: item.category, date: date, note: item.note))
        }
    }
}

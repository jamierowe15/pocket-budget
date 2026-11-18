import Foundation

/// The small summary the Home Screen widget shows. The app writes it to a shared App Group
/// after every change; the widget (a separate process) reads it. It never opens the database.
public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public static let appGroup = "group.com.jamierowe.pocketbudget"
    public static let storageKey = "widgetSnapshot"

    public let period: MonthPeriod
    public let spent: Money
    public let budget: Money?
    public let topCategory: ExpenseCategory?
    public let updatedAt: Date

    public init(period: MonthPeriod, spent: Money, budget: Money?, topCategory: ExpenseCategory?, updatedAt: Date) {
        self.period = period
        self.spent = spent
        self.budget = budget
        self.topCategory = topCategory
        self.updatedAt = updatedAt
    }

    /// Builds this month's summary. The overall budget is the sum of the category budgets.
    public static func make(records: [ExpenseRecord], limits: [ExpenseCategory: Money], now: Date,
                            calendar: Calendar = .current) -> WidgetSnapshot {
        let period = MonthPeriod(containing: now, calendar: calendar)
        let budget = limits.values.reduce(Money.zero, +)
        return WidgetSnapshot(
            period: period,
            spent: BudgetCalculator.total(records, in: period, calendar: calendar),
            budget: budget > .zero ? budget : nil,
            topCategory: BudgetCalculator.totalsByCategory(records, in: period, calendar: calendar).first?.category,
            updatedAt: now
        )
    }

    public var status: BudgetStatus { BudgetCalculator.status(spent: spent, limit: budget) }

    public func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    public static func load(from defaults: UserDefaults?) -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// What the widget gallery shows before the app has run.
    public static let sample = WidgetSnapshot(period: MonthPeriod(year: 2026, month: 11), spent: Money(cents: 124_350),
                                              budget: Money(cents: 200_000), topCategory: .groceries,
                                              updatedAt: Date(timeIntervalSince1970: 1_794_600_000))
}

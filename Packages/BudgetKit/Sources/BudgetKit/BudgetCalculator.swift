import Foundation

public struct CategoryTotal: Hashable, Sendable, Identifiable {
    public let category: ExpenseCategory
    public let amount: Money
    public var id: ExpenseCategory { category }
}

/// Running total at the end of each day, for the "spending so far" line chart.
public struct DailyTotal: Hashable, Sendable, Identifiable {
    public let day: Int
    public let total: Money
    public var id: Int { day }
}

public enum BudgetLevel: String, Sendable {
    /// No budget set for this category.
    case none
    case onTrack
    /// 80% or more used.
    case warning
    case over
}

public struct BudgetStatus: Hashable, Sendable {
    public let spent: Money
    public let limit: Money?
    public let level: BudgetLevel

    /// Money left (negative when over budget). Nil when there's no budget.
    public var remaining: Money? { limit.map { $0 - spent } }

    /// 0.0 to 1.0+ of the budget used. Nil when there's no budget.
    public var fractionUsed: Double? {
        guard let limit, limit.cents > 0 else { return nil }
        return Double(spent.cents) / Double(limit.cents)
    }
}

/// The budgeting rules, all pure functions: same inputs, same answer, easy to test.
public enum BudgetCalculator {
    public static let warningThreshold = 0.8

    public static func total(_ records: [ExpenseRecord], in period: MonthPeriod, calendar: Calendar = .current) -> Money {
        records.filter { period.contains($0.date, calendar: calendar) }.reduce(.zero) { $0 + $1.amount }
    }

    /// Spending per category, biggest first, leaving out categories with nothing spent.
    public static func totalsByCategory(_ records: [ExpenseRecord], in period: MonthPeriod,
                                        calendar: Calendar = .current) -> [CategoryTotal] {
        var sums: [ExpenseCategory: Money] = [:]
        for record in records where period.contains(record.date, calendar: calendar) {
            sums[record.category, default: .zero] = sums[record.category, default: .zero] + record.amount
        }
        return sums.map { CategoryTotal(category: $0.key, amount: $0.value) }
            .filter { $0.amount > .zero }
            .sorted { $0.amount == $1.amount ? $0.category.rawValue < $1.category.rawValue : $0.amount > $1.amount }
    }

    public static func status(spent: Money, limit: Money?) -> BudgetStatus {
        guard let limit, limit.cents > 0 else { return BudgetStatus(spent: spent, limit: nil, level: .none) }
        let level: BudgetLevel
        if spent > limit {
            level = .over
        } else if Double(spent.cents) >= Double(limit.cents) * warningThreshold {
            level = .warning
        } else {
            level = .onTrack
        }
        return BudgetStatus(spent: spent, limit: limit, level: level)
    }

    /// How many days of the month have happened by `today` (all of them for a past month).
    public static func daysElapsed(in period: MonthPeriod, today: Date, calendar: Calendar = .current) -> Int {
        let current = MonthPeriod(containing: today, calendar: calendar)
        if current < period { return 0 }
        if period < current { return period.dayCount(in: calendar) }
        return calendar.component(.day, from: today)
    }

    public static func dailyAverage(spent: Money, period: MonthPeriod, today: Date, calendar: Calendar = .current) -> Money {
        let days = daysElapsed(in: period, today: today, calendar: calendar)
        guard days > 0 else { return .zero }
        return Money(cents: divideRounded(spent.cents, by: Int64(days)))
    }

    /// "At this pace you'll spend $X this month." Only for the current month.
    public static func projectedTotal(spent: Money, period: MonthPeriod, today: Date,
                                      calendar: Calendar = .current) -> Money? {
        guard MonthPeriod(containing: today, calendar: calendar) == period else { return nil }
        let days = Int64(daysElapsed(in: period, today: today, calendar: calendar))
        guard days > 0 else { return nil }
        return Money(cents: divideRounded(spent.cents * Int64(period.dayCount(in: calendar)), by: days))
    }

    /// The running total on each day from the 1st up to `lastDay`.
    public static func cumulativeByDay(_ records: [ExpenseRecord], in period: MonthPeriod, through lastDay: Int,
                                       calendar: Calendar = .current) -> [DailyTotal] {
        guard lastDay > 0 else { return [] }
        var perDay = [Int64](repeating: 0, count: lastDay + 1)
        for record in records where period.contains(record.date, calendar: calendar) {
            let day = calendar.component(.day, from: record.date)
            if day <= lastDay { perDay[day] += record.amount.cents }
        }
        var running: Int64 = 0
        return (1...lastDay).map { day in
            running += perDay[day]
            return DailyTotal(day: day, total: Money(cents: running))
        }
    }

    /// Integer division that rounds half away from zero: 7 / 2 = 4, not 3.
    static func divideRounded(_ value: Int64, by divisor: Int64) -> Int64 {
        guard divisor != 0 else { return 0 }
        let quotient = value / divisor
        let remainder = value % divisor
        return abs(remainder) * 2 >= abs(divisor) ? quotient + (value < 0 ? -1 : 1) : quotient
    }
}

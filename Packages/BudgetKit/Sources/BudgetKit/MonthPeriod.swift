import Foundation

/// A calendar month, like November 2026. Budgets reset every month.
/// Every function takes a Calendar, so tests can use a fixed one and get the same answer
/// in every time zone.
public struct MonthPeriod: Hashable, Sendable, Codable, Comparable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        // Normalise "month 13 of 2026" to "month 1 of 2027" and "month 0" to December.
        let zeroBased = year * 12 + (month - 1)
        self.year = Int((Double(zeroBased) / 12).rounded(.down))
        self.month = zeroBased - self.year * 12 + 1
    }

    public init(containing date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month], from: date)
        self.init(year: parts.year ?? 2000, month: parts.month ?? 1)
    }

    public var next: MonthPeriod { MonthPeriod(year: year, month: month + 1) }
    public var previous: MonthPeriod { MonthPeriod(year: year, month: month - 1) }

    /// Midnight on the 1st.
    public func start(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date.distantPast
    }

    /// Midnight on the 1st of the next month (the first moment *not* in this month).
    public func end(in calendar: Calendar = .current) -> Date {
        next.start(in: calendar)
    }

    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        date >= start(in: calendar) && date < end(in: calendar)
    }

    public func dayCount(in calendar: Calendar = .current) -> Int {
        calendar.range(of: .day, in: .month, for: start(in: calendar))?.count ?? 30
    }

    public static func < (lhs: MonthPeriod, rhs: MonthPeriod) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

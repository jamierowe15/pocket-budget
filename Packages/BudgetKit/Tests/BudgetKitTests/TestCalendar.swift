import Foundation
@testable import BudgetKit

/// A fixed Gregorian calendar in UTC, so dates mean the same thing on every machine.
enum TestCalendar {
    static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date.distantPast
    }

    static func record(_ cents: Int64, _ category: ExpenseCategory, _ day: Int, month: Int = 11, note: String = "") -> ExpenseRecord {
        ExpenseRecord(amount: Money(cents: cents), category: category, date: date(2026, month, day), note: note)
    }
}

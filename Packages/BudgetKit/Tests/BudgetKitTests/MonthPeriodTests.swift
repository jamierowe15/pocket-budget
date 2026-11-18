import Foundation
import Testing
@testable import BudgetKit

@Suite("Months")
struct MonthPeriodTests {
    let calendar = TestCalendar.utc

    @Test func nextAndPreviousCrossYearEnds() {
        #expect(MonthPeriod(year: 2026, month: 12).next == MonthPeriod(year: 2027, month: 1))
        #expect(MonthPeriod(year: 2027, month: 1).previous == MonthPeriod(year: 2026, month: 12))
        #expect(MonthPeriod(year: 2026, month: 0) == MonthPeriod(year: 2025, month: 12))
    }

    @Test("Days in month", arguments: [(2026, 2, 28), (2028, 2, 29), (2026, 11, 30), (2026, 12, 31)])
    func dayCount(year: Int, month: Int, days: Int) {
        #expect(MonthPeriod(year: year, month: month).dayCount(in: calendar) == days)
    }

    @Test func containsIsHalfOpen() {
        let november = MonthPeriod(year: 2026, month: 11)
        #expect(november.contains(TestCalendar.date(2026, 11, 1, hour: 0), calendar: calendar))
        #expect(november.contains(TestCalendar.date(2026, 11, 30, hour: 23), calendar: calendar))
        #expect(!november.contains(TestCalendar.date(2026, 12, 1, hour: 0), calendar: calendar))
        #expect(MonthPeriod(containing: TestCalendar.date(2026, 11, 13), calendar: calendar) == november)
    }

    @Test func ordersByTime() {
        #expect(MonthPeriod(year: 2026, month: 11) < MonthPeriod(year: 2026, month: 12))
        #expect(MonthPeriod(year: 2025, month: 12) < MonthPeriod(year: 2026, month: 1))
    }
}

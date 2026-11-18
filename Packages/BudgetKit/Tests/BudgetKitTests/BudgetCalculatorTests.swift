import Foundation
import Testing
@testable import BudgetKit

@Suite("Budget maths")
struct BudgetCalculatorTests {
    let calendar = TestCalendar.utc
    let november = MonthPeriod(year: 2026, month: 11)
    let records = [
        TestCalendar.record(5_420, .groceries, 2),
        TestCalendar.record(1_250, .dining, 2),
        TestCalendar.record(8_000, .groceries, 9),
        TestCalendar.record(3_300, .transport, 13),
        TestCalendar.record(99_999, .shopping, 28, month: 10), // October: must be ignored
    ]

    @Test func totalOnlyCountsThisMonth() {
        #expect(BudgetCalculator.total(records, in: november, calendar: calendar) == Money(cents: 17_970))
    }

    @Test func totalsByCategoryBiggestFirst() {
        let totals = BudgetCalculator.totalsByCategory(records, in: november, calendar: calendar)
        #expect(totals.map(\.category) == [.groceries, .transport, .dining])
        #expect(totals.first?.amount == Money(cents: 13_420))
    }

    @Test("Budget levels", arguments: [
        (Int64(5_000), BudgetLevel.onTrack), (8_000, .warning), (10_000, .warning), (10_001, .over),
    ])
    func levels(spentCents: Int64, expected: BudgetLevel) {
        let status = BudgetCalculator.status(spent: Money(cents: spentCents), limit: Money(cents: 10_000))
        #expect(status.level == expected)
    }

    @Test func remainingAndFraction() {
        let status = BudgetCalculator.status(spent: Money(cents: 12_000), limit: Money(cents: 10_000))
        #expect(status.remaining == Money(cents: -2_000))
        #expect(status.fractionUsed == 1.2)
    }

    @Test func noBudgetMeansNoLevel() {
        let status = BudgetCalculator.status(spent: Money(cents: 500), limit: nil)
        #expect(status.level == .none)
        #expect(status.remaining == nil)
        #expect(status.fractionUsed == nil)
        #expect(BudgetCalculator.status(spent: .zero, limit: .zero).level == .none)
    }

    @Test func daysElapsedForPastCurrentAndFutureMonths() {
        let today = TestCalendar.date(2026, 11, 13)
        #expect(BudgetCalculator.daysElapsed(in: november, today: today, calendar: calendar) == 13)
        #expect(BudgetCalculator.daysElapsed(in: november.previous, today: today, calendar: calendar) == 31)
        #expect(BudgetCalculator.daysElapsed(in: november.next, today: today, calendar: calendar) == 0)
    }

    @Test func averageAndProjection() {
        let today = TestCalendar.date(2026, 11, 13)
        let spent = BudgetCalculator.total(records, in: november, calendar: calendar)
        // 179.70 over 13 days = 13.82 a day; 13.8231 x 30 days = 414.69
        #expect(BudgetCalculator.dailyAverage(spent: spent, period: november, today: today, calendar: calendar) == Money(cents: 1_382))
        #expect(BudgetCalculator.projectedTotal(spent: spent, period: november, today: today, calendar: calendar) == Money(cents: 41_469))
        #expect(BudgetCalculator.projectedTotal(spent: spent, period: november.previous, today: today, calendar: calendar) == nil)
        #expect(BudgetCalculator.dailyAverage(spent: spent, period: november.next, today: today, calendar: calendar) == .zero)
    }

    @Test func cumulativeRunsDayByDay() {
        let line = BudgetCalculator.cumulativeByDay(records, in: november, through: 13, calendar: calendar)
        #expect(line.count == 13)
        #expect(line[0].total == .zero)                    // 1st: nothing yet
        #expect(line[1].total == Money(cents: 6_670))      // 2nd: groceries + dining
        #expect(line[12].total == Money(cents: 17_970))    // 13th: everything
        #expect(BudgetCalculator.cumulativeByDay(records, in: november, through: 0, calendar: calendar).isEmpty)
    }

    @Test("Rounded division", arguments: [(Int64(7), Int64(2), Int64(4)), (6, 4, 2), (-7, 2, -4), (10, 0, 0)])
    func divideRounded(value: Int64, divisor: Int64, expected: Int64) {
        #expect(BudgetCalculator.divideRounded(value, by: divisor) == expected)
    }
}

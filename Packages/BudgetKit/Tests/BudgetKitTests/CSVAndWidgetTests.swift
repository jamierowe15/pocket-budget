import Foundation
import Testing
@testable import BudgetKit

@Suite("CSV export")
struct CSVTests {
    @Test func writesHeaderAndRowsInDateOrder() {
        let csv = CSVExporter.csv([
            TestCalendar.record(450, .dining, 9, note: "Coffee"),
            TestCalendar.record(5_420, .groceries, 2),
        ], calendar: TestCalendar.utc)
        #expect(csv == "date,category,amount,note\n2026-11-02,groceries,54.20,\n2026-11-09,dining,4.50,Coffee\n")
    }

    @Test("Escapes awkward notes", arguments: [
        ("plain", "plain"),
        ("Coffee, muffin", "\"Coffee, muffin\""),
        ("The \"good\" one", "\"The \"\"good\"\" one\""),
        ("two\nlines", "\"two\nlines\""),
    ])
    func escapes(note: String, expected: String) {
        #expect(CSVExporter.escape(note) == expected)
    }
}

@Suite("Widget snapshot")
struct WidgetSnapshotTests {
    @Test func summarisesThisMonth() {
        let now = TestCalendar.date(2026, 11, 13)
        let snapshot = WidgetSnapshot.make(
            records: [TestCalendar.record(5_000, .groceries, 2), TestCalendar.record(2_000, .dining, 3),
                      TestCalendar.record(9_999, .health, 30, month: 10)],
            limits: [.groceries: Money(cents: 40_000), .dining: Money(cents: 10_000)],
            now: now, calendar: TestCalendar.utc)
        #expect(snapshot.period == MonthPeriod(year: 2026, month: 11))
        #expect(snapshot.spent == Money(cents: 7_000))
        #expect(snapshot.budget == Money(cents: 50_000))
        #expect(snapshot.topCategory == .groceries)
        #expect(snapshot.status.level == .onTrack)
    }

    @Test func noLimitsMeansNoBudget() {
        let snapshot = WidgetSnapshot.make(records: [], limits: [:], now: TestCalendar.date(2026, 11, 13), calendar: TestCalendar.utc)
        #expect(snapshot.budget == nil)
        #expect(snapshot.topCategory == nil)
    }

    @Test func savesAndLoadsThroughUserDefaults() throws {
        let defaults = try #require(UserDefaults(suiteName: "test-\(UUID().uuidString)"))
        WidgetSnapshot.sample.save(to: defaults)
        #expect(WidgetSnapshot.load(from: defaults) == WidgetSnapshot.sample)
        #expect(WidgetSnapshot.load(from: nil) == nil)
    }

    @Test func unknownStoredCategoryBecomesOther() {
        #expect(ExpenseCategory(storedValue: "groceries") == .groceries)
        #expect(ExpenseCategory(storedValue: "crypto") == .other)
        #expect(ExpenseCategory.allCases.allSatisfy { !$0.displayName.isEmpty && !$0.symbolName.isEmpty })
    }
}

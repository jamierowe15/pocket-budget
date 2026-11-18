import Foundation
import SwiftData
import Testing
@testable import PocketBudget

/// Each test gets a fresh in-memory database, so tests never affect each other.
@MainActor
struct RepositoryTests {
    let container: ModelContainer
    let repository: ExpenseRepository
    let november = MonthPeriod(year: 2026, month: 11)

    init() {
        container = Persistence.makeContainer(inMemory: true)
        repository = ExpenseRepository(context: container.mainContext)
    }

    private func day(_ number: Int, month: Int = 11) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: month, day: number, hour: 12)) ?? Date()
    }

    @Test func addedExpensesAreSavedAndTotalled() {
        repository.add(amount: Money(cents: 1_250), category: .dining, date: day(3), note: "  Tim Hortons  ")
        repository.add(amount: Money(cents: 6_420), category: .groceries, date: day(2), note: "")
        repository.add(amount: Money(cents: 9_999), category: .shopping, date: day(30, month: 10), note: "")
        let inNovember = repository.records(in: november)
        #expect(inNovember.count == 2)
        #expect(inNovember.first?.category == .groceries, "Oldest first")
        #expect(inNovember.last?.note == "Tim Hortons", "Notes are trimmed")
        #expect(repository.records().count == 3)
    }

    @Test func updateAndDelete() throws {
        let expense = repository.add(amount: Money(cents: 500), category: .other, date: day(5), note: "x")
        repository.update(expense, amount: Money(cents: 750), category: .health, date: day(6), note: "Pharmacy")
        let record = try #require(repository.records().first)
        #expect(record.amount == Money(cents: 750))
        #expect(record.category == .health)
        repository.delete(expense)
        #expect(repository.records().isEmpty)
    }

    @Test func limitsCanBeSetChangedAndRemoved() {
        repository.setLimit(Money(cents: 40_000), for: .groceries)
        #expect(repository.limits()[.groceries] == Money(cents: 40_000))
        repository.setLimit(Money(cents: 45_000), for: .groceries)
        #expect(repository.limits() == [.groceries: Money(cents: 45_000)], "Updated, not duplicated")
        repository.setLimit(nil, for: .groceries)
        #expect(repository.limits().isEmpty)
    }

    @Test func deleteAllEmptiesEverything() {
        repository.add(amount: Money(cents: 100), category: .other, date: day(1), note: "")
        repository.setLimit(Money(cents: 100), for: .other)
        repository.deleteAll()
        #expect(repository.records().isEmpty)
        #expect(repository.limits().isEmpty)
    }

    @Test func csvContainsEveryExpense() {
        repository.add(amount: Money(cents: 450), category: .dining, date: day(9), note: "Coffee, muffin")
        let csv = repository.csv()
        #expect(csv.hasPrefix(CSVExporter.header))
        #expect(csv.contains("\"Coffee, muffin\""))
    }

    @Test func sampleDataFillsTheMonthAndBudgets() {
        let today = day(13)
        SampleData.insert(into: container.mainContext, today: today)
        #expect(repository.records(in: november).count == 12)
        #expect(repository.limits().count == SampleData.budgets.count)
    }
}

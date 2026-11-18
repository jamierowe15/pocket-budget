import Foundation
import Testing
@testable import PocketBudget

@MainActor
struct ExpenseFormModelTests {
    let english = Locale(identifier: "en_CA")
    let today = Date(timeIntervalSince1970: 1_794_600_000)

    @Test("Valid amounts", arguments: ["12.50", "$1,000", "0.01", "100000"])
    func acceptsValidAmounts(text: String) {
        let model = ExpenseFormModel(expense: nil, today: today, locale: english)
        model.amountText = text
        #expect(model.isValid)
        #expect(model.validationMessage == nil)
    }

    @Test("Invalid amounts explain themselves", arguments: ["abc", "0", "100000.01", "1.234"])
    func rejectsInvalidAmounts(text: String) {
        let model = ExpenseFormModel(expense: nil, today: today, locale: english)
        model.amountText = text
        #expect(!model.isValid)
        #expect(model.validationMessage != nil)
    }

    @Test func emptyFieldShowsNoErrorYet() {
        let model = ExpenseFormModel(expense: nil, today: today, locale: english)
        #expect(!model.isValid)
        #expect(model.validationMessage == nil)
        #expect(model.title == "New expense")
    }

    @Test func frenchUsesACommaWhenEditing() {
        let expense = Expense(amount: Money(cents: 1_230), category: .dining, date: today, note: "Café")
        let model = ExpenseFormModel(expense: expense, today: today, locale: Locale(identifier: "fr_CA"))
        #expect(model.amountText == "12,30")
        #expect(model.money == Money(cents: 1_230))
        #expect(model.isEditing)
        #expect(model.title == "Edit expense")
    }

    @Test func saveAddsThenUpdates() throws {
        let container = Persistence.makeContainer(inMemory: true)
        let repository = ExpenseRepository(context: container.mainContext)
        let model = ExpenseFormModel(expense: nil, today: today, locale: english)
        model.amountText = "8.75"
        model.category = .transport
        #expect(model.save(using: repository))
        let saved = try #require(repository.records().first)
        #expect(saved.amount == Money(cents: 875))

        let invalid = ExpenseFormModel(expense: nil, today: today, locale: english)
        invalid.amountText = "nope"
        #expect(!invalid.save(using: repository))
        #expect(repository.records().count == 1)
    }
}

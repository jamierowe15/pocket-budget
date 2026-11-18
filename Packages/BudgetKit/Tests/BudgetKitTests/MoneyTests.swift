import Foundation
import Testing
@testable import BudgetKit

@Suite("Money")
struct MoneyTests {
    // One test, many inputs: Swift Testing runs it once per argument and reports each.
    @Test("Parses what people type", arguments: [
        ("42", Int64(4200)), ("42.5", 4250), ("$1,234.56", 123_456), (".99", 99), ("0.05", 5), (" 7 ", 700),
    ])
    func parsesTypedAmounts(text: String, cents: Int64) {
        #expect(Money(parsing: text)?.cents == cents)
    }

    @Test("Rejects nonsense", arguments: ["", ".", "abc", "1.234", "1.2.3", "-5", "12a"])
    func rejectsNonsense(text: String) {
        #expect(Money(parsing: text) == nil)
    }

    @Test func readsAFrenchDecimalComma() {
        #expect(Money(parsing: "42,50", decimalSeparator: ",")?.cents == 4250)
        #expect(Money(parsing: "1 234,5", decimalSeparator: ",")?.cents == 123_450)
    }

    @Test func plainStringPadsCents() {
        #expect(Money(cents: 1230).plainString == "12.30")
        #expect(Money(cents: 5).plainString == "0.05")
        #expect(Money(cents: -250).plainString == "-2.50")
    }

    @Test func arithmeticIsExact() {
        // The Double version of this is famously wrong; whole cents are always right.
        #expect(Money(cents: 10) + Money(cents: 20) == Money(cents: 30))
        #expect(Money(cents: 100) - Money(cents: 250) == Money(cents: -150))
        #expect([Money(cents: 1), Money(cents: 2)].reduce(.zero, +) == Money(cents: 3))
    }

    @Test func fromDollarsRoundsToTheCent() {
        #expect(Money(dollars: 12.346)?.cents == 1235)
        #expect(Money(dollars: 0.1 + 0.2)?.cents == 30)
        #expect(Money(dollars: .infinity) == nil)
    }

    @Test func formattedIsNotEmpty() {
        #expect(!Money(cents: 123_450).formatted(locale: Locale(identifier: "en_CA")).isEmpty)
    }
}

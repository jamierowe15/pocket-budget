import XCTest

final class BudgetFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAddAnExpense() {
        let app = launchApp()
        let add = app.buttons["expenses.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        demoPause()
        add.tap()

        let amount = app.textFields["form.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("12.34")
        XCTAssertTrue(app.buttons["form.save"].isEnabled)
        demoPause()

        app.buttons["form.category"].tap()
        app.buttons["Eating out"].tap()
        let note = app.textFields["form.note"]
        note.tap()
        note.typeText("UI test coffee")
        demoPause()
        app.buttons["form.save"].tap()

        XCTAssertTrue(row(app, containing: "UI test coffee").waitForExistence(timeout: 5))
        demoPause(2)
    }

    func testSaveIsDisabledForNonsense() {
        let app = launchApp()
        app.buttons["expenses.add"].tap()
        let amount = app.textFields["form.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("0")
        XCTAssertFalse(app.buttons["form.save"].isEnabled)
    }

    func testEditThenDeleteAnExpense() {
        let app = launchApp()
        let pizza = row(app, containing: "Pizza night")
        XCTAssertTrue(pizza.waitForExistence(timeout: 10))
        pizza.tap()

        let amount = app.textFields["form.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.replaceText("20")
        app.buttons["form.save"].tap()
        XCTAssertTrue(row(app, containing: "$20.00").waitForExistence(timeout: 5))

        let edited = row(app, containing: "Pizza night")
        edited.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(row(app, containing: "Pizza night").waitForExistence(timeout: 2))
    }

    func testSetABudget() {
        let app = launchApp()
        openTab(app, "Budgets")
        let health = app.buttons["budget.row.health"]
        XCTAssertTrue(scrollTo(app, health))
        XCTAssertTrue((health.value as? String ?? "").contains("No budget"))
        health.tap()

        let limit = app.textFields["budget.limit"]
        XCTAssertTrue(limit.waitForExistence(timeout: 5))
        limit.tap()
        limit.typeText("50")
        app.buttons["budget.save"].tap()

        XCTAssertTrue(scrollTo(app, health))
        XCTAssertTrue((health.value as? String ?? "").contains("$50.00"), health.value as? String ?? "")
    }

    func testInsightsDrawCharts() {
        let app = launchApp()
        openTab(app, "Insights")
        XCTAssertTrue(app.otherElements["insights.byCategory"].waitForExistence(timeout: 10)
                      || app.descendants(matching: .any)["insights.byCategory"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["insights.projection"].exists)
    }

    func testPreviousMonthShowsOctober() {
        let app = launchApp()
        let previous = app.buttons["month.previous"]
        XCTAssertTrue(previous.waitForExistence(timeout: 10))
        previous.tap()
        let title = app.staticTexts["month.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "October 2026")
        XCTAssertTrue(row(app, containing: "Birthday dinner").exists)
    }
}

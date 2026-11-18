import XCTest

/// Captures every screen. scripts/ci/evidence.sh runs it in light, dark, the largest text
/// size and on iPad (TEST_RUNNER_SHOTS_TAG names each set). Skipped in normal CI.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureEveryScreen() {
        let app = launchApp()
        XCTAssertTrue(app.buttons["expenses.add"].waitForExistence(timeout: 10))
        sleep(1)
        capture("01-expenses")

        app.buttons["expenses.add"].tap()
        let amount = app.textFields["form.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("42.50")
        capture("02-add")
        app.buttons["Cancel"].tap()

        openTab(app, "Budgets")
        sleep(1)
        capture("03-budgets")
        openTab(app, "Insights")
        sleep(1)
        capture("04-insights")
        openTab(app, "Settings")
        sleep(1)
        capture("05-settings")
    }

    private func capture(_ name: String) {
        let tag = ProcessInfo.processInfo.environment["SHOTS_TAG"] ?? "shot"
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(tag)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let folder = evidenceFolder() {
            try? screenshot.pngRepresentation.write(to: folder.appendingPathComponent("\(tag)-\(name).png"))
        }
    }
}

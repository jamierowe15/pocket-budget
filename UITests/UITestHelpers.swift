import XCTest

/// Launches the app with a fresh in-memory database full of sample data, on a fixed date.
func launchApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-uiTesting", "-fixedToday", "2026-11-13"]
    app.launch()
    return app
}

/// Taps a tab whether iOS draws a bottom tab bar (iPhone) or a top tab strip (iPad).
func openTab(_ app: XCUIApplication, _ name: String) {
    let tab = app.tabBars.buttons[name]
    if tab.exists {
        tab.tap()
    } else {
        app.buttons[name].firstMatch.tap()
    }
}

/// The first button whose VoiceOver label contains `text` (expense rows are buttons).
func row(_ app: XCUIApplication, containing text: String) -> XCUIElement {
    app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
}

/// Swipes up until the element is on screen.
@discardableResult
func scrollTo(_ app: XCUIApplication, _ element: XCUIElement, maxSwipes: Int = 6) -> Bool {
    var swipes = 0
    while !(element.exists && element.isHittable) && swipes < maxSwipes {
        app.swipeUp()
        swipes += 1
    }
    return element.exists
}

extension XCUIElement {
    /// Deletes what's in a text field and types new text.
    func replaceText(_ text: String) {
        coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let current = (value as? String) ?? ""
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
        typeText(text)
    }
}

/// Slows tests down only while a demo is being recorded (TEST_RUNNER_DEMO_PACE=1).
func demoPause(_ seconds: UInt32 = 1) {
    if ProcessInfo.processInfo.environment["DEMO_PACE"] != nil { sleep(seconds) }
}

/// Where tests drop screenshots and reports on the Mac running the Simulator.
func evidenceFolder() -> URL? {
    guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return nil }
    let folder = URL(fileURLWithPath: home).appendingPathComponent("lab-shots")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}

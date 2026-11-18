import Foundation
import SwiftData

/// Creates the database. The app, the Siri intent and the tests all get theirs from here.
@MainActor
enum Persistence {
    static let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    /// The app's one container: on disk normally, in memory with sample data for UI tests.
    static let shared: ModelContainer = makeContainer(
        inMemory: isUITesting,
        sampleData: isUITesting || ProcessInfo.processInfo.arguments.contains("-sampleData")
    )

    static func makeContainer(inMemory: Bool, sampleData: Bool = false) -> ModelContainer {
        let schema = Schema([Expense.self, CategoryBudget.self])
        // A unique name keeps every in-memory container (one per test) separate.
        let configuration = ModelConfiguration(inMemory ? UUID().uuidString : nil, schema: schema,
                                               isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if sampleData {
                SampleData.insert(into: container.mainContext)
            }
            return container
        } catch {
            // Without a database the app can't do anything useful; crash loudly in development.
            fatalError("Couldn't open the expenses database: \(error)")
        }
    }
}

/// "Now" for the whole app. UI tests pass `-fixedToday 2026-11-13` so screenshots are the
/// same every time; otherwise it's the real date.
enum AppClock {
    static let fixedToday: Date? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-fixedToday"), index + 1 < arguments.count else { return nil }
        let parts = arguments[index + 1].split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }()

    static var now: Date { fixedToday ?? Date() }
}

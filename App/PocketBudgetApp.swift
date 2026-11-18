import SwiftData
import SwiftUI

/// The app's entry point. One window, one shared SwiftData container for every screen.
@main
struct PocketBudgetApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    // Keep the widget's summary fresh whenever the app opens.
                    ExpenseRepository(context: Persistence.shared.mainContext).publishWidgetSnapshot()
                }
        }
        .modelContainer(Persistence.shared)
    }
}

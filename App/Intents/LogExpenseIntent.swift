import AppIntents
import BudgetKit
import Foundation

/// "Hey Siri, log an expense in Pocket Budget." App Intents describe an action the system can
/// run without opening the app: Siri, Spotlight, the Shortcuts app and the Action button.
struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log an expense"
    static var description = IntentDescription("Adds an expense to Pocket Budget.")

    @Parameter(title: "Amount", description: "How much you spent, in Canadian dollars")
    var amount: Double

    @Parameter(title: "Category", default: .other)
    var category: CategoryOption

    @Parameter(title: "Note", default: "")
    var note: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$category)") {
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let money = Money(dollars: amount), money > .zero, money <= ExpenseFormModel.maximum else {
            throw $amount.needsValueError("How much did you spend?")
        }
        let repository = ExpenseRepository(context: Persistence.shared.mainContext)
        repository.add(amount: money, category: category.category, date: AppClock.now, note: note)
        return .result(dialog: "Logged \(money.formatted()) for \(category.category.displayName).")
    }
}

/// The categories as Siri understands them. AppEnum needs fixed, literal names.
enum CategoryOption: String, AppEnum {
    case groceries, dining, transport, housing, bills, shopping, entertainment, health, other

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"

    static var caseDisplayRepresentations: [CategoryOption: DisplayRepresentation] = [
        .groceries: "Groceries",
        .dining: "Eating out",
        .transport: "Transport",
        .housing: "Housing",
        .bills: "Bills",
        .shopping: "Shopping",
        .entertainment: "Entertainment",
        .health: "Health",
        .other: "Other",
    ]

    var category: ExpenseCategory { ExpenseCategory(storedValue: rawValue) }
}

/// Phrases Siri recognises with no setup. Each must contain the app's name.
struct PocketBudgetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Add spending to \(.applicationName)",
            ],
            shortTitle: "Log expense",
            systemImageName: "plus.circle"
        )
    }
}

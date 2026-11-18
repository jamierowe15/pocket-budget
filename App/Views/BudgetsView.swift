import BudgetKit
import SwiftData
import SwiftUI

/// The Budgets tab: how much of each monthly budget is used.
struct BudgetsView: View {
    @State private var period = MonthPeriod(containing: AppClock.now)

    var body: some View {
        NavigationStack {
            BudgetList(period: $period)
                .navigationTitle("Budgets")
        }
    }
}

private struct BudgetList: View {
    @Binding var period: MonthPeriod
    @Query private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]
    @State private var editing: ExpenseCategory?

    init(period: Binding<MonthPeriod>) {
        _period = period
        let start = period.wrappedValue.start()
        let end = period.wrappedValue.end()
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    var body: some View {
        let records = expenses.map(\.record)
        let limits = Dictionary(budgets.map { ($0.category, $0.money) }, uniquingKeysWith: { first, _ in first })
        let overallLimit = limits.values.reduce(Money.zero, +)
        List {
            Section {
                MonthSwitcher(period: $period)
                BudgetRow(title: "All categories", symbol: "sum",
                          status: BudgetCalculator.status(spent: BudgetCalculator.total(records, in: period),
                                                          limit: overallLimit > .zero ? overallLimit : nil))
                    .accessibilityIdentifier("budget.row.overall")
            }
            Section("Categories") {
                ForEach(ExpenseCategory.allCases) { category in
                    let spent = records.filter { $0.category == category }.reduce(Money.zero) { $0 + $1.amount }
                    let status = BudgetCalculator.status(spent: spent, limit: limits[category])
                    Button {
                        editing = category
                    } label: {
                        BudgetRow(title: category.displayName, symbol: category.symbolName, status: status)
                    }
                    // The button speaks for the whole row: name, then spent / used / left.
                    .accessibilityLabel(category.displayName)
                    .accessibilityValue(BudgetRow.spokenValue(status))
                    .accessibilityHint("Sets the monthly budget")
                    .accessibilityIdentifier("budget.row.\(category.rawValue)")
                }
            }
        }
        .sheet(item: $editing) { category in
            BudgetLimitView(category: category, current: limits[category])
        }
    }
}

struct BudgetRow: View {
    let title: String
    let symbol: String
    let status: BudgetStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AdaptiveRow {
                Label(title, systemImage: symbol)
                    .foregroundStyle(.primary)
            } trailing: {
                Text(status.spent.formatted())
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
            }
            if let fraction = status.fractionUsed {
                ProgressView(value: min(fraction, 1))
                    .tint(Palette.color(for: status.level))
                Label(caption, systemImage: Palette.symbol(for: status.level))
                    .font(.footnote)
                    .foregroundStyle(Palette.color(for: status.level))
            } else {
                Text("No budget yet. Tap to set one.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Self.spokenValue(status))
    }

    private var caption: String { Self.caption(status) }

    static func caption(_ status: BudgetStatus) -> String {
        guard let limit = status.limit, let remaining = status.remaining else { return "" }
        switch status.level {
        case .over: return "Over by \((status.spent - limit).formatted())"
        case .warning: return "\(percentUsed(status))% used. \(remaining.formatted()) left of \(limit.formatted())"
        default: return "\(remaining.formatted()) left of \(limit.formatted())"
        }
    }

    static func percentUsed(_ status: BudgetStatus) -> Int {
        Int(((status.fractionUsed ?? 0) * 100).rounded())
    }

    /// What VoiceOver reads after the title: "Spent $226.80. 57% used. $173.20 left of $400.00."
    static func spokenValue(_ status: BudgetStatus) -> String {
        guard status.limit != nil else { return "Spent \(status.spent.formatted()). No budget set." }
        let warning = status.level == .over ? "Over budget. " : status.level == .warning ? "Warning. " : ""
        return "Spent \(status.spent.formatted()). \(warning)\(percentUsed(status))% used. \(caption(status))."
    }
}

/// Set or remove one category's monthly budget.
struct BudgetLimitView: View {
    let category: ExpenseCategory
    let current: Money?
    @State private var text: String
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    init(category: ExpenseCategory, current: Money?) {
        self.category = category
        self.current = current
        _text = State(initialValue: current?.plainString ?? "")
    }

    private var amount: Money? {
        Money(parsing: text, decimalSeparator: Locale.current.decimalSeparator?.first ?? ".")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Monthly budget", text: $text, prompt: Text("0.00"))
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                        .accessibilityIdentifier("budget.limit")
                } header: {
                    Label(category.displayName, systemImage: category.symbolName)
                } footer: {
                    Text("Resets on the 1st of every month. You'll see a warning at 80%.")
                }
                if current != nil {
                    Section {
                        Button("Remove budget", role: .destructive) {
                            ExpenseRepository(context: context).setLimit(nil, for: category)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Monthly budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        ExpenseRepository(context: context).setLimit(amount, for: category)
                        dismiss()
                    }
                    .disabled(amount == nil)
                    .accessibilityIdentifier("budget.save")
                }
            }
        }
    }
}

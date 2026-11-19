import BudgetKit
import SwiftData
import SwiftUI

/// The Expenses tab: this month's spending grouped by day, with + to add.
struct ExpensesView: View {
    @State private var period = MonthPeriod(containing: AppClock.now)
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            ExpenseList(period: $period)
                .navigationTitle("Expenses")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isAdding = true
                        } label: {
                            Label("Add expense", systemImage: "plus")
                        }
                        .accessibilityIdentifier("expenses.add")
                    }
                }
                .sheet(isPresented: $isAdding) {
                    ExpenseFormView(expense: nil)
                }
        }
    }
}

/// A separate view so its @Query can be rebuilt when the month changes: SwiftUI calls init
/// again with the new period, and the query filters to that month.
private struct ExpenseList: View {
    @Binding var period: MonthPeriod
    @Query private var expenses: [Expense]
    @Environment(\.modelContext) private var context
    @State private var editing: Expense?

    init(period: Binding<MonthPeriod>) {
        _period = period
        let start = period.wrappedValue.start()
        let end = period.wrappedValue.end()
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end },
                          sort: \Expense.date, order: .reverse)
    }

    private var total: Money { expenses.reduce(.zero) { $0 + $1.money } }

    private struct DayGroup: Identifiable {
        let day: Date
        let items: [Expense]
        var id: Date { day }
    }

    /// Expenses grouped by calendar day, newest day first.
    private var days: [DayGroup] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { DayGroup(day: $0, items: groups[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                MonthSwitcher(period: $period)
                LabeledContent("Spent", value: total.formatted())
                    .font(.title3.monospacedDigit())
                    .accessibilityIdentifier("expenses.total")
            }
            if expenses.isEmpty {
                ContentUnavailableView("No expenses", systemImage: "tray",
                                       description: Text("Tap + to log what you spend."))
            }
            ForEach(days) { group in
                Section(group.day.formatted(.dateTime.weekday(.wide).month(.wide).day())) {
                    ForEach(group.items) { expense in
                        Button {
                            editing = expense
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                        // .plain stops the List tinting the whole row green, which failed the contrast audit.
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .accessibilityHint("Opens the expense to edit it")
                        .swipeActions {
                            Button(role: .destructive) {
                                ExpenseRepository(context: context).delete(expense)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $editing) { expense in
            ExpenseFormView(expense: expense)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        let category = expense.category
        AdaptiveRow {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.note.isEmpty ? category.displayName : expense.note)
                        .foregroundStyle(.primary)
                    if !expense.note.isEmpty {
                        Text(category.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: category.symbolName)
                    .foregroundStyle(Palette.brand)
            }
        } trailing: {
            Text(expense.money.formatted())
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
        }
        // One VoiceOver stop per row, read as a sentence.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([expense.note, category.displayName, expense.money.formatted()]
            .filter { !$0.isEmpty }.joined(separator: ", "))
    }
}

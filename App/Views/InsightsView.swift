import BudgetKit
import Charts
import SwiftData
import SwiftUI

/// The Insights tab: where the money went (bar chart) and how the month is going (line chart).
struct InsightsView: View {
    @State private var period = MonthPeriod(containing: AppClock.now)

    var body: some View {
        NavigationStack {
            InsightsContent(period: $period)
                .navigationTitle("Insights")
        }
    }
}

private struct InsightsContent: View {
    @Binding var period: MonthPeriod
    @Query private var expenses: [Expense]
    @Query private var budgets: [CategoryBudget]

    init(period: Binding<MonthPeriod>) {
        _period = period
        let start = period.wrappedValue.start()
        let end = period.wrappedValue.end()
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    var body: some View {
        let records = expenses.map(\.record)
        let now = AppClock.now
        let spent = BudgetCalculator.total(records, in: period)
        let totals = BudgetCalculator.totalsByCategory(records, in: period)
        let budget = budgets.reduce(Money.zero) { $0 + $1.money }
        let lastDay = BudgetCalculator.daysElapsed(in: period, today: now)
        let line = BudgetCalculator.cumulativeByDay(records, in: period, through: lastDay)
        let projected = BudgetCalculator.projectedTotal(spent: spent, period: period, today: now)

        List {
            Section {
                MonthSwitcher(period: $period)
                LabeledContent("Spent", value: spent.formatted())
                LabeledContent("Daily average",
                               value: BudgetCalculator.dailyAverage(spent: spent, period: period, today: now).formatted())
                if let projected {
                    LabeledContent("At this pace", value: projected.formatted())
                        .accessibilityIdentifier("insights.projection")
                }
            }

            Section("By category") {
                if totals.isEmpty {
                    Text("Nothing spent this month yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(totals) { item in
                        BarMark(
                            x: .value("Amount", item.amount.dollars),
                            y: .value("Category", item.category.displayName)
                        )
                        .foregroundStyle(Palette.brand)
                        .annotation(position: .trailing) {
                            Text(item.amount.formatted())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(item.category.displayName)
                        .accessibilityValue(item.amount.formatted())
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(totals.count) * 40 + 16)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("insights.byCategory")
                }
            }

            if !line.isEmpty {
                Section("Spending so far") {
                    Chart {
                        ForEach(line) { point in
                            LineMark(x: .value("Day", point.day), y: .value("Total", point.total.dollars))
                                .foregroundStyle(Palette.brand)
                                .accessibilityLabel("Day \(point.day)")
                                .accessibilityValue(point.total.formatted())
                        }
                        if budget > .zero {
                            RuleMark(y: .value("Budget", budget.dollars))
                                .foregroundStyle(Palette.over)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Budget \(budget.formatted())")
                                        .font(.caption)
                                        .foregroundStyle(Palette.over)
                                }
                                .accessibilityLabel("Monthly budget")
                                .accessibilityValue(budget.formatted())
                        }
                    }
                    .frame(height: 220)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("insights.line")
                }
            }
        }
    }
}

import BudgetKit
import SwiftUI

/// "‹ November 2026 ›". Shared by the Expenses, Budgets and Insights tabs.
struct MonthSwitcher: View {
    @Binding var period: MonthPeriod

    private var isCurrentMonth: Bool { period >= MonthPeriod(containing: AppClock.now) }

    var body: some View {
        HStack {
            Button {
                period = period.previous
            } label: {
                Image(systemName: "chevron.left").padding(8)
            }
            .accessibilityLabel("Previous month")
            .accessibilityIdentifier("month.previous")
            Spacer()
            Text(period.start().formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("month.title")
            Spacer()
            Button {
                period = period.next
            } label: {
                Image(systemName: "chevron.right").padding(8)
            }
            .accessibilityLabel("Next month")
            .accessibilityIdentifier("month.next")
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0 : 1) // hidden rather than greyed out: no future months
        }
        .buttonStyle(.borderless)
    }
}

import BudgetKit
import SwiftUI
import WidgetKit

/// The Home Screen and Lock Screen widget. It runs in its own small process, so it reads
/// the summary the app saved in the shared App Group instead of opening the database.
@main
struct PocketBudgetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetWidget()
    }
}

struct BudgetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BudgetWidget", provider: BudgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly spending")
        .description("How much you've spent this month against your budget.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct BudgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

/// WidgetKit asks the provider what to show and when to ask again.
struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : current())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        // The app reloads the widget after every change; this hourly refresh is a safety net.
        let next = Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [current()], policy: .after(next)))
    }

    private func current() -> BudgetEntry {
        BudgetEntry(date: Date(), snapshot: WidgetSnapshot.load(from: UserDefaults(suiteName: WidgetSnapshot.appGroup)))
    }
}

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BudgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            content(snapshot)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken(snapshot))
        } else {
            Text("Open Pocket Budget to start tracking.")
                .font(.caption)
        }
    }

    @ViewBuilder
    private func content(_ snapshot: WidgetSnapshot) -> some View {
        let status = snapshot.status
        if family == .accessoryRectangular {
            VStack(alignment: .leading) {
                Text("Spent this month").font(.caption2)
                Text(snapshot.spent.formatted()).font(.headline)
                if let fraction = status.fractionUsed {
                    Gauge(value: min(fraction, 1)) { EmptyView() }
                        .gaugeStyle(.accessoryLinear)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(snapshot.period.start().formatted(.dateTime.month(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(snapshot.spent.formatted())
                    .font(.title2.bold().monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if let budget = snapshot.budget, let fraction = status.fractionUsed {
                    Gauge(value: min(fraction, 1)) { Text("Budget") }
                        .gaugeStyle(.linearCapacity)
                        .tint(tint(status.level))
                    Text("of \(budget.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No budget set").font(.caption).foregroundStyle(.secondary)
                }
                if family == .systemMedium, let top = snapshot.topCategory {
                    Label("Most on \(top.displayName)", systemImage: top.symbolName)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func tint(_ level: BudgetLevel) -> Color {
        switch level {
        case .over: return .red
        case .warning: return .orange
        default: return .green
        }
    }

    private func spoken(_ snapshot: WidgetSnapshot) -> String {
        var text = "Spent \(snapshot.spent.formatted()) this month"
        if let budget = snapshot.budget { text += " of \(budget.formatted())" }
        if snapshot.status.level == .over { text += ". Over budget" }
        return text
    }
}

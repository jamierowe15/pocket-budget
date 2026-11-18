import AppIntents
import BudgetKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @AppStorage("dailyReminder") private var reminderOn = false
    @State private var confirmDelete = false
    @State private var showDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Daily reminder at 8 PM", isOn: $reminderOn)
                        .accessibilityIdentifier("settings.reminder")
                } footer: {
                    Text("A gentle nudge each evening to log what you spent.")
                }

                Section("Siri and Shortcuts") {
                    SiriTipView(intent: LogExpenseIntent())
                    ShortcutsLink()
                }

                Section {
                    ShareLink(item: CSVFile(text: CSVExporter.csv(expenses.map(\.record))),
                              preview: SharePreview("Pocket Budget expenses")) {
                        Label("Export as CSV", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("settings.export")
                    Button("Delete all data", role: .destructive) { confirmDelete = true }
                        .accessibilityIdentifier("settings.deleteAll")
                } header: {
                    Text("Your data")
                } footer: {
                    Text("\(expenses.count) expenses saved on this device.")
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    Text("Your data stays on this device. No account, no ads, no tracking.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onChange(of: reminderOn) { _, isOn in
                Task { @MainActor in
                    if isOn {
                        let granted = await ReminderScheduler.enable()
                        if !granted {
                            reminderOn = false
                            showDenied = true
                        }
                    } else {
                        ReminderScheduler.disable()
                    }
                }
            }
            .alert("Notifications are off", isPresented: $showDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Turn on notifications for Pocket Budget in the Settings app to get reminders.")
            }
            .confirmationDialog("Delete every expense and budget?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    ExpenseRepository(context: context).deleteAll()
                }
            } message: {
                Text("This can't be undone. Export a CSV first if you want a copy.")
            }
        }
    }
}

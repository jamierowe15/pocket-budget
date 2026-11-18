import BudgetKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date) private var expenses: [Expense]
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
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

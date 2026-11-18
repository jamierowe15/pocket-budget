import BudgetKit
import SwiftUI

/// Add or edit an expense. A sheet with its own navigation bar for Cancel and Save.
struct ExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var model: ExpenseFormModel
    @FocusState private var amountFocused: Bool

    init(expense: Expense?) {
        _model = State(initialValue: ExpenseFormModel(expense: expense, today: AppClock.now))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $model.amountText, prompt: Text("0.00"))
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit())
                        .focused($amountFocused)
                        .accessibilityIdentifier("form.amount")
                    if let message = model.validationMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(Palette.over)
                    }
                } header: {
                    Text("Amount")
                }

                Section {
                    Picker("Category", selection: $model.category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbolName).tag(category)
                        }
                    }
                    .accessibilityIdentifier("form.category")
                    DatePicker("Date", selection: $model.date, in: ...AppClock.now, displayedComponents: .date)
                    TextField("Note (optional)", text: $model.note)
                        .accessibilityIdentifier("form.note")
                }

                if model.isEditing {
                    Section {
                        Button("Delete expense", role: .destructive) {
                            model.delete(using: ExpenseRepository(context: context))
                            dismiss()
                        }
                        .accessibilityIdentifier("form.delete")
                    }
                }
            }
            .navigationTitle(model.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save(using: ExpenseRepository(context: context)) { dismiss() }
                    }
                    .disabled(!model.isValid)
                    .accessibilityIdentifier("form.save")
                }
            }
            .onAppear {
                if !model.isEditing { amountFocused = true }
            }
        }
    }
}

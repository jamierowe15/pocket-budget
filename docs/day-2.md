# Day 2: The SwiftUI app on SwiftData

## Goal
A complete budgeting app: log expenses, set monthly budgets per category and see charts,
with everything saved on the phone by SwiftData.

## How it fits together
```
PocketBudgetApp ── .modelContainer(Persistence.shared) ──▶ every view can read the database
RootView (TabView)
 ├─ ExpensesView ─▶ ExpenseList (@Query for one month) ─▶ ExpenseFormView (ExpenseFormModel)
 ├─ BudgetsView  ─▶ BudgetList (@Query) ─▶ BudgetLimitView
 ├─ InsightsView ─▶ Swift Charts: bars by category, running total vs budget
 └─ SettingsView ─▶ CSV export (ShareLink), delete all
Reads: @Query in views.   Writes: ExpenseRepository (save + refresh the widget's summary).
Maths: BudgetKit (Day 1).
```

## Skills shown
| Skill | Where |
|---|---|
| SwiftData `@Model`, `@Attribute(.unique)`, `ModelContainer`, in-memory containers for tests | `App/Model/` |
| `@Query` with a `#Predicate` rebuilt when the month changes | `ExpenseList`, `BudgetList`, `InsightsContent` |
| `@Observable` form model with validation, `@State`, `@Binding`, `@FocusState` | `ExpenseFormModel`, `ExpenseFormView` |
| Swift Charts: bar, line, rule marks with annotations and VoiceOver labels | `InsightsView` |
| `ContentUnavailableView`, swipe actions, sheets, `ShareLink` with `Transferable` | Expenses, Settings |
| Adaptive layout for the largest text sizes (`AdaptiveRow`) and iPad | `Palette.swift`, all rows |
| Status shown by colour **and** symbol **and** words | `BudgetRow` |

## Proof
Unit tests in `AppTests/` (Swift Testing): the repository against a real in-memory SwiftData
store (add, update, delete, budgets, delete all, CSV, sample data) and the form's validation.

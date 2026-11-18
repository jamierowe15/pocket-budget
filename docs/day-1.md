# Day 1: BudgetKit

## Goal
Write and test the rules of budgeting before drawing a single screen. If the maths is
wrong, no amount of nice UI will save the app.

## What's in the package
| File | Job |
|---|---|
| `Money.swift` | Whole cents in an `Int64`; parsing typed amounts (English or French); `+` and `-` |
| `ExpenseCategory.swift` | The nine categories with names and SF Symbols; `ExpenseRecord`, a plain copy of an expense |
| `MonthPeriod.swift` | A calendar month: start, end, next, previous, number of days |
| `BudgetCalculator.swift` | Totals, per-category totals, budget level (on track / 80% warning / over), daily average, projection, running total |
| `CSVExporter.swift` | Spreadsheet export with proper escaping |
| `WidgetSnapshot.swift` | The summary the widget reads from the shared App Group |

## Decisions
- **Swift 6 language mode.** The compiler proves there are no data races. Everything is a value type and `Sendable`.
- **Swift Testing**, Apple's newer test framework: `@Test`, `#expect`, and parameterized tests that run one test over many inputs.
- **Pass the Calendar in.** Month maths depends on time zones; tests use a fixed UTC calendar so they pass on every machine.

## Proof
- `swift test` in `Packages/BudgetKit`: about 50 test cases including parameterized ones.
- CI jobs `packages` (macOS, 70% coverage gate) and `packages-linux`.

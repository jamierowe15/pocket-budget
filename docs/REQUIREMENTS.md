# How this lab maps to the job posting

TD Mobile Software Engineer I (iOS), req. R_1520654. This is the third of my iOS labs, after
[Maple Wallet](https://github.com/jamierowe15/maple-wallet) and [Loonie Rates](https://github.com/jamierowe15/loonie-rates).

| Posting requirement | Evidence here |
|---|---|
| SwiftUI production-style app | Four tabs, forms, sheets, swipe actions, charts, iPhone and iPad |
| Modern Swift features | `@Observable`, macros (`@Model`, `#Predicate`, `#expect`), Swift 6 language mode in `BudgetKit`, Swift Testing |
| Swift Concurrency, thread safety | `Sendable` value types checked by Swift 6; `@MainActor` repository and intent; async notification APIs |
| Reusable UI components, adaptive layouts | `AdaptiveRow`, `BudgetRow`, `MonthSwitcher`; iPad screenshots |
| MVVM, protocol-oriented design | `ExpenseFormModel` (tested without UI), `ExpenseRepository` as the single write path, pure `BudgetCalculator` |
| Offline / local data | SwiftData store on the device; works with no network at all |
| Accessibility | `docs/accessibility.md`, automated audit, status by symbol and words |
| Unit, integration and UI tests; coverage | Swift Testing package and app tests (real in-memory SwiftData), XCTest UI tests, 70% gate |
| Git, PRs, CI/CD | One PR per day, protected `main`, CI proof PR, `ci.yml` and `evidence.yml` |
| SPM, modular code | `Packages/BudgetKit`, shared by the app and the widget |
| **Nice to have:** widgets, deep system features, privacy | WidgetKit + App Groups, App Intents / Siri, local notifications, privacy manifest |
| Scripting (Bash, Python, YAML) | `scripts/*.sh`, `scripts/*.py`, workflows |

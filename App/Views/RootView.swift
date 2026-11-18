import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }
            BudgetsView()
                .tabItem { Label("Budgets", systemImage: "chart.bar.doc.horizontal") }
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Palette.brand)
    }
}

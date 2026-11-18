import BudgetKit
import SwiftUI
import UIKit

/// App colours, each with a light and dark version and at least 4.5:1 contrast for text.
enum Palette {
    static let brand = Color(light: 0x0B6E4F, dark: 0x5FD3A4)
    static let warning = Color(light: 0x8A5300, dark: 0xFFC266)
    static let over = Color(light: 0xB3261E, dark: 0xFF8A80)

    static func color(for level: BudgetLevel) -> Color {
        switch level {
        case .over: return over
        case .warning: return warning
        case .onTrack, .none: return brand
        }
    }

    /// A shape for each level too, so nobody has to tell green from red.
    static func symbol(for level: BudgetLevel) -> String {
        switch level {
        case .over: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .onTrack: return "checkmark.circle.fill"
        case .none: return "circle.dashed"
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                           blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
        })
    }
}

extension Bundle {
    var appVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}

/// Side by side normally; stacked at the largest text sizes so nothing gets cut off.
struct AdaptiveRow<Leading: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let leading: Leading
    private let trailing: Trailing

    init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                leading
                trailing
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                leading
                Spacer(minLength: 8)
                trailing
            }
        }
    }
}

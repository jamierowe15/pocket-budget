import Foundation

/// An amount in Canadian dollars, stored as whole cents.
/// Never Double for money: 0.1 + 0.2 is 0.30000000000000004 in binary floating point.
public struct Money: Hashable, Codable, Sendable, Comparable, AdditiveArithmetic {
    public var cents: Int64

    public init(cents: Int64) {
        self.cents = cents
    }

    /// From a Double (Siri gives us one), rounded to the nearest cent.
    public init?(dollars: Double) {
        guard dollars.isFinite, abs(dollars) < 1_000_000_000 else { return nil }
        self.cents = Int64((dollars * 100).rounded())
    }

    public static let zero = Money(cents: 0)

    public static func + (lhs: Money, rhs: Money) -> Money { Money(cents: lhs.cents + rhs.cents) }
    public static func - (lhs: Money, rhs: Money) -> Money { Money(cents: lhs.cents - rhs.cents) }
    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.cents < rhs.cents }

    /// For charts only (they need a plain number to place a bar). Never do maths with it.
    public var dollars: Double { Double(cents) / 100 }

    /// "12.30" with no symbol, for text fields and CSV.
    public var plainString: String {
        let sign = cents < 0 ? "-" : ""
        let units = cents.magnitude
        let fraction = units % 100
        return "\(sign)\(units / 100).\(fraction < 10 ? "0" : "")\(fraction)"
    }

    /// "$1,234.50" or "1 234,50 $", following the phone's region.
    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(plainString)"
    }

    /// Reads what a person types: "42", "42.5", "$1,234.56", ".99", or "42,50" with a French
    /// decimal comma. Returns nil for letters, negatives or more than two decimal places.
    public init?(parsing text: String, decimalSeparator: Character = ".") {
        var cleaned = ""
        for character in text.trimmingCharacters(in: .whitespacesAndNewlines) {
            if character.isASCII && character.isNumber {
                cleaned.append(character)
            } else if character == decimalSeparator {
                cleaned.append(".")
            } else if [",", " ", "$", "\u{00A0}", "\u{202F}"].contains(character) {
                continue
            } else {
                return nil
            }
        }
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !cleaned.isEmpty, parts.count <= 2, cleaned != "." else { return nil }
        let whole = parts[0].isEmpty ? 0 : Int64(parts[0])
        guard let whole else { return nil }
        var fraction: Int64 = 0
        if parts.count == 2 {
            guard parts[1].count <= 2 else { return nil }
            fraction = Int64(parts[1].padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0
        }
        let (scaled, overflow) = whole.multipliedReportingOverflow(by: 100)
        guard !overflow else { return nil }
        self.cents = scaled + fraction
    }
}

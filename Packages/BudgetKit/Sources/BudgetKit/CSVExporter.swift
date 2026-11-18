import Foundation

/// Turns expenses into a CSV file that Excel, Numbers and Google Sheets can open.
public enum CSVExporter {
    public static let header = "date,category,amount,note"

    public static func csv(_ records: [ExpenseRecord], calendar: Calendar = .current) -> String {
        let rows = records.sorted { $0.date < $1.date }.map { record in
            [day(record.date, calendar: calendar), record.category.rawValue, record.amount.plainString, escape(record.note)]
                .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    /// A field with a comma, quote or new line must be wrapped in quotes, and quotes inside it
    /// doubled (RFC 4180). Otherwise "Coffee, muffin" would split into two columns.
    public static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// "2026-11-13": sorts correctly as text and every spreadsheet understands it.
    static func day(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return "\(parts.year ?? 0)-\(month < 10 ? "0" : "")\(month)-\(day < 10 ? "0" : "")\(day)"
    }
}

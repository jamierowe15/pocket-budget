import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Lets ShareLink hand a real "pocket-budget-expenses.csv" file to Mail, Files, AirDrop...
struct CSVFile: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("pocket-budget-expenses.csv")
            try file.text.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

import Foundation

struct CSVExportService {
    static func generateCSV(for log: DailyLog) -> URL? {
        let fileName = "HimmerFlow_\(log.towerName.replacingOccurrences(of: " ", with: "_"))_\(log.date.formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvString = "Item Name,Received Pieces,Required Pieces,Difference Pieces,Deliverable Bundles,Shortage Bundles,Leftover Bundles,Status\n"
        
        let summaries = log.summarySnapshot.sorted { $0.itemName < $1.itemName }
        
        for summary in summaries {
            let row = [
                summary.itemName,
                "\(summary.receivedPieces)",
                "\(summary.requiredPieces)",
                "\(summary.differencePieces)",
                "\(summary.deliverableBundles)",
                "\(summary.shortageBundles)",
                "\(summary.leftoverBundles)",
                summary.status.rawValue.capitalized
            ]
            
            let rowString = row.map { "\"\($0)\"" }.joined(separator: ",")
            csvString.append(rowString + "\n")
        }
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to create CSV file: \(error)")
            return nil
        }
    }
}

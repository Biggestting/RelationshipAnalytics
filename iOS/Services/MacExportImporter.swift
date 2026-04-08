import Foundation

/// Imports the JSON export file created by the macOS companion app.
/// Users can AirDrop or share the file to the iOS app.
final class MacExportImporter {
    static let shared = MacExportImporter()
    private init() {}

    func importFile(from url: URL) throws -> [ContactAnalyticsBundle] {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFormat("Cannot access file")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exported = try decoder.decode([ExportedBundle].self, from: data)

        let bundles = exported.map { item in
            ContactAnalyticsBundle(
                contact: item.contact,
                messageStats: item.messageStats,
                callStats: item.callStats,
                rankData: item.rankData
            )
        }

        // Cache locally
        saveBundles(bundles)

        return bundles
    }

    func loadCachedBundles() -> [ContactAnalyticsBundle] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = UserDefaults.standard.data(forKey: "macExportBundles"),
              let bundles = try? decoder.decode([ExportedBundle].self, from: data) else {
            return []
        }

        return bundles.map {
            ContactAnalyticsBundle(contact: $0.contact, messageStats: $0.messageStats, callStats: $0.callStats, rankData: $0.rankData)
        }
    }

    private func saveBundles(_ bundles: [ContactAnalyticsBundle]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let exportable = bundles.map {
            ExportedBundle(contact: $0.contact, messageStats: $0.messageStats, callStats: $0.callStats, rankData: $0.rankData)
        }

        if let data = try? encoder.encode(exportable) {
            UserDefaults.standard.set(data, forKey: "macExportBundles")
        }
    }
}

private struct ExportedBundle: Codable {
    let contact: ContactProfile
    let messageStats: MessageStats
    let callStats: CallStats
    let rankData: RankData
}

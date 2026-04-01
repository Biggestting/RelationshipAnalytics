import Foundation

struct RankData: Codable {
    let contactId: String
    let currentRank: Int
    let bestRank: Int
    let currentRankDate: Date
    let bestRankDate: Date
    let rankHistory: [RankPoint]

    var currentRankFormatted: String { "#\(currentRank)" }
    var bestRankFormatted: String { "#\(bestRank)" }

    var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: currentRankDate)
    }

    var bestDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bestRankDate)
    }
}

struct RankPoint: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }
    let date: Date
    let rank: Int

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

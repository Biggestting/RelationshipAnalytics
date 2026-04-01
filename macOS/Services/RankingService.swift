import Foundation

/// Calculates contact rankings based on message frequency over time.
final class RankingService {

    /// Calculate weekly rank history for a contact among all contacts
    func calculateRankHistory(
        contactId: String,
        allContactStats: [(id: String, weeklyMessageCounts: [Date: Int])]
    ) -> RankData {
        // Get all unique weeks
        let allWeeks = Set(allContactStats.flatMap { $0.weeklyMessageCounts.keys })
            .sorted()

        var rankHistory: [RankPoint] = []
        var bestRank = Int.max
        var bestDate = Date()
        var currentRank = 0
        var currentDate = Date()

        for week in allWeeks {
            // Rank all contacts by their message count in this week
            let ranked = allContactStats
                .map { (id: $0.id, count: $0.weeklyMessageCounts[week] ?? 0) }
                .sorted { $0.count > $1.count }

            if let index = ranked.firstIndex(where: { $0.id == contactId }) {
                let rank = index + 1
                rankHistory.append(RankPoint(date: week, rank: rank))

                if rank < bestRank {
                    bestRank = rank
                    bestDate = week
                }
                currentRank = rank
                currentDate = week
            }
        }

        if bestRank == Int.max { bestRank = 0 }

        return RankData(
            contactId: contactId,
            currentRank: currentRank,
            bestRank: bestRank,
            currentRankDate: currentDate,
            bestRankDate: bestDate,
            rankHistory: rankHistory
        )
    }

    /// Calculate weekly message counts for a contact from daily activity
    func weeklyMessageCounts(from activity: [DayActivity]) -> [Date: Int] {
        let calendar = Calendar.current
        var weeklyCounts: [Date: Int] = [:]

        for day in activity {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: day.date)?.start ?? day.date
            weeklyCounts[weekStart, default: 0] += day.count
        }

        return weeklyCounts
    }
}

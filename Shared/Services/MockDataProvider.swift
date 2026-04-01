import Foundation

enum MockDataProvider {

    static let contact = ContactProfile(
        id: "contact_001",
        name: "Nina",
        initials: "N",
        talkingSince: dateFrom("2025-02-01"),
        phoneNumber: "+1 (555) 123-4567",
        email: "nina@example.com"
    )

    static let contacts: [ContactProfile] = [
        contact,
        ContactProfile(id: "contact_002", name: "Alex", initials: "A", talkingSince: dateFrom("2024-06-15"), phoneNumber: nil, email: nil),
        ContactProfile(id: "contact_003", name: "Jordan", initials: "J", talkingSince: dateFrom("2023-11-20"), phoneNumber: nil, email: nil),
        ContactProfile(id: "contact_004", name: "Sam", initials: "S", talkingSince: dateFrom("2025-01-10"), phoneNumber: nil, email: nil),
        ContactProfile(id: "contact_005", name: "Riley", initials: "R", talkingSince: dateFrom("2024-03-05"), phoneNumber: nil, email: nil),
    ]

    static let messageStats = MessageStats(
        contactId: "contact_001",
        totalSent: 237,
        totalReceived: 240,
        totalMessages: 477,
        messageActivity: generateHeatmapData(),
        activeStreak: 0,
        bestStreak: 4,
        youStartPercentage: 74,
        yourReplyTime: 14400,    // 4 hours
        theirReplyTime: 3240,    // 54 minutes
        longestConvo: ConversationInfo(
            messageCount: 35,
            duration: 68100,     // 18h 55m
            startDate: dateFrom("2025-09-30"),
            endDate: dateFrom("2025-10-01")
        ),
        firstMessageSent: MessagePreview(
            text: "Hey this is seif, 2:15 still good?",
            date: dateFrom("2025-02-01"),
            isFromUser: true
        ),
        firstMessageReceived: nil
    )

    static let callStats = CallStats(
        contactId: "contact_001",
        totalCallTime: 1200,     // 20 minutes
        totalCalls: 30,
        answeredCalls: 26,
        averageCallDuration: 60, // 1 minute
        lastAnsweredDate: dateFrom("2026-03-14"),
        monthlyCallData: generateMonthlyCallData()
    )

    static let rankData = RankData(
        contactId: "contact_001",
        currentRank: 14,
        bestRank: 14,
        currentRankDate: dateFrom("2026-03-26"),
        bestRankDate: dateFrom("2026-03-26"),
        rankHistory: generateRankHistory()
    )

    // MARK: - Generators

    private static func dateFrom(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? Date()
    }

    private static func generateHeatmapData() -> [DayActivity] {
        var activities: [DayActivity] = []
        let calendar = Calendar.current
        let today = Date()

        for dayOffset in 0..<180 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let count: Int
            let random = Int.random(in: 0...20)
            if random < 5 {
                count = 0
            } else if random < 10 {
                count = Int.random(in: 1...3)
            } else if random < 15 {
                count = Int.random(in: 4...8)
            } else {
                count = Int.random(in: 9...20)
            }
            activities.append(DayActivity(date: date, count: count))
        }
        return activities.reversed()
    }

    private static func generateMonthlyCallData() -> [MonthlyCallData] {
        let months = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
        return months.enumerated().map { index, month in
            let year = index < 9 ? 2025 : 2026
            let minutes: Double
            let calls: Int
            if index < 4 {
                minutes = 0
                calls = 0
            } else if index < 8 {
                minutes = Double.random(in: 1...3)
                calls = Int.random(in: 1...4)
            } else {
                minutes = Double.random(in: 2...6)
                calls = Int.random(in: 2...6)
            }
            return MonthlyCallData(month: month, year: year, totalMinutes: minutes, callCount: calls)
        }
    }

    private static func generateRankHistory() -> [RankPoint] {
        let calendar = Calendar.current
        var points: [RankPoint] = []
        let startDate = dateFrom("2025-04-01")

        var currentRank = 31
        for weekOffset in 0..<52 {
            guard let date = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate) else { continue }
            // Gradually improve rank with some fluctuation
            let trend = max(1, currentRank - Int.random(in: -2...3))
            currentRank = min(31, max(14, trend))
            points.append(RankPoint(date: date, rank: currentRank))
        }

        // Ensure last point matches current rank
        if var last = points.last {
            points[points.count - 1] = RankPoint(date: last.date, rank: 14)
        }

        return points
    }
}

import Foundation

enum MockDataProvider {

    static let contact = ContactProfile(
        id: "contact_001",
        name: "Nina",
        initials: "N",
        talkingSince: dateFrom("2025-02-01"),
        identifiers: [
            ContactIdentifier(value: "+1 (555) 123-4567", type: .phone, label: "Personal", addedDate: dateFrom("2025-02-01")),
            ContactIdentifier(value: "+1 (555) 987-6543", type: .phone, label: "Old Number", addedDate: dateFrom("2024-08-15")),
            ContactIdentifier(value: "nina@example.com", type: .email, label: nil, addedDate: dateFrom("2025-02-01")),
        ]
    )

    static let contacts: [ContactProfile] = [
        contact,
        ContactProfile(id: "contact_002", name: "Alex", initials: "A", talkingSince: dateFrom("2024-06-15"), identifiers: [
            ContactIdentifier(value: "+1 (555) 222-3333", type: .phone, label: nil, addedDate: dateFrom("2024-06-15"))
        ]),
        ContactProfile(id: "contact_003", name: "Jordan", initials: "J", talkingSince: dateFrom("2023-11-20"), identifiers: [
            ContactIdentifier(value: "+1 (555) 444-5555", type: .phone, label: nil, addedDate: dateFrom("2023-11-20"))
        ]),
        ContactProfile(id: "contact_004", name: "Sam", initials: "S", talkingSince: dateFrom("2025-01-10"), identifiers: [
            ContactIdentifier(value: "+1 (555) 666-7777", type: .phone, label: nil, addedDate: dateFrom("2025-01-10"))
        ]),
        ContactProfile(id: "contact_005", name: "Riley", initials: "R", talkingSince: dateFrom("2024-03-05"), identifiers: [
            ContactIdentifier(value: "+1 (555) 888-9999", type: .phone, label: nil, addedDate: dateFrom("2024-03-05"))
        ]),
    ]

    static let messageStats = MessageStats(
        contactId: "contact_001",
        totalSent: 237,
        totalReceived: 240,
        totalMessages: 477,
        messageActivity: _heatmap,
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
        firstMessageReceived: nil,
        messagesEdited: 14,
        messagesUnsent: 3,
        voiceMessages: VoiceMessageStats(
            sentCount: 12,
            receivedCount: 8,
            totalDuration: 272,
            averageDuration: 13.6,
            longestDuration: 45,
            contactPhoneNumber: "+1 (555) 123-4567"
        ),
        emojiStats: EmojiStats(
            topEmojis: [
                EmojiCount(emoji: "😂", count: 89, fromYou: 52, fromThem: 37),
                EmojiCount(emoji: "❤️", count: 64, fromYou: 28, fromThem: 36),
                EmojiCount(emoji: "😭", count: 41, fromYou: 25, fromThem: 16),
                EmojiCount(emoji: "🔥", count: 33, fromYou: 20, fromThem: 13),
                EmojiCount(emoji: "💀", count: 27, fromYou: 18, fromThem: 9),
                EmojiCount(emoji: "😍", count: 22, fromYou: 8, fromThem: 14),
                EmojiCount(emoji: "👀", count: 19, fromYou: 12, fromThem: 7),
                EmojiCount(emoji: "🥺", count: 15, fromYou: 4, fromThem: 11),
            ],
            yourTopEmojis: [
                EmojiCount(emoji: "😂", count: 52, fromYou: 52, fromThem: 0),
                EmojiCount(emoji: "❤️", count: 28, fromYou: 28, fromThem: 0),
                EmojiCount(emoji: "😭", count: 25, fromYou: 25, fromThem: 0),
            ],
            theirTopEmojis: [
                EmojiCount(emoji: "❤️", count: 36, fromYou: 0, fromThem: 36),
                EmojiCount(emoji: "😂", count: 37, fromYou: 0, fromThem: 37),
                EmojiCount(emoji: "😭", count: 16, fromYou: 0, fromThem: 16),
            ],
            totalEmojisSent: 198,
            totalEmojisReceived: 156,
            uniqueEmojiCount: 43
        )
    )

    static let callStats = CallStats(
        contactId: "contact_001",
        totalCallTime: 1200,     // 20 minutes
        totalCalls: 30,
        answeredCalls: 26,
        averageCallDuration: 60, // 1 minute
        lastAnsweredDate: dateFrom("2026-03-14"),
        monthlyCallData: _monthly,
        callRecords: _calls,
        hourlyCallPattern: _hourly,
        missedStats: MissedCallStats(
            youMissed: 2,
            theyMissed: 5,
            totalMissed: 7,
            totalAnswered: 26,
            yourAnswerRate: 92,
            theirAnswerRate: 78,
            longestUnansweredStreak: 3
        ),
        faceTimeStats: FaceTimeStats(
            videoCallCount: 4,
            audioCallCount: 6,
            regularCallCount: 20,
            videoTotalDuration: 1800,    // 30m
            audioFTDuration: 480,        // 8m
            regularDuration: 720,        // 12m
            lastFaceTimeDate: dateFrom("2026-03-10")
        )
    )

    static let rankData = RankData(
        contactId: "contact_001",
        currentRank: 14,
        bestRank: 14,
        currentRankDate: dateFrom("2026-03-26"),
        bestRankDate: dateFrom("2026-03-26"),
        rankHistory: _rank
    )

    // MARK: - Cached generated data (computed once, reused)
    private static let _heatmap = generateHeatmapData()
    private static let _monthly = generateMonthlyCallData()
    private static let _calls = generateCallRecords()
    private static let _hourly = generateHourlyPattern()
    private static let _rank = generateRankHistory()

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

    private static func generateCallRecords() -> [CallRecord] {
        let calendar = Calendar.current
        var records: [CallRecord] = []
        let types: [CallRecord.CallType] = [.audio, .audio, .audio, .faceTimeVideo, .faceTimeAudio]
        let directions: [CallRecord.CallDirection] = [.incoming, .outgoing]

        for i in 0..<20 {
            let daysAgo = Int.random(in: 0...90)
            let hour = [9, 12, 14, 18, 20, 22].randomElement()!
            var components = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: -daysAgo, to: Date())!)
            components.hour = hour
            components.minute = Int.random(in: 0...59)
            let date = calendar.date(from: components) ?? Date()

            let answered = i < 15 // first 15 answered, last 5 missed
            let duration: TimeInterval = answered ? TimeInterval(Int.random(in: 15...300)) : 0
            let type = types[i % types.count]
            let direction = directions[i % directions.count]

            records.append(CallRecord(
                date: date,
                duration: duration,
                type: type,
                direction: direction,
                answered: answered
            ))
        }
        return records.sorted { $0.date > $1.date }
    }

    private static func generateHourlyPattern() -> [HourlyCallData] {
        var data: [HourlyCallData] = []
        for day in 1...7 {
            for hour in 0..<24 {
                let count: Int
                // More calls in evening, fewer at night
                switch hour {
                case 0...6: count = 0
                case 7...8: count = Int.random(in: 0...1)
                case 9...11: count = Int.random(in: 0...2)
                case 12...14: count = Int.random(in: 0...2)
                case 15...17: count = Int.random(in: 0...1)
                case 18...21: count = Int.random(in: 1...4)
                default: count = Int.random(in: 0...2)
                }
                data.append(HourlyCallData(hour: hour, callCount: count, dayOfWeek: day))
            }
        }
        return data
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

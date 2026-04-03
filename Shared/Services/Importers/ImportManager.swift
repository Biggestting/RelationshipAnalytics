import Foundation

/// Manages importing and storing chat exports from various platforms
final class ImportManager {
    static let shared = ImportManager()

    private let parsers: [ChatPlatform: ChatExportParser] = [
        .whatsapp: WhatsAppParser(),
        .messenger: MessengerParser(),
        .instagram: InstagramParser(),
        .twitter: TwitterParser(),
    ]

    private init() {}

    /// Parse a file for the given platform
    func importFile(data: Data, fileName: String, platform: ChatPlatform, userName: String) throws -> ImportResult {
        guard let parser = parsers[platform] else {
            throw ImportError.invalidFormat("No parser for \(platform.rawValue)")
        }
        let result = try parser.parse(data: data, fileName: fileName, userName: userName)
        saveImport(result)
        return result
    }

    /// Auto-detect platform from file extension and content
    func detectPlatform(fileName: String, data: Data) -> ChatPlatform? {
        let ext = (fileName as NSString).pathExtension.lowercased()

        if ext == "txt" {
            // WhatsApp exports are .txt
            if let text = String(data: data.prefix(500), encoding: .utf8) {
                if text.contains("[") && text.contains("]:") {
                    return .whatsapp
                }
                if text.range(of: #"\d{1,2}/\d{1,2}/\d{2,4}.*-.*:"#, options: .regularExpression) != nil {
                    return .whatsapp
                }
            }
        }

        if ext == "json" {
            if let text = String(data: data.prefix(1000), encoding: .utf8) {
                if text.contains("\"participants\"") && text.contains("\"messages\"") {
                    // Could be Messenger or Instagram — check for Instagram-specific fields
                    if text.contains("\"share\"") || fileName.lowercased().contains("instagram") {
                        return .instagram
                    }
                    return .messenger
                }
            }
        }

        if ext == "js" {
            if let text = String(data: data.prefix(200), encoding: .utf8) {
                if text.contains("direct_messages") || text.contains("dmConversation") {
                    return .twitter
                }
            }
        }

        return nil
    }

    /// Convert ImportResult to MessageStats for display in existing cards
    func convertToMessageStats(from result: ImportResult) -> MessageStats {
        let activity = buildDailyActivity(from: result.messages)
        let streak = calculateStreak(from: activity)
        let youStart = calculateYouStartPercentage(from: result.messages)
        let replyTimes = calculateReplyTimes(from: result.messages)
        let longestConvo = findLongestConvo(from: result.messages)

        let voiceMessages = result.voiceCount > 0 ? VoiceMessageStats(
            sentCount: result.messages.filter { $0.isFromUser && $0.isVoiceMessage }.count,
            receivedCount: result.messages.filter { !$0.isFromUser && $0.isVoiceMessage }.count,
            totalDuration: 0,
            averageDuration: 0,
            longestDuration: 0,
            contactPhoneNumber: nil
        ) : nil

        return MessageStats(
            contactId: "import_\(result.platform.rawValue)_\(result.contactName)",
            totalSent: result.sentCount,
            totalReceived: result.receivedCount,
            totalMessages: result.totalMessages,
            messageActivity: activity,
            activeStreak: streak.current,
            bestStreak: streak.best,
            youStartPercentage: youStart,
            yourReplyTime: replyTimes.yours,
            theirReplyTime: replyTimes.theirs,
            longestConvo: longestConvo,
            firstMessageSent: result.messages.first.map { msg in
                MessagePreview(text: msg.text, date: msg.date, isFromUser: msg.isFromUser)
            },
            firstMessageReceived: nil,
            messagesEdited: result.editedCount,
            messagesUnsent: result.unsentCount,
            voiceMessages: voiceMessages
        )
    }

    // MARK: - Persistence

    func saveImport(_ result: ImportResult) {
        var imports = loadAllImports()
        imports.removeAll { $0.platform == result.platform && $0.contactName == result.contactName }
        imports.append(result)

        if let data = try? JSONEncoder().encode(imports) {
            UserDefaults.standard.set(data, forKey: "importedChats")
        }
    }

    func loadAllImports() -> [ImportResult] {
        guard let data = UserDefaults.standard.data(forKey: "importedChats"),
              let imports = try? JSONDecoder().decode([ImportResult].self, from: data) else {
            return []
        }
        return imports
    }

    func deleteImport(platform: ChatPlatform, contactName: String) {
        var imports = loadAllImports()
        imports.removeAll { $0.platform == platform && $0.contactName == contactName }
        if let data = try? JSONEncoder().encode(imports) {
            UserDefaults.standard.set(data, forKey: "importedChats")
        }
    }

    // MARK: - Analytics helpers

    private func buildDailyActivity(from messages: [ImportedMessage]) -> [DayActivity] {
        let calendar = Calendar.current
        var dailyCounts: [Date: Int] = [:]
        for msg in messages {
            let day = calendar.startOfDay(for: msg.date)
            dailyCounts[day, default: 0] += 1
        }
        return dailyCounts.map { DayActivity(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private func calculateStreak(from activity: [DayActivity]) -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let activeDays = Set(activity.filter { $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })

        var current = 0
        var check = today
        while activeDays.contains(check) {
            current += 1
            check = calendar.date(byAdding: .day, value: -1, to: check)!
        }

        var best = 0
        var streak = 0
        for day in activity.sorted(by: { $0.date < $1.date }) {
            if day.count > 0 {
                streak += 1
                best = max(best, streak)
            } else {
                streak = 0
            }
        }

        return (current, best)
    }

    private func calculateYouStartPercentage(from messages: [ImportedMessage]) -> Double {
        guard !messages.isEmpty else { return 0 }
        let gapThreshold: TimeInterval = 4 * 3600
        var youStart = 0
        var totalConvos = 0
        var lastDate: Date?

        for msg in messages.sorted(by: { $0.date < $1.date }) {
            if lastDate == nil || msg.date.timeIntervalSince(lastDate!) > gapThreshold {
                totalConvos += 1
                if msg.isFromUser { youStart += 1 }
            }
            lastDate = msg.date
        }

        return totalConvos > 0 ? Double(youStart) / Double(totalConvos) * 100 : 0
    }

    private func calculateReplyTimes(from messages: [ImportedMessage]) -> (yours: TimeInterval, theirs: TimeInterval) {
        let sorted = messages.sorted { $0.date < $1.date }
        var yourTimes: [TimeInterval] = []
        var theirTimes: [TimeInterval] = []

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if prev.isFromUser != curr.isFromUser {
                let diff = curr.date.timeIntervalSince(prev.date)
                if diff > 0, diff < 86400 {
                    if curr.isFromUser { yourTimes.append(diff) }
                    else { theirTimes.append(diff) }
                }
            }
        }

        let avgYours = yourTimes.isEmpty ? 0 : yourTimes.reduce(0, +) / Double(yourTimes.count)
        let avgTheirs = theirTimes.isEmpty ? 0 : theirTimes.reduce(0, +) / Double(theirTimes.count)
        return (avgYours, avgTheirs)
    }

    private func findLongestConvo(from messages: [ImportedMessage]) -> ConversationInfo? {
        let sorted = messages.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return nil }

        let gap: TimeInterval = 4 * 3600
        var bestCount = 0, bestStart = sorted[0].date, bestEnd = sorted[0].date
        var count = 1, start = sorted[0].date

        for i in 1..<sorted.count {
            if sorted[i].date.timeIntervalSince(sorted[i - 1].date) > gap {
                if count > bestCount {
                    bestCount = count
                    bestStart = start
                    bestEnd = sorted[i - 1].date
                }
                count = 1
                start = sorted[i].date
            } else {
                count += 1
            }
        }
        if count > bestCount {
            bestCount = count
            bestStart = start
            bestEnd = sorted.last!.date
        }

        guard bestCount > 1 else { return nil }
        return ConversationInfo(
            messageCount: bestCount,
            duration: bestEnd.timeIntervalSince(bestStart),
            startDate: bestStart,
            endDate: bestEnd
        )
    }
}

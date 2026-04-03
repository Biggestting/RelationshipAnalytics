import Foundation
import SQLite3

/// Reads the iMessage database (chat.db) on macOS.
/// Requires Full Disk Access permission in System Settings > Privacy & Security.
final class MessageDatabaseService {
    private let dbPath: String
    private var db: OpaquePointer?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = "\(home)/Library/Messages/chat.db"
    }

    // MARK: - Database Connection

    func open() throws {
        guard FileManager.default.fileExists(atPath: dbPath) else {
            throw DatabaseError.fileNotFound(dbPath)
        }
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(dbPath, &db, flags, nil) == SQLITE_OK else {
            let message = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw DatabaseError.cannotOpen(message)
        }
    }

    func close() {
        if let db { sqlite3_close(db) }
        db = nil
    }

    // MARK: - Queries

    /// Get all unique contacts with message history
    func fetchContacts() throws -> [ContactProfile] {
        let sql = """
            SELECT
                h.ROWID,
                h.id,
                COALESCE(h.uncanonicalized_id, h.id) as display_id,
                MIN(m.date) as first_message_date
            FROM handle h
            JOIN message m ON m.handle_id = h.ROWID
            GROUP BY h.ROWID
            ORDER BY MAX(m.date) DESC
        """
        return try query(sql) { stmt in
            let handleId = String(sqlite3_column_int64(stmt, 0))
            let identifier = columnText(stmt, 1)
            let displayId = columnText(stmt, 2)
            let firstDate = cocoaDate(sqlite3_column_int64(stmt, 3))

            let name = displayId.isEmpty ? identifier : displayId
            let initials = String(name.prefix(1)).uppercased()

            return ContactProfile(
                id: handleId,
                name: name,
                initials: initials,
                talkingSince: firstDate,
                phoneNumber: identifier.contains("@") ? nil : identifier,
                email: identifier.contains("@") ? identifier : nil
            )
        }
    }

    /// Get message stats for a specific contact
    func fetchMessageStats(handleId: String) throws -> MessageStats {
        guard let handleRowId = Int64(handleId) else {
            throw DatabaseError.invalidHandle
        }

        let sent = try countMessages(handleRowId: handleRowId, isFromMe: true)
        let received = try countMessages(handleRowId: handleRowId, isFromMe: false)
        let activity = try fetchDailyActivity(handleRowId: handleRowId)
        let streak = calculateStreak(activity: activity)
        let youStart = try calculateYouStartPercentage(handleRowId: handleRowId)
        let replyTimes = try calculateReplyTimes(handleRowId: handleRowId)
        let longestConvo = try findLongestConversation(handleRowId: handleRowId)
        let firstMessage = try fetchFirstMessage(handleRowId: handleRowId)
        let edited = try countEditedMessages(handleRowId: handleRowId)
        let unsent = try countUnsentMessages(handleRowId: handleRowId)
        let voiceStats = try fetchVoiceMessageStats(handleRowId: handleRowId)

        return MessageStats(
            contactId: handleId,
            totalSent: sent,
            totalReceived: received,
            totalMessages: sent + received,
            messageActivity: activity,
            activeStreak: streak.current,
            bestStreak: streak.best,
            youStartPercentage: youStart,
            yourReplyTime: replyTimes.yours,
            theirReplyTime: replyTimes.theirs,
            longestConvo: longestConvo,
            firstMessageSent: firstMessage,
            firstMessageReceived: nil,
            messagesEdited: edited,
            messagesUnsent: unsent,
            voiceMessages: voiceStats
        )
    }

    // MARK: - Private Helpers

    private func countMessages(handleRowId: Int64, isFromMe: Bool) throws -> Int {
        let sql = """
            SELECT COUNT(*) FROM message
            WHERE handle_id = ? AND is_from_me = ?
        """
        let results: [Int] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
            sqlite3_bind_int(stmt, 2, isFromMe ? 1 : 0)
        }) { stmt in
            Int(sqlite3_column_int(stmt, 0))
        }
        return results.first ?? 0
    }

    private func fetchDailyActivity(handleRowId: Int64) throws -> [DayActivity] {
        // iMessage dates are in nanoseconds since 2001-01-01
        let sql = """
            SELECT
                date(datetime(m.date / 1000000000 + 978307200, 'unixepoch', 'localtime')) as msg_date,
                COUNT(*) as msg_count
            FROM message m
            WHERE m.handle_id = ?
            AND m.date > 0
            GROUP BY msg_date
            ORDER BY msg_date ASC
        """
        return try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            let dateStr = columnText(stmt, 0)
            let count = Int(sqlite3_column_int(stmt, 1))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let date = formatter.date(from: dateStr) ?? Date()
            return DayActivity(date: date, count: count)
        }
    }

    private func calculateStreak(activity: [DayActivity]) -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let activeDates = Set(activity.filter { $0.count > 0 }.map { calendar.startOfDay(for: $0.date) })

        var current = 0
        var best = 0
        var streak = 0
        var checkDate = today

        // Count backwards from today
        while activeDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        current = streak

        // Find best streak
        streak = 0
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

    private func calculateYouStartPercentage(handleRowId: Int64) throws -> Double {
        // Find conversations where there's a gap of >4 hours between messages
        let sql = """
            SELECT is_from_me FROM message
            WHERE handle_id = ?
            AND date > 0
            ORDER BY date ASC
        """
        let messages: [(Bool)] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            sqlite3_column_int(stmt, 0) == 1
        }

        guard !messages.isEmpty else { return 0 }

        // Simplified: count who sends first message overall
        var youStart = 0
        var totalConvos = 0
        var lastWasGap = true

        for isFromMe in messages {
            if lastWasGap {
                totalConvos += 1
                if isFromMe { youStart += 1 }
            }
            lastWasGap = false
        }

        return totalConvos > 0 ? (Double(youStart) / Double(totalConvos)) * 100 : 0
    }

    private func calculateReplyTimes(handleRowId: Int64) throws -> (yours: TimeInterval, theirs: TimeInterval) {
        // Simplified average reply time calculation
        let sql = """
            SELECT date, is_from_me FROM message
            WHERE handle_id = ?
            AND date > 0
            ORDER BY date ASC
            LIMIT 1000
        """
        let messages: [(date: Int64, isFromMe: Bool)] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            (sqlite3_column_int64(stmt, 0), sqlite3_column_int(stmt, 1) == 1)
        }

        var yourReplyTimes: [TimeInterval] = []
        var theirReplyTimes: [TimeInterval] = []

        for i in 1..<messages.count {
            let prev = messages[i - 1]
            let curr = messages[i]
            if prev.isFromMe != curr.isFromMe {
                let diff = TimeInterval(curr.date - prev.date) / 1_000_000_000 // nanoseconds to seconds
                if diff > 0, diff < 86400 { // within 24 hours
                    if curr.isFromMe {
                        yourReplyTimes.append(diff)
                    } else {
                        theirReplyTimes.append(diff)
                    }
                }
            }
        }

        let avgYours = yourReplyTimes.isEmpty ? 0 : yourReplyTimes.reduce(0, +) / Double(yourReplyTimes.count)
        let avgTheirs = theirReplyTimes.isEmpty ? 0 : theirReplyTimes.reduce(0, +) / Double(theirReplyTimes.count)

        return (avgYours, avgTheirs)
    }

    private func findLongestConversation(handleRowId: Int64) throws -> ConversationInfo? {
        // Group messages into conversations with >4h gaps
        let sql = """
            SELECT date, is_from_me FROM message
            WHERE handle_id = ?
            AND date > 0
            ORDER BY date ASC
        """
        let messages: [(date: Int64, isFromMe: Bool)] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            (sqlite3_column_int64(stmt, 0), sqlite3_column_int(stmt, 1) == 1)
        }

        guard !messages.isEmpty else { return nil }

        let gapThreshold: Int64 = 4 * 3600 * 1_000_000_000 // 4 hours in nanoseconds
        var bestCount = 0
        var bestStart: Int64 = 0
        var bestEnd: Int64 = 0
        var currentCount = 1
        var currentStart = messages[0].date

        for i in 1..<messages.count {
            if messages[i].date - messages[i - 1].date > gapThreshold {
                if currentCount > bestCount {
                    bestCount = currentCount
                    bestStart = currentStart
                    bestEnd = messages[i - 1].date
                }
                currentCount = 1
                currentStart = messages[i].date
            } else {
                currentCount += 1
            }
        }

        // Check last conversation
        if currentCount > bestCount {
            bestCount = currentCount
            bestStart = currentStart
            bestEnd = messages.last!.date
        }

        guard bestCount > 0 else { return nil }

        let startDate = cocoaDate(bestStart)
        let endDate = cocoaDate(bestEnd)
        let duration = endDate.timeIntervalSince(startDate)

        return ConversationInfo(
            messageCount: bestCount,
            duration: duration,
            startDate: startDate,
            endDate: endDate
        )
    }

    private func fetchFirstMessage(handleRowId: Int64) throws -> MessagePreview? {
        let sql = """
            SELECT text, date, is_from_me FROM message
            WHERE handle_id = ?
            AND date > 0
            AND text IS NOT NULL
            AND text != ''
            ORDER BY date ASC
            LIMIT 1
        """
        let results: [MessagePreview] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            MessagePreview(
                text: columnText(stmt, 0),
                date: cocoaDate(sqlite3_column_int64(stmt, 1)),
                isFromUser: sqlite3_column_int(stmt, 2) == 1
            )
        }
        return results.first
    }

    private func countEditedMessages(handleRowId: Int64) throws -> Int {
        // In iMessage, edited messages have a non-null message_summary_info
        // and the edit history is tracked
        let sql = """
            SELECT COUNT(*) FROM message
            WHERE handle_id = ?
            AND is_from_me = 1
            AND message_summary_info IS NOT NULL
            AND length(message_summary_info) > 0
        """
        let results: [Int] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            Int(sqlite3_column_int(stmt, 0))
        }
        return results.first ?? 0
    }

    private func countUnsentMessages(handleRowId: Int64) throws -> Int {
        // Unsent messages in iMessage have date_retracted set
        let sql = """
            SELECT COUNT(*) FROM message
            WHERE handle_id = ?
            AND is_from_me = 1
            AND date_retracted > 0
        """
        let results: [Int] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            Int(sqlite3_column_int(stmt, 0))
        }
        return results.first ?? 0
    }

    private func fetchVoiceMessageStats(handleRowId: Int64) throws -> VoiceMessageStats? {
        // Voice messages are stored as attachments with mime_type 'audio/amr'
        // or uti 'com.apple.coreaudio-format' in the attachment table
        let sql = """
            SELECT
                m.is_from_me,
                a.total_bytes,
                COALESCE(a.transfer_name, '') as filename
            FROM message m
            JOIN message_attachment_join maj ON maj.message_id = m.ROWID
            JOIN attachment a ON a.ROWID = maj.attachment_id
            WHERE m.handle_id = ?
            AND (
                a.mime_type LIKE 'audio/%'
                OR a.uti = 'com.apple.coreaudio-format'
                OR a.transfer_name LIKE '%.caf'
                OR a.transfer_name LIKE '%.amr'
            )
        """
        let results: [(isFromMe: Bool, bytes: Int64, filename: String)] = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, handleRowId)
        }) { stmt in
            (
                sqlite3_column_int(stmt, 0) == 1,
                sqlite3_column_int64(stmt, 1),
                columnText(stmt, 2)
            )
        }

        guard !results.isEmpty else { return nil }

        let sent = results.filter { $0.isFromMe }.count
        let received = results.filter { !$0.isFromMe }.count

        // Estimate duration from file size (~1600 bytes/second for AMR audio)
        let bytesPerSecond: Double = 1600
        let durations = results.map { Double($0.bytes) / bytesPerSecond }
        let totalDuration = durations.reduce(0, +)
        let avgDuration = totalDuration / Double(results.count)
        let longestDuration = durations.max() ?? 0

        return VoiceMessageStats(
            sentCount: sent,
            receivedCount: received,
            totalDuration: totalDuration,
            averageDuration: avgDuration,
            longestDuration: longestDuration,
            contactPhoneNumber: nil
        )
    }

    // MARK: - SQLite Utilities

    private func query<T>(_ sql: String, bind: ((OpaquePointer) -> Void)? = nil, map: (OpaquePointer) -> T) throws -> [T] {
        guard let db else { throw DatabaseError.notConnected }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.queryFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        bind?(stmt!)

        var results: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(map(stmt!))
        }
        return results
    }

    private func columnText(_ stmt: OpaquePointer, _ index: Int32) -> String {
        guard let cString = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: cString)
    }

    /// Convert iMessage nanoseconds-since-2001 to Date
    private func cocoaDate(_ nanoseconds: Int64) -> Date {
        let seconds = TimeInterval(nanoseconds) / 1_000_000_000
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}

enum DatabaseError: LocalizedError {
    case fileNotFound(String)
    case cannotOpen(String)
    case notConnected
    case queryFailed(String)
    case invalidHandle

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): return "Database not found at \(path). Enable Full Disk Access."
        case .cannotOpen(let msg): return "Cannot open database: \(msg)"
        case .notConnected: return "Database not connected. Call open() first."
        case .queryFailed(let msg): return "Query failed: \(msg)"
        case .invalidHandle: return "Invalid contact handle ID."
        }
    }
}

import Foundation
import SQLite3

/// Reads call history from the macOS CallHistory database.
/// Located at ~/Library/Application Support/CallHistoryDB/CallHistory.storedata
/// Requires Full Disk Access permission.
final class CallLogService {
    private let dbPath: String
    private var db: OpaquePointer?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = "\(home)/Library/Application Support/CallHistoryDB/CallHistory.storedata"
    }

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

    /// Fetch comprehensive call stats for a phone number
    func fetchCallStats(phoneNumber: String) throws -> CallStats {
        guard let db else { throw DatabaseError.notConnected }

        let normalized = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let lastDigits = String(normalized.suffix(10))

        // Fetch all call records with full detail
        let sql = """
            SELECT
                ZDURATION,
                ZDATE,
                ZANSWERED,
                ZORIGINATED,
                ZCALLTYPE,
                ZSERVICE_PROVIDER
            FROM ZCALLRECORD
            WHERE ZADDRESS LIKE ?
            ORDER BY ZDATE ASC
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return emptyCallStats(contactId: phoneNumber)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, "%\(lastDigits)%", -1, nil)

        var totalDuration: TimeInterval = 0
        var totalCalls = 0
        var answeredCalls = 0
        var lastAnswered: Date?
        var monthlyData: [String: (minutes: Double, calls: Int)] = [:]

        var callRecords: [CallRecord] = []
        var hourlyBuckets: [String: Int] = [:]  // "day-hour" -> count

        // Missed stats
        var youMissed = 0      // incoming unanswered
        var theyMissed = 0     // outgoing unanswered
        var incomingTotal = 0
        var outgoingTotal = 0
        var incomingAnswered = 0
        var outgoingAnswered = 0
        var currentMissedStreak = 0
        var longestMissedStreak = 0

        // FaceTime stats
        var ftVideoCount = 0
        var ftAudioCount = 0
        var regularCount = 0
        var ftVideoDuration: TimeInterval = 0
        var ftAudioDuration: TimeInterval = 0
        var regularDuration: TimeInterval = 0
        var lastFaceTime: Date?

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let calendar = Calendar.current

        while sqlite3_step(stmt) == SQLITE_ROW {
            totalCalls += 1
            let duration = sqlite3_column_double(stmt, 0)
            let timestamp = sqlite3_column_double(stmt, 1)
            let answered = sqlite3_column_int(stmt, 2) == 1
            let originated = sqlite3_column_int(stmt, 3) == 1
            let callType = sqlite3_column_int(stmt, 4)
            let provider = columnText(stmt, 5)

            let date = Date(timeIntervalSinceReferenceDate: timestamp)
            let direction: CallRecord.CallDirection = originated ? .outgoing : .incoming

            // Determine call type (FaceTime video=1, FaceTime audio=8, regular=0/16)
            let recordType: CallRecord.CallType
            let isFaceTime = provider.lowercased().contains("facetime") || callType == 1 || callType == 8
            if isFaceTime {
                if callType == 1 {
                    recordType = .faceTimeVideo
                } else {
                    recordType = .faceTimeAudio
                }
            } else {
                recordType = .audio
            }

            // Build call record
            callRecords.append(CallRecord(
                date: date,
                duration: duration,
                type: recordType,
                direction: direction,
                answered: answered
            ))

            // Aggregate monthly
            if answered {
                answeredCalls += 1
                totalDuration += duration
                lastAnswered = date
            }

            let monthKey = monthFormatter.string(from: date)
            let existing = monthlyData[monthKey] ?? (0, 0)
            monthlyData[monthKey] = (existing.minutes + duration / 60, existing.calls + 1)

            // Hourly pattern
            let dayOfWeek = calendar.component(.weekday, from: date)
            let hour = calendar.component(.hour, from: date)
            let bucketKey = "\(dayOfWeek)-\(hour)"
            hourlyBuckets[bucketKey, default: 0] += 1

            // Missed stats
            if originated {
                outgoingTotal += 1
                if answered {
                    outgoingAnswered += 1
                    currentMissedStreak = 0
                } else {
                    theyMissed += 1
                    currentMissedStreak += 1
                    longestMissedStreak = max(longestMissedStreak, currentMissedStreak)
                }
            } else {
                incomingTotal += 1
                if answered {
                    incomingAnswered += 1
                    currentMissedStreak = 0
                } else {
                    youMissed += 1
                    currentMissedStreak += 1
                    longestMissedStreak = max(longestMissedStreak, currentMissedStreak)
                }
            }

            // FaceTime stats
            switch recordType {
            case .faceTimeVideo:
                ftVideoCount += 1
                ftVideoDuration += duration
                if answered { lastFaceTime = date }
            case .faceTimeAudio:
                ftAudioCount += 1
                ftAudioDuration += duration
                if answered { lastFaceTime = date }
            case .audio:
                regularCount += 1
                regularDuration += duration
            }
        }

        let avgDuration = answeredCalls > 0 ? totalDuration / Double(answeredCalls) : 0

        let months = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
        let monthlyCallData = months.enumerated().map { index, month in
            let data = monthlyData[month]
            let year = index < 9 ? 2025 : 2026
            return MonthlyCallData(
                month: month,
                year: year,
                totalMinutes: data?.minutes ?? 0,
                callCount: data?.calls ?? 0
            )
        }

        // Build hourly pattern
        var hourlyCallPattern: [HourlyCallData] = []
        for day in 1...7 {
            for hour in 0..<24 {
                let count = hourlyBuckets["\(day)-\(hour)"] ?? 0
                hourlyCallPattern.append(HourlyCallData(hour: hour, callCount: count, dayOfWeek: day))
            }
        }

        let yourAnswerRate = incomingTotal > 0 ? Double(incomingAnswered) / Double(incomingTotal) * 100 : 100
        let theirAnswerRate = outgoingTotal > 0 ? Double(outgoingAnswered) / Double(outgoingTotal) * 100 : 100

        return CallStats(
            contactId: phoneNumber,
            totalCallTime: totalDuration,
            totalCalls: totalCalls,
            answeredCalls: answeredCalls,
            averageCallDuration: avgDuration,
            lastAnsweredDate: lastAnswered,
            monthlyCallData: monthlyCallData,
            callRecords: callRecords.sorted { $0.date > $1.date },
            hourlyCallPattern: hourlyCallPattern,
            missedStats: MissedCallStats(
                youMissed: youMissed,
                theyMissed: theyMissed,
                totalMissed: youMissed + theyMissed,
                totalAnswered: answeredCalls,
                yourAnswerRate: yourAnswerRate,
                theirAnswerRate: theirAnswerRate,
                longestUnansweredStreak: longestMissedStreak
            ),
            faceTimeStats: FaceTimeStats(
                videoCallCount: ftVideoCount,
                audioCallCount: ftAudioCount,
                regularCallCount: regularCount,
                videoTotalDuration: ftVideoDuration,
                audioFTDuration: ftAudioDuration,
                regularDuration: regularDuration,
                lastFaceTimeDate: lastFaceTime
            )
        )
    }

    private func columnText(_ stmt: OpaquePointer, _ index: Int32) -> String {
        guard let cString = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: cString)
    }

    private func emptyCallStats(contactId: String) -> CallStats {
        CallStats(
            contactId: contactId,
            totalCallTime: 0,
            totalCalls: 0,
            answeredCalls: 0,
            averageCallDuration: 0,
            lastAnsweredDate: nil,
            monthlyCallData: [],
            callRecords: [],
            hourlyCallPattern: [],
            missedStats: MissedCallStats(
                youMissed: 0, theyMissed: 0, totalMissed: 0,
                totalAnswered: 0, yourAnswerRate: 100, theirAnswerRate: 100,
                longestUnansweredStreak: 0
            ),
            faceTimeStats: FaceTimeStats(
                videoCallCount: 0, audioCallCount: 0, regularCallCount: 0,
                videoTotalDuration: 0, audioFTDuration: 0, regularDuration: 0,
                lastFaceTimeDate: nil
            )
        )
    }
}

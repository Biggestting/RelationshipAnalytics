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

    /// Fetch call stats for a phone number
    func fetchCallStats(phoneNumber: String) throws -> CallStats {
        guard let db else { throw DatabaseError.notConnected }

        // Normalize phone number for matching
        let normalized = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let lastDigits = String(normalized.suffix(10))

        let sql = """
            SELECT
                ZDURATION,
                ZDATE,
                ZANSWERED,
                ZORIGINATED
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

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        while sqlite3_step(stmt) == SQLITE_ROW {
            totalCalls += 1
            let duration = sqlite3_column_double(stmt, 0)
            let timestamp = sqlite3_column_double(stmt, 1)
            let answered = sqlite3_column_int(stmt, 2) == 1

            // Core Data timestamps are seconds since 2001-01-01
            let date = Date(timeIntervalSinceReferenceDate: timestamp)

            if answered {
                answeredCalls += 1
                totalDuration += duration
                lastAnswered = date
            }

            let monthKey = monthFormatter.string(from: date)
            let existing = monthlyData[monthKey] ?? (0, 0)
            monthlyData[monthKey] = (existing.minutes + duration / 60, existing.calls + 1)
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

        return CallStats(
            contactId: phoneNumber,
            totalCallTime: totalDuration,
            totalCalls: totalCalls,
            answeredCalls: answeredCalls,
            averageCallDuration: avgDuration,
            lastAnsweredDate: lastAnswered,
            monthlyCallData: monthlyCallData
        )
    }

    private func emptyCallStats(contactId: String) -> CallStats {
        CallStats(
            contactId: contactId,
            totalCallTime: 0,
            totalCalls: 0,
            answeredCalls: 0,
            averageCallDuration: 0,
            lastAnsweredDate: nil,
            monthlyCallData: []
        )
    }
}

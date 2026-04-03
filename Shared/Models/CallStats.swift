import Foundation

struct CallStats: Codable {
    let contactId: String
    let totalCallTime: TimeInterval
    let totalCalls: Int
    let answeredCalls: Int
    let averageCallDuration: TimeInterval
    let lastAnsweredDate: Date?
    let monthlyCallData: [MonthlyCallData]

    // New detailed stats
    let callRecords: [CallRecord]
    let hourlyCallPattern: [HourlyCallData]
    let missedStats: MissedCallStats
    let faceTimeStats: FaceTimeStats

    var totalCallTimeFormatted: String {
        let minutes = Int(totalCallTime) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }

    var averageCallFormatted: String {
        let minutes = Int(averageCallDuration) / 60
        return "\(minutes)m"
    }

    var lastAnsweredFormatted: String? {
        guard let date = lastAnsweredDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Last answered \(formatter.string(from: date))"
    }
}

struct MonthlyCallData: Codable, Identifiable {
    var id: String { month }
    let month: String
    let year: Int
    let totalMinutes: Double
    let callCount: Int
}

// MARK: - Individual Call Record

struct CallRecord: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(type.rawValue)" }
    let date: Date
    let duration: TimeInterval
    let type: CallType
    let direction: CallDirection
    let answered: Bool

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    enum CallType: String, Codable {
        case audio
        case faceTimeVideo
        case faceTimeAudio
    }

    enum CallDirection: String, Codable {
        case incoming
        case outgoing
    }
}

// MARK: - Hourly Call Pattern

struct HourlyCallData: Codable, Identifiable {
    var id: Int { hour }
    let hour: Int       // 0-23
    let callCount: Int
    let dayOfWeek: Int  // 1=Sun, 7=Sat

    var hourLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "A" : "P"
        return "\(h)\(ampm)"
    }

    var intensity: Int {
        switch callCount {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }
}

// MARK: - Missed Call Stats

struct MissedCallStats: Codable {
    let youMissed: Int
    let theyMissed: Int
    let totalMissed: Int
    let totalAnswered: Int
    let yourAnswerRate: Double     // 0-100
    let theirAnswerRate: Double    // 0-100
    let longestUnansweredStreak: Int

    var yourAnswerRateFormatted: String {
        "\(Int(yourAnswerRate))%"
    }

    var theirAnswerRateFormatted: String {
        "\(Int(theirAnswerRate))%"
    }
}

// MARK: - FaceTime Stats

struct FaceTimeStats: Codable {
    let videoCallCount: Int
    let audioCallCount: Int
    let regularCallCount: Int
    let videoTotalDuration: TimeInterval
    let audioFTDuration: TimeInterval
    let regularDuration: TimeInterval
    let lastFaceTimeDate: Date?

    var totalFaceTimeCalls: Int { videoCallCount + audioCallCount }

    var videoDurationFormatted: String {
        formatDuration(videoTotalDuration)
    }

    var audioFTDurationFormatted: String {
        formatDuration(audioFTDuration)
    }

    var regularDurationFormatted: String {
        formatDuration(regularDuration)
    }

    var lastFaceTimeFormatted: String? {
        guard let date = lastFaceTimeDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

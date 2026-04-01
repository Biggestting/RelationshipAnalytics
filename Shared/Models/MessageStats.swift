import Foundation

struct MessageStats: Codable {
    let contactId: String
    let totalSent: Int
    let totalReceived: Int
    let totalMessages: Int
    let messageActivity: [DayActivity]
    let activeStreak: Int
    let bestStreak: Int
    let youStartPercentage: Double
    let yourReplyTime: TimeInterval
    let theirReplyTime: TimeInterval
    let longestConvo: ConversationInfo?
    let firstMessageSent: MessagePreview?
    let firstMessageReceived: MessagePreview?

    var sentPercentage: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(totalSent) / Double(totalMessages) * 100
    }

    var receivedPercentage: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(totalReceived) / Double(totalMessages) * 100
    }

    var yourReplyTimeFormatted: String {
        formatDuration(yourReplyTime)
    }

    var theirReplyTimeFormatted: String {
        formatDuration(theirReplyTime)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DayActivity: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }
    let date: Date
    let count: Int

    var intensity: Int {
        switch count {
        case 0: return 0
        case 1...3: return 1
        case 4...7: return 2
        case 8...15: return 3
        default: return 4
        }
    }
}

struct ConversationInfo: Codable {
    let messageCount: Int
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return "\(hours)h \(minutes)m"
    }

    var dateRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = ", yyyy"
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate) + yearFormatter.string(from: endDate)
        return "\(start)-\(end)"
    }
}

struct MessagePreview: Codable {
    let text: String
    let date: Date
    let isFromUser: Bool
}

import Foundation

struct CallStats: Codable {
    let contactId: String
    let totalCallTime: TimeInterval
    let totalCalls: Int
    let answeredCalls: Int
    let averageCallDuration: TimeInterval
    let lastAnsweredDate: Date?
    let monthlyCallData: [MonthlyCallData]

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

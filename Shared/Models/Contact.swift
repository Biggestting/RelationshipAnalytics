import Foundation

struct ContactProfile: Identifiable, Codable {
    let id: String
    let name: String
    let initials: String
    let talkingSince: Date
    let phoneNumber: String?
    let email: String?

    var talkingSinceFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Talking since \(formatter.string(from: talkingSince))"
    }

    var talkingDuration: String {
        let components = Calendar.current.dateComponents([.year, .month], from: talkingSince, to: Date())
        if let years = components.year, years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else if let months = components.month {
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        return "this year"
    }
}

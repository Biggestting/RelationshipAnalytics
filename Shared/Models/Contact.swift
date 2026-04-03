import Foundation

struct ContactIdentifier: Codable, Identifiable, Hashable {
    var id: String { value }
    let value: String
    let type: IdentifierType
    let label: String?         // "Personal", "Work", "Old Number", etc.
    let addedDate: Date

    enum IdentifierType: String, Codable {
        case phone
        case email
        case whatsapp
        case instagram
        case twitter
    }

    var displayValue: String {
        value
    }

    var icon: String {
        switch type {
        case .phone: return "phone.fill"
        case .email: return "envelope.fill"
        case .whatsapp: return "bubble.left.fill"
        case .instagram: return "camera.fill"
        case .twitter: return "at"
        }
    }
}

struct ContactProfile: Identifiable, Codable {
    let id: String
    var name: String
    var initials: String
    let talkingSince: Date
    var identifiers: [ContactIdentifier]

    // Convenience accessors
    var phoneNumber: String? {
        identifiers.first(where: { $0.type == .phone })?.value
    }

    var email: String? {
        identifiers.first(where: { $0.type == .email })?.value
    }

    var phoneNumbers: [ContactIdentifier] {
        identifiers.filter { $0.type == .phone }
    }

    var allIdentifiersSummary: String {
        let phones = phoneNumbers
        if phones.count > 1 {
            return "\(phones.count) NUMBERS"
        } else if let first = phones.first {
            return first.value
        } else if let email = email {
            return email
        }
        return ""
    }

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

    // MARK: - Persistence for linked identifiers

    static func saveLinkedIdentifiers(_ identifiers: [ContactIdentifier], forContactId contactId: String) {
        if let data = try? JSONEncoder().encode(identifiers) {
            UserDefaults.standard.set(data, forKey: "identifiers_\(contactId)")
        }
    }

    static func loadLinkedIdentifiers(forContactId contactId: String) -> [ContactIdentifier]? {
        guard let data = UserDefaults.standard.data(forKey: "identifiers_\(contactId)"),
              let identifiers = try? JSONDecoder().decode([ContactIdentifier].self, from: data) else {
            return nil
        }
        return identifiers.isEmpty ? nil : identifiers
    }
}

import Foundation

struct ContactNote: Identifiable, Codable {
    let id: String
    let contactId: String
    let text: String
    let createdAt: Date
    let updatedAt: Date

    init(id: String = UUID().uuidString, contactId: String, text: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.contactId = contactId
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

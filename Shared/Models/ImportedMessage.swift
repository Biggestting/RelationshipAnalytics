import Foundation

/// A normalized message from any platform import
struct ImportedMessage: Codable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(sender)" }
    let date: Date
    let sender: String
    let text: String
    let isFromUser: Bool
    let platform: ChatPlatform
    let isEdited: Bool
    let isUnsent: Bool
    let isVoiceMessage: Bool
    let voiceDuration: TimeInterval?
    let isMedia: Bool
    let mediaType: String?   // "image", "video", "sticker", "gif", etc.
}

enum ChatPlatform: String, Codable, CaseIterable {
    case whatsapp = "WHATSAPP"
    case messenger = "MESSENGER"
    case instagram = "INSTAGRAM"
    case twitter = "TWITTER/X"
    case imessage = "IMESSAGE"

    var iconName: String {
        switch self {
        case .whatsapp: return "bubble.left.fill"
        case .messenger: return "message.fill"
        case .instagram: return "camera.fill"
        case .twitter: return "at"
        case .imessage: return "bubble.left.and.bubble.right.fill"
        }
    }
}

/// Result from parsing an export file
struct ImportResult: Codable {
    let platform: ChatPlatform
    let contactName: String
    let messages: [ImportedMessage]
    let importDate: Date
    let sourceFileName: String

    var totalMessages: Int { messages.count }
    var sentCount: Int { messages.filter { $0.isFromUser }.count }
    var receivedCount: Int { messages.filter { !$0.isFromUser }.count }
    var editedCount: Int { messages.filter { $0.isEdited }.count }
    var unsentCount: Int { messages.filter { $0.isUnsent }.count }
    var voiceCount: Int { messages.filter { $0.isVoiceMessage }.count }
    var mediaCount: Int { messages.filter { $0.isMedia }.count }

    var dateRange: (start: Date, end: Date)? {
        guard let first = messages.first?.date, let last = messages.last?.date else { return nil }
        return (first, last)
    }
}

/// Protocol for all platform parsers
protocol ChatExportParser {
    var platform: ChatPlatform { get }
    func parse(data: Data, fileName: String, userName: String) throws -> ImportResult
}

enum ImportError: LocalizedError {
    case invalidFormat(String)
    case emptyFile
    case noMessagesFound
    case unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail): return "Invalid format: \(detail)"
        case .emptyFile: return "The file is empty."
        case .noMessagesFound: return "No messages found in this file."
        case .unsupportedEncoding: return "Unsupported text encoding."
        }
    }
}

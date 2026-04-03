import Foundation

/// Parses Facebook Messenger JSON export
///
/// Facebook export structure (Download Your Information > Messages > JSON):
///   messages/inbox/contactname_hash/message_1.json
///
/// JSON structure:
/// {
///   "participants": [{"name": "You"}, {"name": "Contact"}],
///   "messages": [
///     {
///       "sender_name": "Contact",
///       "timestamp_ms": 1705363200000,
///       "content": "Hey!",
///       "type": "Generic",
///       "is_unsent": false
///     }
///   ]
/// }
struct MessengerParser: ChatExportParser {
    let platform = ChatPlatform.messenger

    func parse(data: Data, fileName: String, userName: String) throws -> ImportResult {
        guard !data.isEmpty else { throw ImportError.emptyFile }

        let json: MessengerExport
        do {
            json = try JSONDecoder().decode(MessengerExport.self, from: data)
        } catch {
            throw ImportError.invalidFormat("Not a valid Messenger JSON export: \(error.localizedDescription)")
        }

        let contactName = json.participants
            .map { fixEncoding($0.name) }
            .first { $0.lowercased() != userName.lowercased() } ?? "Unknown"

        var messages: [ImportedMessage] = []

        for msg in json.messages {
            let sender = fixEncoding(msg.sender_name)
            let isFromUser = sender.lowercased() == userName.lowercased()
            let text = msg.content.map { fixEncoding($0) } ?? ""
            let date = Date(timeIntervalSince1970: TimeInterval(msg.timestamp_ms) / 1000)

            let isVoice = msg.type == "Audio" || (msg.audio_files?.isEmpty == false)
            let isMedia = msg.type == "Photo" || msg.type == "Video"
                || msg.type == "Sticker" || msg.type == "GIF"
                || (msg.photos?.isEmpty == false)
                || (msg.videos?.isEmpty == false)

            let mediaType: String? = {
                if msg.photos?.isEmpty == false { return "image" }
                if msg.videos?.isEmpty == false { return "video" }
                if msg.type == "Sticker" { return "sticker" }
                if msg.type == "GIF" { return "gif" }
                return nil
            }()

            messages.append(ImportedMessage(
                date: date,
                sender: sender,
                text: text,
                isFromUser: isFromUser,
                platform: .messenger,
                isEdited: false,
                isUnsent: msg.is_unsent ?? false,
                isVoiceMessage: isVoice,
                voiceDuration: nil,
                isMedia: isMedia || isVoice,
                mediaType: isVoice ? "audio" : mediaType
            ))
        }

        guard !messages.isEmpty else { throw ImportError.noMessagesFound }

        return ImportResult(
            platform: .messenger,
            contactName: contactName,
            messages: messages.sorted { $0.date < $1.date },
            importDate: Date(),
            sourceFileName: fileName
        )
    }

    /// Facebook exports use mojibake encoding — fix common issues
    private func fixEncoding(_ string: String) -> String {
        guard let data = string.data(using: .windowsCP1252) else { return string }
        return String(data: data, encoding: .utf8) ?? string
    }
}

// MARK: - Messenger JSON structures

private struct MessengerExport: Decodable {
    let participants: [Participant]
    let messages: [Message]

    struct Participant: Decodable {
        let name: String
    }

    struct Message: Decodable {
        let sender_name: String
        let timestamp_ms: Int64
        let content: String?
        let type: String?
        let is_unsent: Bool?
        let photos: [MediaItem]?
        let videos: [MediaItem]?
        let audio_files: [MediaItem]?
    }

    struct MediaItem: Decodable {
        let uri: String?
    }
}

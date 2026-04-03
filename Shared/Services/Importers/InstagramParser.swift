import Foundation

/// Parses Instagram DM JSON export
///
/// Instagram export structure (Download Your Information > Messages > JSON):
///   messages/inbox/contactname_date/message_1.json
///
/// JSON structure (similar to Messenger):
/// {
///   "participants": [{"name": "you"}, {"name": "contact"}],
///   "messages": [
///     {
///       "sender_name": "contact",
///       "timestamp_ms": 1705363200000,
///       "content": "Hey!",
///       "type": "Generic",
///       "is_unsent": false,
///       "share": {"link": "..."}
///     }
///   ]
/// }
struct InstagramParser: ChatExportParser {
    let platform = ChatPlatform.instagram

    func parse(data: Data, fileName: String, userName: String) throws -> ImportResult {
        guard !data.isEmpty else { throw ImportError.emptyFile }

        let json: InstagramExport
        do {
            json = try JSONDecoder().decode(InstagramExport.self, from: data)
        } catch {
            throw ImportError.invalidFormat("Not a valid Instagram JSON export: \(error.localizedDescription)")
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

            let isVoice = msg.audio_files?.isEmpty == false
            let isMedia = msg.photos?.isEmpty == false
                || msg.videos?.isEmpty == false
                || msg.share != nil

            let mediaType: String? = {
                if msg.photos?.isEmpty == false { return "image" }
                if msg.videos?.isEmpty == false { return "video" }
                if msg.share != nil { return "share" }
                return nil
            }()

            messages.append(ImportedMessage(
                date: date,
                sender: sender,
                text: text,
                isFromUser: isFromUser,
                platform: .instagram,
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
            platform: .instagram,
            contactName: contactName,
            messages: messages.sorted { $0.date < $1.date },
            importDate: Date(),
            sourceFileName: fileName
        )
    }

    private func fixEncoding(_ string: String) -> String {
        guard let data = string.data(using: .windowsCP1252) else { return string }
        return String(data: data, encoding: .utf8) ?? string
    }
}

// MARK: - Instagram JSON structures

private struct InstagramExport: Decodable {
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
        let share: ShareItem?
    }

    struct MediaItem: Decodable {
        let uri: String?
    }

    struct ShareItem: Decodable {
        let link: String?
    }
}

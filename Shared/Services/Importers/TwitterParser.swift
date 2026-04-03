import Foundation

/// Parses Twitter/X DM archive
///
/// Twitter data export structure (Settings > Your Account > Download Archive):
///   data/direct-messages.js
///
/// The .js file starts with: window.YTD.direct_messages.part0 = [...]
/// After stripping the prefix, it's a JSON array of conversations:
/// [
///   {
///     "dmConversation": {
///       "conversationId": "...",
///       "messages": [
///         {
///           "messageCreate": {
///             "id": "...",
///             "senderId": "123456",
///             "text": "Hey!",
///             "createdAt": "2025-01-15T21:00:00.000Z",
///             "mediaUrls": []
///           }
///         }
///       ]
///     }
///   }
/// ]
struct TwitterParser: ChatExportParser {
    let platform = ChatPlatform.twitter

    func parse(data: Data, fileName: String, userName: String) throws -> ImportResult {
        guard !data.isEmpty else { throw ImportError.emptyFile }

        guard var text = String(data: data, encoding: .utf8) else {
            throw ImportError.unsupportedEncoding
        }

        // Strip the JS variable assignment prefix
        if let equalsIndex = text.firstIndex(of: "=") {
            text = String(text[text.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)
        }

        // Remove trailing semicolons
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: ";").union(.whitespaces))

        guard let jsonData = text.data(using: .utf8) else {
            throw ImportError.unsupportedEncoding
        }

        let conversations: [TwitterConversation]
        do {
            conversations = try JSONDecoder().decode([TwitterConversation].self, from: jsonData)
        } catch {
            throw ImportError.invalidFormat("Not a valid Twitter DM archive: \(error.localizedDescription)")
        }

        // Find the first 1-on-1 conversation (not group)
        guard let convo = conversations.first(where: { $0.dmConversation.conversationId.contains("-") }) ?? conversations.first else {
            throw ImportError.noMessagesFound
        }

        var messages: [ImportedMessage] = []
        var senderNames: [String: Int] = [:]

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        for wrapper in convo.dmConversation.messages {
            guard let msg = wrapper.messageCreate else { continue }

            let date = dateFormatter.date(from: msg.createdAt)
                ?? fallbackFormatter.date(from: msg.createdAt)
                ?? Date()

            let senderId = msg.senderId
            senderNames[senderId, default: 0] += 1

            let hasMedia = !(msg.mediaUrls?.isEmpty ?? true)
                || msg.text.contains("https://t.co/")

            messages.append(ImportedMessage(
                date: date,
                sender: senderId,
                text: msg.text,
                isFromUser: false, // will fix below
                platform: .twitter,
                isEdited: false,
                isUnsent: false,
                isVoiceMessage: false,
                voiceDuration: nil,
                isMedia: hasMedia,
                mediaType: hasMedia ? "link" : nil
            ))
        }

        guard !messages.isEmpty else { throw ImportError.noMessagesFound }

        // The sender with the most messages is likely the user
        // OR match against userName if provided
        let sortedSenders = senderNames.sorted { $0.value > $1.value }
        let userSenderId: String
        if let match = sortedSenders.first(where: { $0.key == userName }) {
            userSenderId = match.key
        } else {
            userSenderId = sortedSenders.first?.key ?? ""
        }

        let contactSenderId = sortedSenders.first(where: { $0.key != userSenderId })?.key ?? "Unknown"

        // Fix isFromUser flag
        messages = messages.map { msg in
            ImportedMessage(
                date: msg.date,
                sender: msg.sender,
                text: msg.text,
                isFromUser: msg.sender == userSenderId,
                platform: .twitter,
                isEdited: msg.isEdited,
                isUnsent: msg.isUnsent,
                isVoiceMessage: msg.isVoiceMessage,
                voiceDuration: msg.voiceDuration,
                isMedia: msg.isMedia,
                mediaType: msg.mediaType
            )
        }

        return ImportResult(
            platform: .twitter,
            contactName: contactSenderId,
            messages: messages.sorted { $0.date < $1.date },
            importDate: Date(),
            sourceFileName: fileName
        )
    }
}

// MARK: - Twitter JSON structures

private struct TwitterConversation: Decodable {
    let dmConversation: DMConversation

    struct DMConversation: Decodable {
        let conversationId: String
        let messages: [MessageWrapper]
    }

    struct MessageWrapper: Decodable {
        let messageCreate: MessageCreate?
    }

    struct MessageCreate: Decodable {
        let id: String?
        let senderId: String
        let text: String
        let createdAt: String
        let mediaUrls: [String]?
    }
}

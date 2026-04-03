import Foundation

/// Parses WhatsApp chat export .txt files
///
/// WhatsApp export format (varies by locale):
///   [1/15/25, 9:41:32 PM] John: Hey what's up
///   [1/15/25, 9:42:10 PM] You: Not much!
///   [1/15/25, 9:43:00 PM] John: <Media omitted>
///   [1/15/25, 9:44:00 PM] You: This message was deleted
///
/// Also supports:
///   1/15/25, 9:41 PM - John: Hey what's up
struct WhatsAppParser: ChatExportParser {
    let platform = ChatPlatform.whatsapp

    // Patterns for WhatsApp timestamp formats
    private let patterns: [String] = [
        // [M/d/yy, h:mm:ss a] Name: Message
        #"\[(\d{1,2}/\d{1,2}/\d{2,4},\s*\d{1,2}:\d{2}(?::\d{2})?\s*[AaPp][Mm])\]\s*([^:]+):\s*(.*)"#,
        // M/d/yy, h:mm a - Name: Message
        #"(\d{1,2}/\d{1,2}/\d{2,4},\s*\d{1,2}:\d{2}(?::\d{2})?\s*[AaPp][Mm])\s*-\s*([^:]+):\s*(.*)"#,
        // dd/MM/yyyy, HH:mm - Name: Message (24h format)
        #"(\d{1,2}/\d{1,2}/\d{2,4},\s*\d{1,2}:\d{2})\s*-\s*([^:]+):\s*(.*)"#,
    ]

    private let dateFormats: [String] = [
        "M/d/yy, h:mm:ss a",
        "M/d/yy, h:mm a",
        "M/d/yyyy, h:mm:ss a",
        "M/d/yyyy, h:mm a",
        "dd/MM/yyyy, HH:mm",
        "dd/MM/yy, HH:mm",
    ]

    func parse(data: Data, fileName: String, userName: String) throws -> ImportResult {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ImportError.unsupportedEncoding
        }

        guard !text.isEmpty else { throw ImportError.emptyFile }

        let lines = text.components(separatedBy: .newlines)
        var messages: [ImportedMessage] = []
        var contactName = ""

        for line in lines {
            guard let parsed = parseLine(line) else { continue }

            let isFromUser = parsed.sender.lowercased() == userName.lowercased()
                || parsed.sender.lowercased() == "you"

            if !isFromUser && contactName.isEmpty {
                contactName = parsed.sender
            }

            let isUnsent = parsed.text.contains("This message was deleted")
                || parsed.text.contains("You deleted this message")
            let isMedia = parsed.text.contains("<Media omitted>")
                || parsed.text.contains("image omitted")
                || parsed.text.contains("video omitted")
                || parsed.text.contains("sticker omitted")
                || parsed.text.contains("GIF omitted")
            let isVoice = parsed.text.contains("audio omitted")
                || parsed.text.contains("<audio omitted>")
            let isEdited = parsed.text.hasSuffix("<This message was edited>")

            let mediaType: String? = {
                if parsed.text.contains("image") { return "image" }
                if parsed.text.contains("video") { return "video" }
                if parsed.text.contains("sticker") { return "sticker" }
                if parsed.text.contains("GIF") { return "gif" }
                return nil
            }()

            messages.append(ImportedMessage(
                date: parsed.date,
                sender: parsed.sender,
                text: isUnsent ? "" : parsed.text,
                isFromUser: isFromUser,
                platform: .whatsapp,
                isEdited: isEdited,
                isUnsent: isUnsent,
                isVoiceMessage: isVoice,
                voiceDuration: nil,
                isMedia: isMedia || isVoice,
                mediaType: isVoice ? "audio" : mediaType
            ))
        }

        guard !messages.isEmpty else { throw ImportError.noMessagesFound }

        return ImportResult(
            platform: .whatsapp,
            contactName: contactName.isEmpty ? "Unknown" : contactName,
            messages: messages.sorted { $0.date < $1.date },
            importDate: Date(),
            sourceFileName: fileName
        )
    }

    private func parseLine(_ line: String) -> (date: Date, sender: String, text: String)? {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  match.numberOfRanges >= 4 else { continue }

            let dateStr = String(line[Range(match.range(at: 1), in: line)!])
            let sender = String(line[Range(match.range(at: 2), in: line)!]).trimmingCharacters(in: .whitespaces)
            let text = String(line[Range(match.range(at: 3), in: line)!])

            if let date = parseDate(dateStr) {
                return (date, sender, text)
            }
        }
        return nil
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}

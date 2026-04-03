import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Generates a downloadable .shortcut plist file for one-tap installation.
/// The generated shortcut:
/// 1. Asks user to pick a contact
/// 2. Finds all messages with that contact
/// 3. Builds JSON from the messages
/// 4. Calls the ImportMessagesIntent via App Intent
///
/// Since .shortcut files are complex binary plists, we use a simpler approach:
/// Generate a Shortcuts URL that opens the Shortcuts app with pre-filled actions.
enum ShortcutBuilder {

    /// Opens Shortcuts app with the "Add Shortcut" gallery showing our App Shortcuts
    static func openAppShortcutsGallery() {
        #if canImport(UIKit)
        // Opens the Shortcuts app to our app's shortcuts section
        if let url = URL(string: "shortcuts://gallery/search?query=Relationship%20Analytics") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    /// Generate a shareable iCloud Shortcuts link content
    /// This creates the Shortcut definition as a dictionary that can be shared
    static func generateShortcutDefinition(contactName: String? = nil) -> [String: Any] {
        var actions: [[String: Any]] = []

        // Action 1: Ask for contact name if not provided
        if contactName == nil {
            actions.append([
                "WFWorkflowActionIdentifier": "is.workflow.actions.ask",
                "WFWorkflowActionParameters": [
                    "WFAskActionPrompt": "Enter the contact name to export messages from:",
                    "WFAskActionDefaultAnswer": "",
                ] as [String: Any]
            ])
        }

        // Action 2: Find Messages
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.filter.messages",
            "WFWorkflowActionParameters": [
                "WFContentItemSortProperty": "WFDateSentProperty",
                "WFContentItemSortOrder": "Oldest First",
            ] as [String: Any]
        ])

        // Action 3: Build JSON via Repeat
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.repeat.each",
            "WFWorkflowActionParameters": [:] as [String: Any]
        ])

        // Action 4: Text template for each message
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
            "WFWorkflowActionParameters": [
                "WFTextActionText": """
                {"sender":"${Repeat Item.Sender}","text":"${Repeat Item.Text}","date":"${Repeat Item.Date Sent}","is_from_me":${Repeat Item.Is From Me}}
                """
            ] as [String: Any]
        ])

        // Action 5: End repeat
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.repeat.each.end",
            "WFWorkflowActionParameters": [:] as [String: Any]
        ])

        // Action 6: Combine text
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.text.combine",
            "WFWorkflowActionParameters": [
                "WFTextSeparator": ","
            ] as [String: Any]
        ])

        // Action 7: Wrap in array brackets
        actions.append([
            "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
            "WFWorkflowActionParameters": [
                "WFTextActionText": "[${Combined Text}]"
            ] as [String: Any]
        ])

        // Action 8: Run Import Messages intent
        actions.append([
            "WFWorkflowActionIdentifier": "com.relationshipanalytics.ios.ImportMessagesIntent",
            "WFWorkflowActionParameters": [:] as [String: Any]
        ])

        return [
            "WFWorkflowActions": actions,
            "WFWorkflowName": "Export Messages to RA",
            "WFWorkflowMinimumClientVersion": 900,
            "WFWorkflowIcon": [
                "WFWorkflowIconStartColor": 4282601983,  // dark gray
                "WFWorkflowIconGlyphNumber": 59648,       // message bubble
            ] as [String: Any]
        ]
    }

    /// Save shortcut definition to a temp file and offer to share
    static func shareShortcut(from viewController: Any? = nil) {
        #if canImport(UIKit)
        let definition = generateShortcutDefinition()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Export Messages to RA.shortcut")

        // Write as binary plist
        if let data = try? PropertyListSerialization.data(
            fromPropertyList: definition,
            format: .binary,
            options: 0
        ) {
            try? data.write(to: tempURL)

            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                let presenter = rootVC.presentedViewController ?? rootVC
                activityVC.popoverPresentationController?.sourceView = presenter.view
                presenter.present(activityVC, animated: true)
            }
        }
        #endif
    }
}

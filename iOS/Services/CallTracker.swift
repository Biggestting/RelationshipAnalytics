import Foundation
import CallKit
import Contacts

/// Monitors phone calls in real-time using CXCallObserver.
/// Logs every call (incoming/outgoing, answered/missed, duration) to LiveDataStore.
/// Starts automatically on app launch and runs in the background.
final class CallTracker: NSObject, ObservableObject {
    static let shared = CallTracker()

    private let observer = CXCallObserver()
    private var activeCalls: [UUID: CallInfo] = [:]
    private let store = LiveDataStore.shared

    @Published var isTracking = false

    private override init() {
        super.init()
    }

    func startTracking() {
        observer.setDelegate(self, queue: .main)
        isTracking = true
    }

    func stopTracking() {
        isTracking = false
    }

    /// Resolve phone number to contact name
    private func resolveContactName(for phoneNumber: String) -> String? {
        let store = CNContactStore()
        let predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: phoneNumber))
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
        guard let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
              let contact = contacts.first else { return nil }
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }
}

extension CallTracker: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let callID = call.uuid

        if !call.hasEnded && !call.hasConnected && !call.isOnHold {
            // Call is ringing/dialing — start tracking
            activeCalls[callID] = CallInfo(
                startTime: Date(),
                isOutgoing: call.isOutgoing,
                hasConnected: false
            )
        }

        if call.hasConnected {
            // Call was answered
            activeCalls[callID]?.hasConnected = true
            activeCalls[callID]?.connectTime = Date()
        }

        if call.hasEnded {
            // Call ended — log it
            guard let info = activeCalls.removeValue(forKey: callID) else { return }

            let duration: TimeInterval
            if let connectTime = info.connectTime {
                duration = Date().timeIntervalSince(connectTime)
            } else {
                duration = 0
            }

            // Try to get the phone number from recent calls
            // CXCall doesn't directly expose the number, but we can check Contacts
            let phoneNumber = "Unknown"  // CXCall doesn't expose number directly
            let contactName = info.contactName

            let trackedCall = TrackedCall(
                phoneNumber: phoneNumber,
                contactName: contactName,
                date: info.startTime,
                duration: duration,
                wasIncoming: !info.isOutgoing,
                wasAnswered: info.hasConnected,
                isFaceTime: false  // CXCall doesn't distinguish FaceTime
            )

            store.logCall(trackedCall)

            // Post notification for UI updates
            NotificationCenter.default.post(name: .callTracked, object: trackedCall)
        }
    }
}

extension Notification.Name {
    static let callTracked = Notification.Name("callTracked")
    static let messageTracked = Notification.Name("messageTracked")
}

private struct CallInfo {
    let startTime: Date
    let isOutgoing: Bool
    var hasConnected: Bool
    var connectTime: Date?
    var contactName: String?
}

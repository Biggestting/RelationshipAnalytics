import Foundation
import Contacts

/// Resolves phone numbers and emails to contact names using the macOS Contacts framework.
final class ContactNameResolver {
    private let store = CNContactStore()
    private var cache: [String: String] = [:]

    init() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            preloadContacts()
        }
        // If .notDetermined, we skip — caller should request access separately
        // Never block with semaphore.wait() as it freezes the main thread
    }

    /// Request access and preload (call from background thread)
    func requestAccessAndLoad() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            if cache.isEmpty { preloadContacts() }
            return
        }
        if status == .notDetermined {
            // This must NOT be called from main thread
            store.requestAccess(for: .contacts) { granted, _ in
                if granted { self.preloadContacts() }
            }
        }
    }

    func resolveName(for identifier: String) -> String? {
        if identifier.contains("@") {
            return cache[identifier.lowercased()]
        }
        let digits = identifier.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cache[String(digits.suffix(10))]
    }

    private func preloadContacts() {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        request.unifyResults = true

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let name = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                guard !name.isEmpty else { return }

                for phone in contact.phoneNumbers {
                    let digits = phone.value.stringValue
                        .replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    let last10 = String(digits.suffix(10))
                    if !last10.isEmpty { self.cache[last10] = name }
                }
                for email in contact.emailAddresses {
                    self.cache[(email.value as String).lowercased()] = name
                }
            }
        } catch {}
    }
}

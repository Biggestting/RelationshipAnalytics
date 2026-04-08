import Foundation
import Contacts

/// Resolves phone numbers and emails to contact names using the macOS Contacts framework.
final class ContactNameResolver {
    private let store = CNContactStore()
    private var cache: [String: String] = [:]
    private var hasAccess = false

    init() {
        // Check/request access
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            hasAccess = true
            preloadContacts()
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            store.requestAccess(for: .contacts) { granted, _ in
                self.hasAccess = granted
                if granted { self.preloadContacts() }
                semaphore.signal()
            }
            semaphore.wait()
        default:
            hasAccess = false
        }
    }

    /// Resolve a phone number or email to a contact name
    func resolveName(for identifier: String) -> String? {
        if identifier.contains("@") {
            return cache[identifier.lowercased()]
        }
        // Normalize phone for lookup
        let digits = identifier.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        let last10 = String(digits.suffix(10))
        return cache[last10]
    }

    /// Preload all contacts into a lookup dictionary for fast resolution
    private func preloadContacts() {
        guard hasAccess else { return }

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

                // Map all phone numbers to this name
                for phone in contact.phoneNumbers {
                    let digits = phone.value.stringValue
                        .replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    let last10 = String(digits.suffix(10))
                    if !last10.isEmpty {
                        self.cache[last10] = name
                    }
                }

                // Map all emails to this name
                for email in contact.emailAddresses {
                    self.cache[(email.value as String).lowercased()] = name
                }
            }
        } catch {
            // Contacts access failed — names will show as phone numbers
        }
    }
}

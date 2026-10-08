import Foundation
import Security

// The member's upload key (per-device key from the in-app sign-in, or a key entered by hand) as a generic password.
// The file-based login keychain is used on purpose: the data protection keychain needs a signing team, and test builds
// are ad-hoc signed (macOS then asks again for access after each new build).
enum KeychainStore {
    enum ReadResult {
        case found(String)
        case notFound
        // Access was denied or the keychain could not be read; the key may still exist.
        case failed(OSStatus)
    }

    private static let service = "tr.com.upla.UpLa"
    private static let account = "upload-key"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func readKey() -> ReadResult {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let key = String(data: data, encoding: .utf8), !key.isEmpty else {
                return .notFound
            }
            return .found(key)
        case errSecItemNotFound:
            return .notFound
        default:
            return .failed(status)
        }
    }

    // Replaces the stored key. Returns errSecSuccess or the keychain error.
    @discardableResult
    static func saveKey(_ key: String) -> OSStatus {
        let data = Data(key.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update as CFDictionary)

        if updateStatus != errSecItemNotFound {
            return updateStatus
        }

        var add = baseQuery
        add[kSecValueData as String] = data
        add[kSecAttrLabel as String] = "UpLa upload key (upla.com.tr)"
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(add as CFDictionary, nil)

        if status == errSecParam {
            // Some keychains reject the accessibility attribute; the item is still protected by the login keychain.
            add.removeValue(forKey: kSecAttrAccessible as String)
            return SecItemAdd(add as CFDictionary, nil)
        }

        return status
    }

    @discardableResult
    static func deleteKey() -> OSStatus {
        let status = SecItemDelete(baseQuery as CFDictionary)
        return status == errSecItemNotFound ? errSecSuccess : status
    }

    static func message(for status: OSStatus) -> String {
        if let text = SecCopyErrorMessageString(status, nil) as String? {
            return "\(text) (\(status))"
        }
        return "\(status)"
    }
}

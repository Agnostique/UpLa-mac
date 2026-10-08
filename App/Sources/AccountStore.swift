import Combine
import Foundation
import Security
import UplaKit

enum AccountState: Equatable {
    // Uploads with the shared guest key.
    case guest
    // Signed in from the app: this Mac has its own key, shown on the website's "Connected devices" page.
    case signedIn
    // The server no longer accepts this Mac's key (removed on "Connected devices", by the 10 key limit, or by an admin).
    // Kept in memory only, like the Windows app: after a relaunch the next upload or the account settings check again.
    // Uploads still use the key and let the server decide.
    case expired
    // An account or key is remembered but the key could not be read from the keychain. Uploads must not silently
    // become guest uploads.
    case lost
    // A key entered by hand from upla.com.tr/settings/api; files go to the account that owns it.
    case manualKey
}

enum SignInOutcome {
    case success
    case failed(UplaAccountResult)
    case keychainFailed(OSStatus)
}

// The upla.com.tr account of this Mac: the upload key in the keychain, the shown account in UserDefaults.
@MainActor
final class AccountStore: ObservableObject {
    private enum Key {
        static let username = "Account.Username"
        static let name = "Account.Name"
        static let profileURL = "Account.ProfileURL"
        static let keySource = "Account.KeySource"
        static let installID = "InstallID"
    }

    private enum KeySource: String {
        case signIn
        case manual
    }

    @Published private(set) var state: AccountState = .guest
    @Published private(set) var username = ""
    @Published private(set) var name = ""
    @Published private(set) var profileURL = ""

    private let defaults: UserDefaults
    private var apiKey = ""
    private var keySource: KeySource?
    private var expired = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        username = defaults.string(forKey: Key.username) ?? ""
        name = defaults.string(forKey: Key.name) ?? ""
        profileURL = defaults.string(forKey: Key.profileURL) ?? ""
        keySource = KeySource(rawValue: defaults.string(forKey: Key.keySource) ?? "")

        // Guests never touch the keychain, so they never see a keychain prompt.
        if keySource != nil || !username.isEmpty {
            switch KeychainStore.readKey() {
            case .found(let key):
                apiKey = Upla.normalizeAPIKey(key)
            case .notFound:
                accountLog.notice("The remembered upload key is not in the keychain")
            case .failed(let status):
                accountLog.error("Reading the upload key failed: \(status, privacy: .public)")
            }
        }

        updateState()
    }

    // The member key to upload with; nil for guests and when the sign-in is lost.
    var memberKey: String? {
        switch state {
        case .signedIn, .expired, .manualKey:
            return apiKey.isEmpty ? nil : apiKey
        case .guest, .lost:
            return nil
        }
    }

    var isSignedIn: Bool {
        state == .signedIn || state == .expired
    }

    var hasMemberKey: Bool {
        memberKey != nil
    }

    var displayName: String {
        name.isEmpty || name == username ? username : "\(name) (\(username))"
    }

    // Random per installation; names this Mac's key on the website's "Connected devices" page.
    var installID: String {
        if let id = defaults.string(forKey: Key.installID), !id.isEmpty {
            return id
        }

        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        defaults.set(id, forKey: Key.installID)
        return id
    }

    func signIn(loginSubject: String, password: String, twoFactorCode: String?) async -> SignInOutcome {
        // The model ("MacBook Pro"), not the Computer Name: macOS builds that from the owner's name, and the device name
        // is stored on the server.
        let deviceName = Upla.deviceName(computerName: MacModel.name, installID: installID)
        let client = UplaAccountClient(baseURL: AppEnvironment.baseURL)
        let result = await client.signIn(loginSubject: loginSubject, password: password, twoFactorCode: twoFactorCode,
                                         deviceName: deviceName)

        guard result.isSuccess else {
            return .failed(result)
        }

        let key = Upla.normalizeAPIKey(result.apiKey)
        let status = KeychainStore.saveKey(key)

        guard status == errSecSuccess else {
            accountLog.error("Saving the upload key failed: \(status, privacy: .public)")
            // This Mac cannot keep the new key, so it is removed again instead of using up one of the 10 device keys.
            _ = await client.signOut(apiKey: key)
            return .keychainFailed(status)
        }

        apiKey = key
        keySource = .signIn
        expired = false
        username = result.account?.username ?? loginSubject
        name = result.account?.name ?? ""
        profileURL = result.account?.profileURL ?? ""
        save()
        updateState()
        return .success
    }

    // Refreshes the shown account (the name may have changed) and notices a Mac that was removed on the website. Runs
    // when the account settings open, like UpLa for Windows, not at every launch.
    func refresh() async {
        guard isSignedIn, !apiKey.isEmpty else {
            return
        }

        let key = apiKey
        let result = await UplaAccountClient(baseURL: AppEnvironment.baseURL).account(apiKey: key)

        guard key == apiKey, isSignedIn else {
            return
        }

        switch result.status {
        case .success:
            if let account = result.account, !account.username.isEmpty {
                username = account.username
                name = account.name
                profileURL = account.profileURL
                save()
            }
            expired = false
            updateState()
        case .invalidKey:
            // The key stays, so uploads fail with a clear message instead of silently becoming guest uploads.
            markExpired(ifKeyIs: key)
        default:
            accountLog.notice("Account check did not finish: \(String(describing: result.status), privacy: .public)")
        }
    }

    // The server refused the given sign-in key. Ignored when that is no longer this Mac's key (signed out and in again
    // while the request ran), so a newer key is never marked expired.
    func markExpired(ifKeyIs key: String) {
        guard key == apiKey, state == .signedIn else {
            return
        }

        expired = true
        updateState()
    }

    // Forgets the key on this Mac first, then asks the server to delete it. Returns the server's answer when the
    // connection could not be removed there; a key entered by hand belongs to the website and is only forgotten here.
    func signOut() async -> UplaAccountResult? {
        let key = apiKey
        let wasSignedIn = keySource == .signIn || !username.isEmpty
        clear()

        guard wasSignedIn, !key.isEmpty else {
            return nil
        }

        let result = await UplaAccountClient(baseURL: AppEnvironment.baseURL).signOut(apiKey: key)

        switch result.status {
        case .success, .invalidKey:
            // invalidKey: the connection was already removed, which is what signing out wants too.
            return nil
        default:
            return result
        }
    }

    // Replaces the sign-in with a key entered by hand. Returns errSecSuccess or the keychain error.
    func useManualKey(_ key: String) -> OSStatus {
        let normalized = Upla.normalizeAPIKey(key)

        guard !normalized.isEmpty else {
            return errSecParam
        }

        let status = KeychainStore.saveKey(normalized)

        guard status == errSecSuccess else {
            return status
        }

        apiKey = normalized
        keySource = .manual
        expired = false
        username = ""
        name = ""
        profileURL = ""
        save()
        updateState()
        return status
    }

    // Forgets the key and the account on this Mac only ("Continue as Guest", removing a key entered by hand).
    func clear() {
        let status = KeychainStore.deleteKey()

        if status != errSecSuccess {
            accountLog.error("Deleting the upload key failed: \(status, privacy: .public)")
        }

        apiKey = ""
        keySource = nil
        expired = false
        username = ""
        name = ""
        profileURL = ""
        save()
        updateState()
    }

    private func save() {
        defaults.set(username, forKey: Key.username)
        defaults.set(name, forKey: Key.name)
        defaults.set(profileURL, forKey: Key.profileURL)

        if let keySource {
            defaults.set(keySource.rawValue, forKey: Key.keySource)
        } else {
            defaults.removeObject(forKey: Key.keySource)
        }
    }

    private func updateState() {
        if !apiKey.isEmpty {
            state = username.isEmpty ? .manualKey : (expired ? .expired : .signedIn)
        } else {
            state = username.isEmpty && keySource == nil ? .guest : .lost
        }
    }
}

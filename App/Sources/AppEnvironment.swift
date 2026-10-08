import Foundation
import os
import UplaKit

let appLog = Logger(subsystem: "tr.com.upla.UpLa", category: "app")
let uploadLog = Logger(subsystem: "tr.com.upla.UpLa", category: "upload")
let accountLog = Logger(subsystem: "tr.com.upla.UpLa", category: "account")

// Build and runtime facts that do not change while the app runs.
enum AppEnvironment {
    // Debug builds only: a test site on this Mac or the local network, given in the launch environment (Xcode: Edit
    // Scheme › Run › Arguments), e.g. UPLA_DEBUG_BASE_URL=http://localhost:8090. Never read from saved defaults, so
    // nothing can redirect the app for good. Its sign-in has its own keychain item and settings, and the shared guest
    // key is not sent there.
    static let testSiteURL: URL? = {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment

        guard let text = environment["UPLA_DEBUG_BASE_URL"], !text.isEmpty else {
            return nil
        }

        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, isLocalHost(host) else {
            appLog.error("UPLA_DEBUG_BASE_URL is ignored: only http(s) addresses on this Mac or the local network are allowed")
            return nil
        }

        appLog.notice("Using the test site \(url.absoluteString, privacy: .public)")
        return url
        #else
        return nil
        #endif
    }()

    static var baseURL: URL {
        testSiteURL ?? Upla.websiteURL
    }

    // The shared guest key comes from Config/Secrets.xcconfig through Info.plist; builds without it have none. A test
    // site gets only its own key (UPLA_DEBUG_GUEST_API_KEY), never the shared one.
    static var guestAPIKey: String {
        if testSiteURL != nil {
            return Upla.normalizeAPIKey(ProcessInfo.processInfo.environment["UPLA_DEBUG_GUEST_API_KEY"] ?? "")
        }

        let value = Bundle.main.object(forInfoDictionaryKey: "UplaGuestAPIKey") as? String ?? ""
        // An unexpanded "$(UPLA_GUEST_API_KEY)" means the build setting was missing.
        return value.hasPrefix("$(") ? "" : Upla.normalizeAPIKey(value)
    }

    // A test site's sign-in is kept apart from the real one: its own keychain item and account settings.
    static var keychainAccount: String {
        testSiteURL == nil ? "upload-key" : "upload-key-test-site"
    }

    static var accountDefaults: UserDefaults {
        testSiteURL == nil ? .standard : (UserDefaults(suiteName: "tr.com.upla.UpLa.TestSite") ?? .standard)
    }

    // Loopback, private IPv4 ranges and .local names.
    static func isLocalHost(_ host: String) -> Bool {
        let name = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))

        if name == "localhost" || name.hasSuffix(".localhost") || name == "::1" || name.hasSuffix(".local") {
            return true
        }

        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        let numbers = parts.compactMap { UInt8($0) }

        guard parts.count == 4, numbers.count == 4 else {
            return false
        }

        switch (numbers[0], numbers[1]) {
        case (127, _), (10, _), (192, 168), (172, 16...31):
            return true
        default:
            return false
        }
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    static let licenseURL = URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!
    static let screenRecordingSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    // Links from the server are opened only when they are web links.
    static func webURL(_ text: String?) -> URL? {
        guard let text, let url = URL(string: text), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https", url.host != nil else {
            return nil
        }
        return url
    }
}

import Foundation
import os
import UplaKit

let appLog = Logger(subsystem: "tr.com.upla.UpLa", category: "app")
let uploadLog = Logger(subsystem: "tr.com.upla.UpLa", category: "upload")
let accountLog = Logger(subsystem: "tr.com.upla.UpLa", category: "account")

// Build and runtime facts that do not change while the app runs.
enum AppEnvironment {
    // The shared guest key comes from Config/Secrets.xcconfig through Info.plist; builds without it have none.
    static var guestAPIKey: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "UplaGuestAPIKey") as? String ?? ""
        // An unexpanded "$(UPLA_GUEST_API_KEY)" means the build setting was missing.
        return value.hasPrefix("$(") ? "" : Upla.normalizeAPIKey(value)
    }

    static var baseURL: URL {
        #if DEBUG
        // Debug builds can talk to a test site: defaults write tr.com.upla.UpLa UplaDebugBaseURL http://localhost:8090
        if let text = UserDefaults.standard.string(forKey: "UplaDebugBaseURL"), let url = URL(string: text),
           let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https", url.host != nil {
            return url
        }
        #endif
        return Upla.websiteURL
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

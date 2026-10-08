import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Result of a sign-in, account or sign-out request.
public enum UplaAccountStatus: Equatable, Sendable {
    case success
    /// The password is right; the account wants its two-step code.
    case twoFactorRequired
    /// Wrong username/e-mail and password combination, or a field was missing.
    case invalidCredentials
    case invalidTwoFactorCode
    /// Too many failed attempts (or Cloudflare's rate limit); see `retryAfterSeconds`.
    case tooManyAttempts
    /// A plain 403: Chevereto's daily lockout of an IP after failed attempts, or a Cloudflare block.
    case blocked
    case accountBanned
    case accountAwaitingConfirmation
    case accountAwaitingEmail
    case accountNotValid
    /// The key was removed on the website ("Connected devices"), by the 10 key limit, or by an admin.
    case invalidKey
    /// API keys are turned off for members.
    case apiDisabled
    /// A non-JSON 404/405: the site has no upla-app route.
    case notSupported
    /// A non-JSON 2xx page: maintenance, consent or private mode.
    case unexpectedPage
    /// A non-JSON answer with status 500 or higher.
    case server(Int)
    /// An unknown JSON error code, with the server message.
    case failed(String)
    case unexpectedResponse
    case connectionError
    case cancelled
}

/// The signed-in member as the website shows it.
public struct UplaAccount: Codable, Equatable, Sendable {
    public var username: String
    /// Display name; may be empty.
    public var name: String
    /// Profile page link; may be empty.
    public var profileURL: String

    public init(username: String, name: String = "", profileURL: String = "") {
        self.username = username
        self.name = name
        self.profileURL = profileURL
    }

    private enum CodingKeys: String, CodingKey {
        case username, name, profileURL
    }

    // Saved accounts stay readable when fields are added later: missing values are empty.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = (try? container.decodeIfPresent(String.self, forKey: .username)) ?? ""
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        profileURL = (try? container.decodeIfPresent(String.self, forKey: .profileURL)) ?? ""
    }
}

public struct UplaAccountResult: Equatable, Sendable {
    public var status: UplaAccountStatus
    /// The new device key after a successful sign-in, otherwise empty. Keep it in the Keychain; never log it.
    public var apiKey: String
    /// The account of a successful sign-in or account request.
    public var account: UplaAccount?
    /// Seconds to wait after `tooManyAttempts` (0 when not known).
    public var retryAfterSeconds: Int

    public var isSuccess: Bool {
        status == .success
    }

    public init(status: UplaAccountStatus, apiKey: String = "", account: UplaAccount? = nil, retryAfterSeconds: Int = 0) {
        self.status = status
        self.apiKey = apiKey
        self.account = account
        self.retryAfterSeconds = retryAfterSeconds
    }
}

// The device key must not end up in logs or test output.
extension UplaAccountResult: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "UplaAccountResult(status: \(status), apiKey: \(apiKey.isEmpty ? "\"\"" : "<hidden>"), account: \(account.map { "\($0)" } ?? "nil"), retryAfterSeconds: \(retryAfterSeconds))"
    }

    public var debugDescription: String {
        description
    }
}

/// Client of the upla-app route (`Server/chevereto/app/legacy/routes/overrides/upla-app.php` in the Windows repo),
/// ported from `UplaAccount.cs`. It signs a member in with username/e-mail and password and gets an upload key for
/// this computer. The password is only sent to the server and never stored or logged.
public final class UplaAccountClient: Sendable {
    public let baseURL: URL
    /// Each request gives up after this long (the caller can also cancel at any time).
    public let timeout: TimeInterval
    private let sessionSettings: SessionSettings

    public init(baseURL: URL = Upla.websiteURL, configuration: URLSessionConfiguration = .default, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.sessionSettings = SessionSettings(configuration)
    }

    /// - Parameters:
    ///   - loginSubject: Username or e-mail; surrounding spaces are removed.
    ///   - twoFactorCode: Only its digits are sent, and only when there are any.
    ///   - deviceName: Shown on the website's "Connected devices" page; see `Upla.deviceName(computerName:installID:)`.
    public func signIn(loginSubject: String, password: String, twoFactorCode: String?, deviceName: String) async -> UplaAccountResult {
        var fields: [(name: String, value: String)] = [
            ("login-subject", loginSubject.trimmingCharacters(in: .whitespacesAndNewlines)),
            ("password", password),
            ("device", deviceName)
        ]

        let code = Self.digits(twoFactorCode ?? "")

        if !code.isEmpty {
            fields.append(("two-factor-code", code))
        }

        return await post("login", fields: fields, apiKey: nil)
    }

    /// The account the key belongs to ("me").
    public func account(apiKey: String) async -> UplaAccountResult {
        await post("me", fields: [], apiKey: Upla.normalizeAPIKey(apiKey))
    }

    /// Deletes this computer's key on the server ("logout"); the caller forgets the key locally whatever the result is.
    public func signOut(apiKey: String) async -> UplaAccountResult {
        await post("logout", fields: [], apiKey: Upla.normalizeAPIKey(apiKey))
    }

    /// - Parameters:
    ///   - action: "login", "me" or "logout"; a successful login must carry a key and a username, "me" a username.
    ///   - retryAfterHeader: Seconds from the Retry-After header, used when the JSON has no retry_after.
    public static func parseResponse(data: Data?, statusCode: Int?, action: String, retryAfterHeader: Int = 0) -> UplaAccountResult {
        guard let status = statusCode else {
            return UplaAccountResult(status: .connectionError)
        }

        guard let json = JSONFields.object(from: data) else {
            switch status {
            case 404, 405:
                // The site does not have the upla-app route (yet).
                return UplaAccountResult(status: .notSupported)
            case 403:
                // A plain "403 Forbidden" is Chevereto's daily lockout after too many failed sign-ins, sign-ups or
                // two-step codes from one IP; a Cloudflare block is an HTML 403 page.
                return UplaAccountResult(status: .blocked)
            case 429:
                // Cloudflare rate limiting answers with an HTML page.
                return UplaAccountResult(status: .tooManyAttempts, retryAfterSeconds: retryAfterHeader)
            default:
                // 2xx HTML: maintenance, consent or private mode pages, or a Chevereto IP ban message.
                if status >= 500 {
                    return UplaAccountResult(status: .server(status))
                }

                return UplaAccountResult(status: status < 300 ? .unexpectedPage : .unexpectedResponse)
            }
        }

        let user = json["user"] as? [String: Any]
        let apiKey = Upla.normalizeAPIKey(text(json["api_key"]))
        let username = text(user?["username"])

        if status == 200 && json["error"] == nil {
            let complete: Bool

            switch action {
            case "login":
                complete = !apiKey.isEmpty && !username.isEmpty
            case "me":
                complete = !username.isEmpty
            default:
                complete = true
            }

            guard complete else {
                return UplaAccountResult(status: .unexpectedResponse)
            }

            let account = username.isEmpty ? nil : UplaAccount(username: username, name: text(user?["name"]), profileURL: text(user?["url"]))
            return UplaAccountResult(status: .success, apiKey: apiKey, account: account)
        }

        let code = text(JSONFields.value(json, "error", "code"))
        let message = text(JSONFields.value(json, "error", "message"))
        let retryAfter = JSONFields.int(json["retry_after"]) ?? retryAfterHeader

        switch code {
        case "two_factor_required":
            return UplaAccountResult(status: .twoFactorRequired, retryAfterSeconds: retryAfter)
        case "invalid_credentials", "missing_fields":
            return UplaAccountResult(status: .invalidCredentials, retryAfterSeconds: retryAfter)
        case "invalid_two_factor_code":
            return UplaAccountResult(status: .invalidTwoFactorCode, retryAfterSeconds: retryAfter)
        case "too_many_attempts":
            return UplaAccountResult(status: .tooManyAttempts, retryAfterSeconds: retryAfter)
        case "account_banned":
            return UplaAccountResult(status: .accountBanned, retryAfterSeconds: retryAfter)
        case "account_awaiting_confirmation":
            return UplaAccountResult(status: .accountAwaitingConfirmation, retryAfterSeconds: retryAfter)
        case "account_awaiting_email":
            return UplaAccountResult(status: .accountAwaitingEmail, retryAfterSeconds: retryAfter)
        case "account_not_valid":
            return UplaAccountResult(status: .accountNotValid, retryAfterSeconds: retryAfter)
        case "invalid_key":
            return UplaAccountResult(status: .invalidKey, retryAfterSeconds: retryAfter)
        case "api_disabled":
            return UplaAccountResult(status: .apiDisabled, retryAfterSeconds: retryAfter)
        default:
            if status == 429 {
                return UplaAccountResult(status: .tooManyAttempts, retryAfterSeconds: retryAfter)
            }

            return UplaAccountResult(status: message.isEmpty ? .unexpectedResponse : .failed(message), retryAfterSeconds: retryAfter)
        }
    }

    private func post(_ action: String, fields: [(name: String, value: String)], apiKey: String?) async -> UplaAccountResult {
        var request = URLRequest(url: Upla.endpoint(baseURL, "/upla-app/" + action))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "X-Upla-App")

        if let apiKey, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        request.httpBody = Data(FormURLEncoding.encode(fields).utf8)
        request.timeoutInterval = timeout

        let outcome = await HTTPTransfer.run(request, configuration: sessionSettings.make(idleTimeout: timeout), timeLimit: timeout)

        if outcome.failed && outcome.cancelled {
            return UplaAccountResult(status: .cancelled)
        }

        // Errors are reported without any request data, so the password cannot end up in a log.
        if outcome.timedOut || (outcome.failed && outcome.statusCode == nil) {
            return UplaAccountResult(status: .connectionError)
        }

        return Self.parseResponse(data: outcome.data, statusCode: outcome.statusCode, action: action, retryAfterHeader: Self.retryAfterSeconds(outcome.retryAfter))
    }

    /// Retry-After in seconds; an HTTP date or anything else counts as unknown (0).
    static func retryAfterSeconds(_ header: String?) -> Int {
        guard let header, let seconds = Int(header.trimmingCharacters(in: .whitespaces)), seconds >= 0 else {
            return 0
        }

        return seconds
    }

    /// Decimal digits only, as ASCII (a code typed with full-width or other digits still works).
    static func digits(_ text: String) -> String {
        var result = ""

        for scalar in text.unicodeScalars where scalar.properties.generalCategory == .decimalNumber {
            if let value = scalar.properties.numericValue, value >= 0, value <= 9 {
                result += String(Int(value))
            }
        }

        return result
    }

    // The account route's text fields: a JSON string, number or boolean as text, anything else empty.
    private static func text(_ value: Any?) -> String {
        JSONFields.text(value) ?? ""
    }
}

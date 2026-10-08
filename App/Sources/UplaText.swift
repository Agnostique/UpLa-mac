import Foundation
import UplaKit

// Which key an upload used; decides the text of an invalid key error.
enum UploadKeyKind {
    case guest
    case signIn
    case manual
}

// The one place that turns UplaKit results into user-facing texts (English and Turkish, wording of the Windows app's
// UplaStrings.cs). Interpolated values are always strings, so every key uses %@.
enum UplaText {
    static func uploadError(_ error: UplaUploadError, keyKind: UploadKeyKind) -> String {
        switch error {
        case .unsupportedFileType(let fileType):
            let types = (Upla.imageExtensions + Upla.videoExtensions).joined(separator: ", ")
            return String(localized: "\"\(fileType)\" files cannot be uploaded to upla.com.tr. Supported types: \(types).")
        case .fileTooLarge(let size, let limit, let isMember):
            // Guest limits are binary megabytes (20 MiB), member limits decimal (Cloudflare's 100 MB), like on Windows.
            let sizeText = megabytes(size, binary: !isMember)
            let limitText = megabytes(limit, binary: !isMember)
            if isMember {
                return String(localized: "The file is too large (\(sizeText)); at most \(limitText) can be uploaded at once.")
            }
            return String(localized: "The file is too large (\(sizeText)). Guest uploads are limited to \(limitText); sign in with your account for larger files.")
        case .fileUnreadable:
            return String(localized: "The file could not be read.")
        case .invalidKey(let isMember):
            if !isMember || keyKind == .guest {
                return String(localized: "Guest upload is currently disabled on upla.com.tr. Sign in with your account from the \"upla.com.tr Account\" menu.")
            }
            if keyKind == .manual {
                return String(localized: "The upla.com.tr API key entered by hand is invalid. Sign in from the app or check the key in Settings › Account.")
            }
            return invalidSignInText
        case .oldKeyFormat:
            return oldKeyFormatText
        case .duplicate:
            return String(localized: "This file was already uploaded recently; upla.com.tr does not accept the same file again within 24 hours.")
        case .flood:
            return String(localized: "Too many uploads in a short time. Please wait a little and try again.")
        case .emptySource:
            return String(localized: "The file did not reach the server; it may be larger than allowed.")
        case .rejected(let message):
            return String(localized: "upla.com.tr rejected the upload: \(message)")
        case .forbidden:
            return String(localized: "This account is not allowed to upload to upla.com.tr, or uploads are temporarily disabled.")
        case .videoProcessing:
            return String(localized: "upla.com.tr could not process the video.")
        case .widthTooLarge:
            return String(localized: "The resize width is larger than the image width.")
        case .fileTypeRejected:
            return String(localized: "This file type is currently not accepted by upla.com.tr.")
        case .tooBig:
            return String(localized: "The file is too large for upla.com.tr.")
        case .apiDisabled:
            return String(localized: "The upla.com.tr upload API is currently disabled.")
        case .server(let status):
            return serverText(status)
        case .connection:
            return connectionText
        case .unexpectedResponse:
            return unexpectedResponseText
        case .cancelled:
            return String(localized: "The upload was cancelled.")
        @unknown default:
            return unexpectedResponseText
        }
    }

    static func accountStatus(_ status: UplaAccountStatus, retryAfterSeconds: Int = 0) -> String {
        switch status {
        case .success:
            return ""
        case .twoFactorRequired:
            return String(localized: "Two-step verification is on for your account. Enter the 6-digit code from your authenticator app.")
        case .invalidCredentials:
            return String(localized: "Wrong username/email or password. If you created your account with a social network, create a password on the website first.")
        case .invalidTwoFactorCode:
            return String(localized: "Wrong verification code.")
        case .tooManyAttempts:
            if retryAfterSeconds >= 86_400 {
                return String(localized: "Too many failed attempts. Try again in 24 hours or sign in on the website.")
            }
            if retryAfterSeconds >= 3_600 {
                return String(localized: "Too many failed attempts. Try again in an hour or sign in on the website.")
            }
            return String(localized: "Too many requests to upla.com.tr. Wait a little and try again.")
        case .blocked:
            return String(localized: "upla.com.tr is temporarily blocking requests from this Mac (possibly too many failed attempts). Try again later.")
        case .accountBanned:
            return String(localized: "This account is banned.")
        case .accountAwaitingConfirmation:
            return String(localized: "Your account is not confirmed yet. Click the confirmation link sent to your email.")
        case .accountAwaitingEmail:
            return String(localized: "Your account needs an email address. Sign in on upla.com.tr and add your email address.")
        case .accountNotValid:
            return String(localized: "This account cannot sign in.")
        case .invalidKey:
            return deviceSignedOutText
        case .apiDisabled:
            return String(localized: "upla.com.tr does not accept member uploads right now.")
        case .notSupported:
            return String(localized: "upla.com.tr does not support signing in from the app yet. In Settings › Account you can enter the key from upla.com.tr › Settings › API by hand.")
        case .unexpectedPage:
            return String(localized: "upla.com.tr answered the sign-in with an unexpected page (the site may be under maintenance). Try again later.")
        case .server(let code):
            return serverText(code)
        case .failed(let message):
            return message.isEmpty ? unexpectedResponseText : String(localized: "Could not sign in: \(message)")
        case .unexpectedResponse:
            return unexpectedResponseText
        case .connectionError:
            return connectionText
        case .cancelled:
            return ""
        @unknown default:
            return unexpectedResponseText
        }
    }

    // Result of "Check Key"; an empty field checks the guest key, like on Windows.
    static func keyStatus(_ status: UplaKeyStatus, isMember: Bool) -> String {
        switch status {
        case .valid:
            return isMember ? String(localized: "The key is valid; files will be uploaded to your account.")
                : String(localized: "Guest upload is available.")
        case .invalid:
            return isMember ? String(localized: "Invalid key. Sign in from the app or create a new key on the \"Connected devices\" page.")
                : String(localized: "Guest upload is currently disabled. Sign in with your account.")
        case .oldFormat:
            return oldKeyFormatText
        case .noUploadPermission:
            return String(localized: "The key is valid but this account is not allowed to upload.")
        case .unknown(let message):
            let reason = message.isEmpty ? connectionText : message
            return String(localized: "Could not verify the key: \(reason)")
        @unknown default:
            return unexpectedResponseText
        }
    }

    static func linkType(_ type: UplaLinkType) -> String {
        switch type {
        case .viewerPage:
            return String(localized: "Page link (recommended)")
        case .directLink:
            return String(localized: "Direct file link")
        case .shortLink:
            return String(localized: "Short link")
        @unknown default:
            return type.rawValue
        }
    }

    // "PT5M", "PT1H", "P2D", "P1W", "P3M", "P1Y" -> "5 minutes", "1 hour", "2 days"...
    static func duration(_ preset: String) -> String {
        guard preset.hasPrefix("P"), let unit = preset.last else {
            return preset
        }

        let isTime = preset.hasPrefix("PT")
        let digits = preset.dropFirst(isTime ? 2 : 1).dropLast()

        guard let count = Int(digits), count > 0 else {
            return preset
        }

        let number = String(count)
        let one = count == 1

        switch (unit, isTime) {
        case ("M", true):
            return one ? String(localized: "1 minute") : String(localized: "\(number) minutes")
        case ("H", true):
            return one ? String(localized: "1 hour") : String(localized: "\(number) hours")
        case ("D", false):
            return one ? String(localized: "1 day") : String(localized: "\(number) days")
        case ("W", false):
            return one ? String(localized: "1 week") : String(localized: "\(number) weeks")
        case ("M", false):
            return one ? String(localized: "1 month") : String(localized: "\(number) months")
        case ("Y", false):
            return one ? String(localized: "1 year") : String(localized: "\(number) years")
        default:
            return preset
        }
    }

    static func megabytes(_ bytes: Int64, binary: Bool) -> String {
        let value = Double(bytes) / (binary ? 1_048_576 : 1_000_000)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        let number = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return number + " MB"
    }

    static var invalidSignInText: String {
        String(localized: "Your upla.com.tr account connection is no longer valid (this Mac's connection may have been removed). Choose \"Sign In Again\" in the \"upla.com.tr Account\" menu.")
    }

    static var deviceSignedOutText: String {
        String(localized: "This Mac's connection was removed (possibly from the website's \"Connected devices\" page). Sign in again.")
    }

    static var signInLostText: String {
        String(localized: "The file was not uploaded because the upla.com.tr sign-in saved on this Mac could not be read from the keychain. Sign in again or continue as a guest from the \"upla.com.tr Account\" menu.")
    }

    static var noGuestKeyText: String {
        String(localized: "This build has no guest upload key. Sign in to upload.")
    }

    static var oldKeyFormatText: String {
        String(localized: "This key uses an old format that is no longer supported. Sign in from the app or create a new key on the \"Connected devices\" page.")
    }

    static var connectionText: String {
        String(localized: "Could not connect to upla.com.tr. Check your internet connection.")
    }

    static var unexpectedResponseText: String {
        String(localized: "Unexpected response from upla.com.tr.")
    }

    static func serverText(_ status: Int) -> String {
        let code = String(status)
        return String(localized: "upla.com.tr is not responding right now (HTTP \(code)). Please try again later.")
    }

    static func keychainText(_ status: OSStatus) -> String {
        let reason = KeychainStore.message(for: status)
        return String(localized: "The key could not be saved in the keychain: \(reason)")
    }
}

import Foundation

/// Parses the answers of Chevereto's API V1.1 (`/api/1/upload`), ported from `UplaUploader.cs` of UpLa for Windows.
/// Error codes come from Chevereto 4.5.7. Messages may be translated to the site language, so the codes decide.
public enum UplaResponseParser {
    /// - Parameters:
    ///   - data: The response body, nil when no answer arrived.
    ///   - statusCode: The HTTP status, nil when no answer arrived.
    public static func parseUpload(data: Data?, statusCode: Int?, linkType: UplaLinkType, isMember: Bool) -> Result<UplaUploadResult, UplaUploadError> {
        let json = JSONFields.object(from: data)
        let requestSucceeded = statusCode.map { (200..<300).contains($0) } ?? false

        if requestSucceeded, let image = JSONFields.value(json, "image") as? [String: Any] {
            let viewerPage = nonEmpty(JSONFields.text(image["url_viewer"]))
            let directLink = nonEmpty(JSONFields.text(image["url"]))
            let shortLink = nonEmpty(JSONFields.text(image["url_short"]))
            let preferred: String?

            switch linkType {
            case .directLink:
                preferred = directLink
            case .shortLink:
                preferred = shortLink
            case .viewerPage:
                preferred = viewerPage
            }

            // Uploads waiting for moderation have no direct or thumbnail links, only the page link.
            guard let url = preferred ?? viewerPage ?? shortLink ?? directLink else {
                return .failure(.unexpectedResponse)
            }

            return .success(UplaUploadResult(
                url: url,
                viewerURL: viewerPage,
                directURL: directLink,
                shortURL: shortLink,
                thumbnailURL: nonEmpty(JSONFields.text(JSONFields.value(image, "thumb", "url"))),
                deletionURL: nonEmpty(JSONFields.text(image["delete_url"])),
                awaitingModeration: JSONFields.bool(image["is_approved"]) == false))
        }

        let code = JSONFields.int(JSONFields.value(json, "error", "code")) ?? 0
        let message = JSONFields.text(JSONFields.value(json, "error", "message"))
        return .failure(uploadError(code: code, message: message, statusCode: statusCode, isMember: isMember))
    }

    /// Answer to a request without a file: Chevereto checks the key before the source, so error 130 (empty source)
    /// means the key is accepted, 100 means it is invalid and 403 means the account cannot upload.
    public static func parseKeyCheck(data: Data?, statusCode: Int?) -> UplaKeyStatus {
        let json = JSONFields.object(from: data)
        let code = JSONFields.int(JSONFields.value(json, "error", "code")) ?? 0
        let message = JSONFields.text(JSONFields.value(json, "error", "message")) ?? ""

        if isOldKeyFormatMessage(message) {
            return .oldFormat
        }

        switch code {
        case 130:
            return .valid
        case 100:
            return .invalid
        case 403:
            return .noUploadPermission
        case 0 where isInvalidKeyPrefixMessage(message):
            return .invalid
        default:
            break
        }

        if !message.isEmpty {
            return .unknown(message)
        }

        return .unknown(statusCode.map { "HTTP \($0)" } ?? "")
    }

    static func uploadError(code: Int, message: String?, statusCode: Int?, isMember: Bool) -> UplaUploadError {
        // Chevereto reports the old (pre 4.4) key format and a wrong key prefix with code 0, not 100 (ApiKey::verify).
        if isOldKeyFormatMessage(message) {
            return .oldKeyFormat
        }

        switch code {
        case 0 where isInvalidKeyPrefixMessage(message), 100:
            return .invalidKey(isMember: isMember)
        case 101:
            return .duplicate
        case 130:
            if containsText(message, "flood") {
                return .flood
            }

            if let message, !message.isEmpty {
                return .rejected(message)
            }

            return .emptySource
        case 403:
            return .forbidden
        case 600:
            return .videoProcessing
        case 610:
            return .widthTooLarge
        case 614:
            return .fileTypeRejected
        default:
            break
        }

        if containsText(message, "too big") || statusCode == 413 {
            return .tooBig
        }

        if let message, !message.isEmpty {
            return .rejected(message)
        }

        if statusCode == 404 {
            return .apiDisabled
        }

        if let statusCode, statusCode >= 500 {
            return .server(statusCode)
        }

        if statusCode == nil {
            return .connection
        }

        return .unexpectedResponse
    }

    // Both messages come from Chevereto's ApiKey::verify and are not translated.
    private static func isOldKeyFormatMessage(_ message: String?) -> Bool {
        containsText(message, "no longer supported")
    }

    private static func isInvalidKeyPrefixMessage(_ message: String?) -> Bool {
        containsText(message, "API key prefix")
    }

    private static func containsText(_ text: String?, _ value: String) -> Bool {
        guard let text else {
            return false
        }

        return text.range(of: value, options: .caseInsensitive) != nil
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }
}

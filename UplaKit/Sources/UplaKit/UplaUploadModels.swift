import Foundation

/// Which link of an upload goes to the clipboard.
public enum UplaLinkType: String, Codable, CaseIterable, Sendable {
    case viewerPage
    case directLink
    case shortLink
}

/// The upla.com.tr settings that shape an upload request.
public struct UplaUploadOptions: Codable, Equatable, Sendable {
    public var linkType: UplaLinkType
    /// Album link or encoded album ID; only sent with a member's key (Chevereto ignores albums of guest uploads).
    public var album: String
    /// Comma separated; only sent with a member's key.
    public var tags: String
    /// Sent when greater than 0.
    public var categoryID: Int
    /// One of `Upla.expirationPresets`; empty (or anything else) means no automatic deletion.
    public var expiration: String
    /// Server-side resize of images wider than this, 0 to disable. Only sent for images that are wider, otherwise
    /// Chevereto fails the whole upload with error 610.
    public var maxWidth: Int

    public init(linkType: UplaLinkType = .viewerPage, album: String = "", tags: String = "", categoryID: Int = 0, expiration: String = "", maxWidth: Int = 0) {
        self.linkType = linkType
        self.album = album
        self.tags = tags
        self.categoryID = categoryID
        self.expiration = expiration
        self.maxWidth = maxWidth
    }

    private enum CodingKeys: String, CodingKey {
        case linkType, album, tags, categoryID, expiration, maxWidth
    }

    // Saved settings stay readable when fields are added later or a value is not understood: missing values get the defaults.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        linkType = (try? container.decodeIfPresent(UplaLinkType.self, forKey: .linkType)) ?? .viewerPage
        album = (try? container.decodeIfPresent(String.self, forKey: .album)) ?? ""
        tags = (try? container.decodeIfPresent(String.self, forKey: .tags)) ?? ""
        categoryID = (try? container.decodeIfPresent(Int.self, forKey: .categoryID)) ?? 0
        expiration = (try? container.decodeIfPresent(String.self, forKey: .expiration)) ?? ""
        maxWidth = (try? container.decodeIfPresent(Int.self, forKey: .maxWidth)) ?? 0
    }
}

/// A finished upload.
public struct UplaUploadResult: Equatable, Sendable {
    /// The link to share: the one the link type asks for, else the viewer page, short link or direct link.
    public var url: String
    public var viewerURL: String?
    public var directURL: String?
    public var shortURL: String?
    public var thumbnailURL: String?
    /// Lets anyone delete the file: keep it local and never log it.
    public var deletionURL: String?
    /// The upload waits for moderation (`is_approved` is false); it has only the viewer page link until approved.
    public var awaitingModeration: Bool

    public init(url: String, viewerURL: String? = nil, directURL: String? = nil, shortURL: String? = nil, thumbnailURL: String? = nil, deletionURL: String? = nil, awaitingModeration: Bool = false) {
        self.url = url
        self.viewerURL = viewerURL
        self.directURL = directURL
        self.shortURL = shortURL
        self.thumbnailURL = thumbnailURL
        self.deletionURL = deletionURL
        self.awaitingModeration = awaitingModeration
    }
}

// The delete link must not end up in logs or test output.
extension UplaUploadResult: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "UplaUploadResult(url: \(url), viewerURL: \(viewerURL ?? "nil"), directURL: \(directURL ?? "nil"), shortURL: \(shortURL ?? "nil"), "
            + "thumbnailURL: \(thumbnailURL ?? "nil"), deletionURL: \(deletionURL == nil ? "nil" : "<hidden>"), awaitingModeration: \(awaitingModeration))"
    }

    public var debugDescription: String {
        description
    }
}

/// Why an upload failed. Server messages can be translated to the site language, so the error codes decide.
public enum UplaUploadError: Error, Equatable, Sendable {
    /// Checked before sending: the file's extension, or its name when it has none.
    case unsupportedFileType(String)
    /// Checked before sending: guests 20 MiB, members 100 MB.
    case fileTooLarge(size: Int64, limit: Int64, isMember: Bool)
    /// The file could not be read (or the request body could not be written to the temporary folder).
    case fileUnreadable
    /// Error 100, or 0 with "API key prefix": for a member the sign-in expired (or the key entered by hand is wrong),
    /// for a guest uploads are not available.
    case invalidKey(isMember: Bool)
    /// The key has the old (pre Chevereto 4.4) format; the member must create a new key.
    case oldKeyFormat
    /// Error 101: the same file was uploaded in the last 24 hours.
    case duplicate
    /// Error 130 with "flood": too many uploads in a short time.
    case flood
    /// Error 130 without a message.
    case emptySource
    /// Another refusal; carries the server message.
    case rejected(String)
    /// Error 403: the account may not upload.
    case forbidden
    /// Error 600: the server could not process the video.
    case videoProcessing
    /// Error 610: the resize width is larger than the image.
    case widthTooLarge
    /// Error 614: the server does not accept this file type.
    case fileTypeRejected
    /// HTTP 413, or a message containing "too big".
    case tooBig
    /// HTTP 404 without a message: the API is turned off.
    case apiDisabled
    /// HTTP 500 or higher.
    case server(Int)
    /// No answer from the server.
    case connection
    case unexpectedResponse
    case cancelled
}

/// Result of checking a key without uploading.
public enum UplaKeyStatus: Equatable, Sendable {
    /// The key may upload (Chevereto got as far as the missing file, error 130).
    case valid
    /// Error 100, or 0 with "API key prefix".
    case invalid
    /// The key has the old (pre Chevereto 4.4) format.
    case oldFormat
    /// Error 403: the account may not upload.
    case noUploadPermission
    /// Anything else: the server message, "HTTP <status>" without one, or "" when no answer arrived.
    case unknown(String)
}

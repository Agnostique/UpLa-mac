import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Uploads images and videos to upla.com.tr through Chevereto API V1.1, like `UplaUploader.cs` of UpLa for Windows.
public final class UplaClient: Sendable {
    /// The member's device key or key entered by hand, or the shared guest key. Whitespace is removed.
    public let apiKey: String
    /// A member's key: albums and tags are sent, and the member upload limit applies.
    public let isMember: Bool
    public let baseURL: URL
    private let sessionSettings: SessionSettings
    /// Where the request body is written during an upload.
    public let temporaryDirectory: URL

    // Processing a large video on the server can take longer than URLSession's default 60 s without any traffic.
    static let uploadIdleTimeout: TimeInterval = 300

    public convenience init(apiKey: String, isMember: Bool, baseURL: URL = Upla.websiteURL, configuration: URLSessionConfiguration = .default) {
        self.init(apiKey: apiKey, isMember: isMember, baseURL: baseURL, configuration: configuration, temporaryDirectory: FileManager.default.temporaryDirectory)
    }

    /// - Parameter temporaryDirectory: Folder for the request body during an upload, created when missing. The body
    ///   holds the key in clear text and stays behind when the process ends during an upload, so an app passes a
    ///   folder it empties itself (at launch and when quitting).
    public init(apiKey: String, isMember: Bool, baseURL: URL, configuration: URLSessionConfiguration, temporaryDirectory: URL) {
        self.apiKey = Upla.normalizeAPIKey(apiKey)
        self.isMember = isMember
        self.baseURL = baseURL
        self.sessionSettings = SessionSettings(configuration)
        self.temporaryDirectory = temporaryDirectory
    }

    /// Checks the extension and size first, then streams a multipart body written to a temporary file (deleted
    /// afterwards). Cancelling the Swift task cancels the request and throws `UplaUploadError.cancelled`.
    /// - Parameters:
    ///   - fileName: Name sent to the server and whose extension is checked; defaults to the file's own name.
    ///   - progress: Fraction of the request body sent, called on any queue.
    /// - Throws: `UplaUploadError` only.
    public func upload(fileURL: URL, fileName: String? = nil, options: UplaUploadOptions, progress: (@Sendable (Double) -> Void)? = nil) async throws -> UplaUploadResult {
        let name: String

        if let fileName, !fileName.isEmpty {
            name = fileName
        } else {
            name = fileURL.lastPathComponent
        }

        let ext = Upla.fileExtension(of: name)

        guard Upla.isSupportedExtension(ext) else {
            throw UplaUploadError.unsupportedFileType(ext.isEmpty ? name : ext)
        }

        guard let size = Self.fileSize(fileURL) else {
            throw UplaUploadError.fileUnreadable
        }

        let limit = Upla.maxUploadSize(isMember: isMember)

        if size > limit {
            throw UplaUploadError.fileTooLarge(size: size, limit: limit, isMember: isMember)
        }

        if Task.isCancelled {
            throw UplaUploadError.cancelled
        }

        let boundary = MultipartBody.makeBoundary()
        let bodyURL = temporaryDirectory.appendingPathComponent("UplaKit-\(UUID().uuidString).upload")
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        do {
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            try MultipartBody.write(fields: uploadFields(fileURL: fileURL, fileExtension: ext, options: options), fileFieldName: "source",
                                    fileURL: fileURL, fileName: name, mimeType: Upla.mimeType(forExtension: ext), boundary: boundary, to: bodyURL)
        } catch {
            throw UplaUploadError.fileUnreadable
        }

        guard let bodySize = Self.fileSize(bodyURL) else {
            throw UplaUploadError.fileUnreadable
        }

        if Task.isCancelled {
            throw UplaUploadError.cancelled
        }

        var request = URLRequest(url: Upla.endpoint(baseURL, Upla.uploadPath))
        request.httpMethod = "POST"
        request.setValue(MultipartBody.contentType(boundary: boundary), forHTTPHeaderField: "Content-Type")
        // Chevereto reads the header first; the "key" field is kept for proxies that drop custom headers.
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = Self.uploadIdleTimeout

        let outcome = await HTTPTransfer.run(request, bodyFile: bodyURL, bodySize: bodySize,
                                             configuration: sessionSettings.make(minimumIdleTimeout: Self.uploadIdleTimeout), progress: progress)

        if outcome.failed && outcome.cancelled {
            throw UplaUploadError.cancelled
        }

        if outcome.failed && outcome.statusCode == nil {
            throw UplaUploadError.connection
        }

        switch UplaResponseParser.parseUpload(data: outcome.data, statusCode: outcome.statusCode, linkType: options.linkType, isMember: isMember) {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    /// Sends a request without a file: Chevereto checks the key before the source, so error 130 (empty source)
    /// means the key is accepted, 100 means it is invalid and 403 means the account cannot upload.
    public func checkKey() async -> UplaKeyStatus {
        var request = URLRequest(url: Upla.endpoint(baseURL, Upla.uploadPath))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = Data(("format=json&key=" + FormURLEncoding.escapeDataString(apiKey)).utf8)

        let outcome = await HTTPTransfer.run(request, configuration: sessionSettings.make())

        if outcome.failed && (outcome.cancelled || outcome.statusCode == nil) {
            return UplaResponseParser.parseKeyCheck(data: nil, statusCode: nil)
        }

        return UplaResponseParser.parseKeyCheck(data: outcome.data, statusCode: outcome.statusCode)
    }

    /// The form fields in the Windows app's order: key, format, album_id, tags, category_id, expiration, width.
    func uploadFields(fileURL: URL, fileExtension ext: String, options: UplaUploadOptions) -> [(name: String, value: String)] {
        var fields: [(name: String, value: String)] = [("key", apiKey), ("format", "json")]

        // Chevereto ignores albums and tags for guest uploads.
        if isMember {
            let albumID = Upla.parseAlbumID(options.album)

            if !albumID.isEmpty {
                fields.append(("album_id", albumID))
            }

            let tags = Upla.normalizeTags(options.tags)

            if !tags.isEmpty {
                fields.append(("tags", tags))
            }
        }

        if options.categoryID > 0 {
            fields.append(("category_id", String(options.categoryID)))
        }

        if !options.expiration.isEmpty && Upla.expirationPresets.contains(options.expiration) {
            fields.append(("expiration", options.expiration))
        }

        // Chevereto fails the whole upload (error 610) when the resize width is larger than the image.
        if options.maxWidth > 0, !Upla.isVideoExtension(ext), let width = ImageWidth.read(from: fileURL), width > options.maxWidth {
            fields.append(("width", String(options.maxWidth)))
        }

        return fields
    }

    /// Size of a regular file; nil for folders and missing or unreadable files. A symbolic link is measured by its
    /// target, which is what gets uploaded (the attributes of a path describe the link itself).
    static func fileSize(_ url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.resolvingSymlinksInPath().path),
              (attributes[.type] as? FileAttributeType) != .typeDirectory else {
            return nil
        }

        if let size = attributes[.size] as? NSNumber {
            return size.int64Value
        }

        if let size = attributes[.size] as? UInt64 {
            return Int64(clamping: size)
        }

        return attributes[.size] as? Int64
    }
}

/// A private copy of the caller's URLSessionConfiguration (a mutable class), never changed after init; each request
/// gets its own copy.
struct SessionSettings: @unchecked Sendable {
    private let configuration: URLSessionConfiguration

    init(_ configuration: URLSessionConfiguration) {
        self.configuration = configuration.copy() as! URLSessionConfiguration
    }

    func make(minimumIdleTimeout: TimeInterval? = nil, idleTimeout: TimeInterval? = nil) -> URLSessionConfiguration {
        let copy = configuration.copy() as! URLSessionConfiguration
        // Answers carry device keys and delete links: nothing is cached, and like the Windows app no cookies are kept.
        copy.urlCache = nil
        copy.requestCachePolicy = .reloadIgnoringLocalCacheData
        copy.httpCookieStorage = nil
        copy.httpShouldSetCookies = false
        copy.httpCookieAcceptPolicy = .never

        if let minimumIdleTimeout {
            copy.timeoutIntervalForRequest = max(copy.timeoutIntervalForRequest, minimumIdleTimeout)
        }

        if let idleTimeout {
            copy.timeoutIntervalForRequest = idleTimeout
        }

        return copy
    }
}

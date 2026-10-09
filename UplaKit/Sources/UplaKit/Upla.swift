import Foundation

/// upla.com.tr constants and rules, ported from `Upla.cs` of UpLa for Windows.
///
/// upla.com.tr runs Chevereto 4.5.7, whose only API for users is API V1.1 (`POST /api/1/upload`).
public enum Upla {
    public static let websiteURL = URL(string: "https://upla.com.tr")!
    public static let uploadPath = "/api/1/upload"
    public static let apiKeySettingsURL = URL(string: "https://upla.com.tr/settings/api")!
    public static let signUpURL = URL(string: "https://upla.com.tr/signup")!
    public static let passwordForgotURL = URL(string: "https://upla.com.tr/account/password-forgot")!
    public static let connectedDevicesURL = URL(string: "https://upla.com.tr/upla-app/devices")!
    /// The contact page explains how to report content that breaks the terms (abuse@upla.com.tr).
    public static let reportAbuseURL = URL(string: "https://upla.com.tr/page/contact")!
    public static let apiDocumentationURL = URL(string: "https://upla.com.tr/api-v1")!
    public static let sourceCodeURL = URL(string: "https://github.com/Agnostique/UpLa-mac")!

    // Guest uploads are limited to 20 MB on upla.com.tr. Member limits are decided by the server, but a single
    // request can never exceed Cloudflare's 100 MB request body limit.
    public static let guestMaxFileSize: Int64 = 20 * 1024 * 1024
    public static let maxRequestSize: Int64 = 100_000_000

    /// Largest file one upload can send: the guest limit, or for members the request limit (upla.com.tr allows them 100 MB).
    public static func maxUploadSize(isMember: Bool) -> Int64 {
        isMember ? maxRequestSize : guestMaxFileSize
    }

    /// "100 MB" for members (decimal megabytes), "20 MB" for guests (binary megabytes), as the website states them.
    public static func maxUploadSizeText(isMember: Bool) -> String {
        isMember ? "\(maxRequestSize / 1_000_000) MB" : "\(guestMaxFileSize / 1_048_576) MB"
    }

    /// Size at which a screen recording that will be uploaded stops. A recorder that stops at this size still writes
    /// what it has buffered and finishes the file, so room is left below the upload limit.
    public static func recordingSizeLimit(isMember: Bool) -> Int64 {
        let limit = maxUploadSize(isMember: isMember)
        return limit - max(2 * 1024 * 1024, limit * 5 / 100)
    }

    public static let imageExtensions = ["jpg", "jpeg", "png", "bmp", "gif", "webp"]
    // The video formats enabled on upla.com.tr (Chevereto 4.1+). mov is left out: browsers often cannot play it.
    public static let videoExtensions = ["mp4", "webm"]

    /// Images first, then videos: the list an "unsupported file type" message shows.
    public static var supportedExtensions: [String] {
        imageExtensions + videoExtensions
    }

    // Chevereto expiration values (ISO 8601 durations), same as upla.com.tr's own upload form.
    public static let expirationPresets = [
        "PT5M", "PT15M", "PT30M", "PT1H", "PT3H", "PT6H", "PT12H", "P1D", "P2D", "P3D", "P4D", "P5D", "P6D",
        "P1W", "P2W", "P3W", "P1M", "P2M", "P3M", "P4M", "P5M", "P6M", "P1Y"
    ]

    /// Case-insensitive; a leading dot and surrounding spaces are allowed (".PNG").
    public static func isSupportedExtension(_ ext: String) -> Bool {
        let normalized = normalizeExtension(ext)
        return imageExtensions.contains(normalized) || videoExtensions.contains(normalized)
    }

    public static func isVideoExtension(_ ext: String) -> Bool {
        videoExtensions.contains(normalizeExtension(ext))
    }

    /// Content type of the file part; unknown extensions are sent as application/octet-stream.
    public static func mimeType(forExtension ext: String) -> String {
        switch normalizeExtension(ext) {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "bmp": return "image/bmp"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "mp4": return "video/mp4"
        case "webm": return "video/webm"
        default: return "application/octet-stream"
        }
    }

    /// The text after the last dot of a file name, without the dot ("" when there is none). Like ShareX's
    /// GetFileNameExtension, "tar" is kept as part of a double extension ("a.tar.gz" -> "tar.gz").
    public static func fileExtension(of fileName: String) -> String {
        let scalars = Array(fileName.unicodeScalars)

        guard let dot = scalars.lastIndex(of: ".") else {
            return ""
        }

        var ext = string(scalars[(dot + 1)...])
        let rest = scalars[..<dot]

        if let secondDot = rest.lastIndex(of: ".") {
            let second = string(rest[(secondDot + 1)...])

            if second.lowercased() == "tar" {
                ext = second + "." + ext
            }
        }

        return ext
    }

    /// Accepts an album link (https://upla.com.tr/album/Name.AbCd, .../album/AbCd) or the encoded album ID.
    public static func parseAlbumID(_ album: String) -> String {
        let trimmed = album.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return ""
        }

        var value = Array(trimmed.unicodeScalars)

        if let query = value.firstIndex(where: { $0 == "?" || $0 == "#" }) {
            value.removeSubrange(query...)
        }

        while value.last == "/" {
            value.removeLast()
        }

        if let slash = value.lastIndex(of: "/") {
            value.removeSubrange(...slash)
        }

        if let dot = value.lastIndex(of: ".") {
            value.removeSubrange(...dot)
        }

        return string(value[...])
    }

    /// Chevereto drops tags longer than 32 characters or containing ',', '/' or '#'. Duplicates are removed without
    /// regard to case; the first spelling is kept.
    public static func normalizeTags(_ tags: String) -> String {
        if tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ""
        }

        var seen = Set<String>()
        var result: [String] = []

        for part in tags.components(separatedBy: ",") {
            var tag = part.replacingOccurrences(of: "/", with: "")
                .replacingOccurrences(of: "#", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if tag.isEmpty {
                continue
            }

            // 32 UTF-16 units like the Windows app, without cutting a surrogate pair in half.
            if tag.utf16.count > 32 {
                tag = prefix(tag, utf16Count: 32).trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if seen.insert(tag.uppercased()).inserted {
                result.append(tag)
            }
        }

        return result.joined(separator: ",")
    }

    /// Keys never contain whitespace, but a key copied from a web page can carry spaces or line breaks, which would
    /// make the X-API-Key header invalid.
    public static func normalizeAPIKey(_ key: String) -> String {
        var scalars = String.UnicodeScalarView()
        scalars.append(contentsOf: key.unicodeScalars.filter { !$0.properties.isWhitespace && $0.properties.generalCategory != .control })
        return String(scalars)
    }

    /// Name of this computer's key on the website's "Connected devices" page, e.g. "MacBook-Pro (5f3e9a1c)": the computer
    /// name and the first 8 hex digits of the random per-install ID. Signing in again replaces the key with the same
    /// name, so the ID keeps two Macs with the same name apart. The server keeps only 60 characters and names an empty
    /// device "Windows", so a long computer name is shortened to keep the ID and an empty one becomes "Mac".
    public static func deviceName(computerName: String, installID: String) -> String {
        let maxLength = 60
        let id = installID.replacingOccurrences(of: "-", with: "").lowercased()
        var nameScalars = String.UnicodeScalarView()
        nameScalars.append(contentsOf: computerName.unicodeScalars.filter { $0.properties.generalCategory != .control })
        var name = String(nameScalars).trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            name = "Mac"
        }

        guard id.count >= 8 else {
            return prefix(name, scalarCount: maxLength).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let suffix = " (\(id.prefix(8)))"
        let shortName = prefix(name, scalarCount: maxLength - suffix.unicodeScalars.count).trimmingCharacters(in: .whitespacesAndNewlines)
        return shortName + suffix
    }

    /// The profile link as a full URL on `site`. Until October 2026 upla.com.tr sent it as a path ("/name"), like
    /// `GetProfileURL` of UpLa for Windows handles; links to other hosts or with other schemes are not used.
    public static func profileURL(_ text: String?, site: URL = websiteURL) -> URL? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty,
              let url = URL(string: text, relativeTo: site)?.absoluteURL,
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host?.lowercased(), host == site.host?.lowercased() else {
            return nil
        }

        return url
    }

    // MARK: - Internal helpers

    /// Joins the website address and a path like the Windows app (WebsiteURL.TrimEnd('/') + path), so a base URL with
    /// a path keeps it.
    static func endpoint(_ baseURL: URL, _ path: String) -> URL {
        var base = baseURL.absoluteString

        while base.hasSuffix("/") {
            base.removeLast()
        }

        return URL(string: base + path) ?? baseURL.appendingPathComponent(path)
    }

    static func normalizeExtension(_ ext: String) -> String {
        var value = Substring(ext.trimmingCharacters(in: .whitespacesAndNewlines))

        while value.hasPrefix(".") {
            value.removeFirst()
        }

        return value.lowercased()
    }

    private static func string(_ scalars: ArraySlice<Unicode.Scalar>) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    private static func prefix(_ text: String, utf16Count limit: Int) -> String {
        var count = 0
        var view = String.UnicodeScalarView()

        for scalar in text.unicodeScalars {
            let length = scalar.utf16.count

            if count + length > limit {
                break
            }

            count += length
            view.append(scalar)
        }

        return String(view)
    }

    private static func prefix(_ text: String, scalarCount limit: Int) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: text.unicodeScalars.prefix(max(0, limit)))
        return String(view)
    }
}

import XCTest
@testable import UplaKit

/// Constants, limits and the album/tag/key/device rules (cases ported from the Windows app's harness).
final class UplaTests: XCTestCase {
    func testWebsiteLinks() {
        XCTAssertEqual(Upla.websiteURL.absoluteString, "https://upla.com.tr")
        XCTAssertEqual(Upla.uploadPath, "/api/1/upload")
        XCTAssertEqual(Upla.signUpURL.absoluteString, "https://upla.com.tr/signup")
        XCTAssertEqual(Upla.passwordForgotURL.absoluteString, "https://upla.com.tr/account/password-forgot")
        XCTAssertEqual(Upla.connectedDevicesURL.absoluteString, "https://upla.com.tr/upla-app/devices")
        XCTAssertEqual(Upla.apiKeySettingsURL.absoluteString, "https://upla.com.tr/settings/api")
        XCTAssertEqual(Upla.apiDocumentationURL.absoluteString, "https://upla.com.tr/api-v1")
        XCTAssertEqual(Upla.sourceCodeURL.absoluteString, "https://github.com/Agnostique/UpLa-mac")
        XCTAssertEqual(Upla.reportAbuseURL.absoluteString, "https://upla.com.tr/page/contact")
    }

    // The server sent "/name" until October 2026 (Chevereto's get_base_url() without $public); the Windows app shipped
    // a "My profile" that did nothing because of it.
    func testProfileURL() {
        XCTAssertEqual(Upla.profileURL("/test123123")?.absoluteString, "https://upla.com.tr/test123123")
        XCTAssertEqual(Upla.profileURL("ali")?.absoluteString, "https://upla.com.tr/ali")
        XCTAssertEqual(Upla.profileURL(" https://upla.com.tr/ali ")?.absoluteString, "https://upla.com.tr/ali")
        XCTAssertNil(Upla.profileURL(""))
        XCTAssertNil(Upla.profileURL(nil))
        XCTAssertNil(Upla.profileURL("https://evil.example/ali"))
        XCTAssertNil(Upla.profileURL("//evil.example/ali"))
        XCTAssertNil(Upla.profileURL("javascript:alert(1)"))

        let testSite = URL(string: "http://localhost:8090")!
        XCTAssertEqual(Upla.profileURL("/testuser", site: testSite)?.absoluteString, "http://localhost:8090/testuser")
        XCTAssertEqual(Upla.profileURL("http://localhost:8090/testuser", site: testSite)?.absoluteString, "http://localhost:8090/testuser")
        XCTAssertNil(Upla.profileURL("https://upla.com.tr/ali", site: testSite))
    }

    func testEndpointKeepsTheBasePath() {
        XCTAssertEqual(Upla.endpoint(Upla.websiteURL, Upla.uploadPath).absoluteString, "https://upla.com.tr/api/1/upload")
        XCTAssertEqual(Upla.endpoint(URL(string: "http://localhost:8090/")!, "/upla-app/login").absoluteString, "http://localhost:8090/upla-app/login")
        XCTAssertEqual(Upla.endpoint(URL(string: "http://localhost:8090/no-such-site//")!, "/upla-app/me").absoluteString,
                       "http://localhost:8090/no-such-site/upla-app/me")
    }

    func testUploadLimits() {
        XCTAssertEqual(Upla.guestMaxFileSize, 20_971_520)
        XCTAssertEqual(Upla.maxRequestSize, 100_000_000)
        XCTAssertEqual(Upla.maxUploadSize(isMember: false), 20 * 1024 * 1024)
        XCTAssertEqual(Upla.maxUploadSize(isMember: true), 100 * 1000 * 1000)
        XCTAssertEqual(Upla.maxUploadSizeText(isMember: false), "20 MB")
        XCTAssertEqual(Upla.maxUploadSizeText(isMember: true), "100 MB")
    }

    func testRecordingStopsBelowTheUploadLimit() {
        // limit - max(2 MiB, 5% of limit)
        XCTAssertEqual(Upla.recordingSizeLimit(isMember: false), 18 * 1024 * 1024)
        XCTAssertEqual(Upla.recordingSizeLimit(isMember: false), 18_874_368)
        XCTAssertEqual(Upla.recordingSizeLimit(isMember: true), 95 * 1000 * 1000)
    }

    func testSupportedExtensions() {
        XCTAssertEqual(Upla.imageExtensions, ["jpg", "jpeg", "png", "bmp", "gif", "webp"])
        XCTAssertEqual(Upla.videoExtensions, ["mp4", "webm"])
        XCTAssertEqual(Upla.supportedExtensions, ["jpg", "jpeg", "png", "bmp", "gif", "webp", "mp4", "webm"])

        for ext in ["png", "PNG", ".png", " .Jpeg ", "..gif", "webp", "BMP", "mp4", ".WEBM"] {
            XCTAssertTrue(Upla.isSupportedExtension(ext), ext)
        }

        for ext in ["mov", "zip", "", ".", "tiff", "heic", "svg", "tar.gz", "png "  + "x", "jpg.zip"] {
            XCTAssertFalse(Upla.isSupportedExtension(ext), ext)
        }

        XCTAssertTrue(Upla.isVideoExtension("MP4"))
        XCTAssertTrue(Upla.isVideoExtension(".webm"))
        XCTAssertFalse(Upla.isVideoExtension("mov"))
        XCTAssertFalse(Upla.isVideoExtension("gif"))
    }

    func testFileExtension() {
        XCTAssertEqual(Upla.fileExtension(of: "arsiv.zip"), "zip")
        XCTAssertEqual(Upla.fileExtension(of: "Ekran Resmi 2026-10-08 22.10.16.PNG"), "PNG")
        XCTAssertEqual(Upla.fileExtension(of: "kayit.tar.gz"), "tar.gz")
        XCTAssertEqual(Upla.fileExtension(of: "Kayit.TAR.gz"), "TAR.gz")
        XCTAssertEqual(Upla.fileExtension(of: "noextension"), "")
        XCTAssertEqual(Upla.fileExtension(of: "trailingdot."), "")
        XCTAssertEqual(Upla.fileExtension(of: ".png"), "png")
        XCTAssertEqual(Upla.fileExtension(of: "görüntü.webp"), "webp")
    }

    func testMimeTypes() {
        XCTAssertEqual(Upla.mimeType(forExtension: "jpg"), "image/jpeg")
        XCTAssertEqual(Upla.mimeType(forExtension: ".JPEG"), "image/jpeg")
        XCTAssertEqual(Upla.mimeType(forExtension: "png"), "image/png")
        XCTAssertEqual(Upla.mimeType(forExtension: "bmp"), "image/bmp")
        XCTAssertEqual(Upla.mimeType(forExtension: "gif"), "image/gif")
        XCTAssertEqual(Upla.mimeType(forExtension: "webp"), "image/webp")
        XCTAssertEqual(Upla.mimeType(forExtension: "mp4"), "video/mp4")
        XCTAssertEqual(Upla.mimeType(forExtension: "WEBM"), "video/webm")
        XCTAssertEqual(Upla.mimeType(forExtension: "zip"), "application/octet-stream")
        XCTAssertEqual(Upla.mimeType(forExtension: ""), "application/octet-stream")
    }

    func testExpirationPresets() {
        XCTAssertEqual(Upla.expirationPresets, [
            "PT5M", "PT15M", "PT30M", "PT1H", "PT3H", "PT6H", "PT12H", "P1D", "P2D", "P3D", "P4D", "P5D", "P6D",
            "P1W", "P2W", "P3W", "P1M", "P2M", "P3M", "P4M", "P5M", "P6M", "P1Y"
        ])
    }

    func testAlbumIDParsing() {
        let cases = [
            "https://upla.com.tr/album/Tatil.AbCd": "AbCd",
            "https://upla.com.tr/album/Tatil.2024.AbCd/": "AbCd",
            "https://upla.com.tr/album/AbCd?sort=date_desc#x": "AbCd",
            "upla.com.tr/album/Yaz-Fotoğrafları.XyZ1": "XyZ1",
            "  AbCd  ": "AbCd",
            "": "",
            "   ": "",
            "https://upla.com.tr/album/Tatil.AbCd#photos": "AbCd",
            "https://upla.com.tr/album/AbCd///": "AbCd",
            "https://upla.com.tr/album/Tatil.AbCd/?page=2": "AbCd"
        ]

        for (input, expected) in cases {
            XCTAssertEqual(Upla.parseAlbumID(input), expected, "album \(input)")
        }
    }

    func testTagNormalization() {
        XCTAssertEqual(Upla.normalizeTags(" oyun, ekran görüntüsü ,, #cs2, OYUN "), "oyun,ekran görüntüsü,cs2")
        XCTAssertEqual(Upla.normalizeTags(String(repeating: "a", count: 40)), String(repeating: "a", count: 32))
        XCTAssertEqual(Upla.normalizeTags("  , / ,#"), "")
        XCTAssertEqual(Upla.normalizeTags(""), "")
        XCTAssertEqual(Upla.normalizeTags(" oyun ,#cs2"), "oyun,cs2")
        XCTAssertEqual(Upla.normalizeTags("a/b, c#d"), "ab,cd")
        XCTAssertEqual(Upla.normalizeTags("Kedi,kedi,KEDİ"), "Kedi,KEDİ")
        // Cut at 32 characters, then the space before the cut is trimmed.
        XCTAssertEqual(Upla.normalizeTags(String(repeating: "b", count: 31) + " cdef"), String(repeating: "b", count: 31))
        // An emoji counts as two UTF-16 units and is never cut in half.
        let emoji = String(repeating: "x", count: 31) + "😀"
        XCTAssertEqual(Upla.normalizeTags(emoji), String(repeating: "x", count: 31))
    }

    func testAPIKeyNormalization() {
        XCTAssertEqual(Upla.normalizeAPIKey(" chv_Ab_1234 "), "chv_Ab_1234")
        XCTAssertEqual(Upla.normalizeAPIKey("chv_Ab\r\n_12\t34\u{00A0}"), "chv_Ab_1234")
        XCTAssertEqual(Upla.normalizeAPIKey("chv\u{0007}_x"), "chv_x")
        XCTAssertEqual(Upla.normalizeAPIKey(""), "")
    }

    func testDeviceName() {
        XCTAssertEqual(Upla.deviceName(computerName: "MacBook-Pro", installID: "5f3e9a1c2b4d4e6f8a9b0c1d2e3f4a5b"), "MacBook-Pro (5f3e9a1c)")
        XCTAssertEqual(Upla.deviceName(computerName: "MacBook-Pro", installID: "5F3E9A1C-2B4D-4E6F-8A9B-0C1D2E3F4A5B"), "MacBook-Pro (5f3e9a1c)")
        XCTAssertEqual(Upla.deviceName(computerName: "MacBook-Pro", installID: "5f3e-9a1c-2b4d"), "MacBook-Pro (5f3e9a1c)")
        XCTAssertEqual(Upla.deviceName(computerName: "MacBook-Pro", installID: ""), "MacBook-Pro")
        XCTAssertEqual(Upla.deviceName(computerName: "MacBook-Pro", installID: "1234567"), "MacBook-Pro")
        XCTAssertEqual(Upla.deviceName(computerName: "  ", installID: "1a2b3c4d"), "Mac (1a2b3c4d)")
        XCTAssertEqual(Upla.deviceName(computerName: "Alper\u{0}’s Mac\n", installID: "1a2b3c4d"), "Alper’s Mac (1a2b3c4d)")

        // The server keeps 60 characters: the computer name gives way so the ID survives.
        let long = Upla.deviceName(computerName: String(repeating: "Ğ", count: 80), installID: "1a2b3c4d")
        XCTAssertEqual(long.unicodeScalars.count, 60)
        XCTAssertTrue(long.hasSuffix(" (1a2b3c4d)"))
        XCTAssertTrue(long.hasPrefix(String(repeating: "Ğ", count: 49)))
    }
}

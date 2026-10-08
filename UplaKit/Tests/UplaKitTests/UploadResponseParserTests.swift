import XCTest
@testable import UplaKit

/// Chevereto API V1.1 answers; the fixtures and cases come from the Windows app's parser tests.
final class UploadResponseParserTests: XCTestCase {
    static let imageJSON = """
        {"status_code":200,"success":{"message":"file uploaded","code":200},"image":{"name":"a","type":"image",
        "url":"https://upla.com.tr/images/2026/10/07/a.png","url_viewer":"https://upla.com.tr/image/AbC1","url_short":"https://upla.com.tr/AbC1",
        "thumb":{"url":"https://upla.com.tr/images/2026/10/07/a.th.png"},"medium":{"url":null},"is_approved":1,
        "delete_url":"https://upla.com.tr/image/AbC1/delete/0123456789abcdef"},"status_txt":"OK"}
        """

    static func errorJSON(_ code: Int, _ message: String, status: Int = 400) -> String {
        #"{"status_code":\#(status),"error":{"message":"\#(message)","code":\#(code)},"status_txt":"Bad Request"}"#
    }

    private func parse(_ text: String?, _ status: Int?, _ linkType: UplaLinkType = .viewerPage, member: Bool = true) -> Result<UplaUploadResult, UplaUploadError> {
        UplaResponseParser.parseUpload(data: text.map { Data($0.utf8) }, statusCode: status, linkType: linkType, isMember: member)
    }

    private func error(_ text: String?, _ status: Int?, member: Bool = true) -> UplaUploadError? {
        if case .failure(let error) = parse(text, status, member: member) {
            return error
        }

        return nil
    }

    func testSuccessWithEachLinkType() throws {
        let viewer = try parse(Self.imageJSON, 200).get()
        XCTAssertEqual(viewer.url, "https://upla.com.tr/image/AbC1")
        XCTAssertEqual(viewer.viewerURL, "https://upla.com.tr/image/AbC1")
        XCTAssertEqual(viewer.directURL, "https://upla.com.tr/images/2026/10/07/a.png")
        XCTAssertEqual(viewer.shortURL, "https://upla.com.tr/AbC1")
        XCTAssertEqual(viewer.thumbnailURL, "https://upla.com.tr/images/2026/10/07/a.th.png")
        XCTAssertEqual(viewer.deletionURL, "https://upla.com.tr/image/AbC1/delete/0123456789abcdef")
        XCTAssertFalse(viewer.awaitingModeration)

        XCTAssertEqual(try parse(Self.imageJSON, 200, .directLink).get().url, "https://upla.com.tr/images/2026/10/07/a.png")
        XCTAssertEqual(try parse(Self.imageJSON, 200, .shortLink).get().url, "https://upla.com.tr/AbC1")
        XCTAssertEqual(try parse(Self.imageJSON, 201).get().url, "https://upla.com.tr/image/AbC1", "any 2xx is a success")
    }

    func testVideoWithoutShortLinkFallsBackToViewer() throws {
        let json = """
            {"status_code":200,"image":{"type":"video","mime":"video/mp4","duration":12,"url":"https://upla.com.tr/images/v.mp4",
            "url_viewer":"https://upla.com.tr/video/Vd1","url_short":null,"url_frame":"https://upla.com.tr/images/v.fr.jpeg",
            "thumb":{"url":"https://upla.com.tr/images/v.th.jpeg"},"delete_url":"https://upla.com.tr/video/Vd1/delete/xyz"}}
            """
        let result = try parse(json, 200, .shortLink).get()
        XCTAssertEqual(result.url, "https://upla.com.tr/video/Vd1")
        XCTAssertNil(result.shortURL)
        XCTAssertEqual(result.thumbnailURL, "https://upla.com.tr/images/v.th.jpeg")
        XCTAssertFalse(result.awaitingModeration, "no is_approved means approved")
    }

    func testLinkFallbackOrderIsViewerShortDirect() throws {
        let shortAndDirect = #"{"image":{"url":"https://x/d.png","url_short":"https://x/s","url_viewer":""}}"#
        XCTAssertEqual(try parse(shortAndDirect, 200, .viewerPage).get().url, "https://x/s")
        let directOnly = #"{"image":{"url":"https://x/d.png"}}"#
        XCTAssertEqual(try parse(directOnly, 200, .shortLink).get().url, "https://x/d.png")
    }

    func testAwaitingModeration() throws {
        let json = #"{"status_code":200,"image":{"url_viewer":"https://upla.com.tr/image/Md1","is_approved":0,"thumb":"x","delete_url":"https://upla.com.tr/image/Md1/delete/1"}}"#
        let result = try parse(json, 200, .directLink).get()
        XCTAssertTrue(result.awaitingModeration)
        XCTAssertEqual(result.url, "https://upla.com.tr/image/Md1", "moderated upload falls back to viewer")
        XCTAssertNil(result.thumbnailURL, "thumb that is not an object")
    }

    func testIsApprovedValues() throws {
        let cases: [(String, Bool)] = [
            ("false", true), ("0", true), (#""0""#, true), (#""false""#, true), (#""FALSE""#, true),
            ("true", false), ("1", false), ("2", false), (#""1""#, false), (#""True""#, false),
            ("null", false), (#""maybe""#, false), ("1.0", false), ("0.0", false)
        ]

        for (value, awaiting) in cases {
            let json = #"{"image":{"url_viewer":"https://x/v","is_approved":\#(value)}}"#
            XCTAssertEqual(try parse(json, 200).get().awaitingModeration, awaiting, "is_approved \(value)")
        }
    }

    func testSuccessWithoutLinksIsUnexpected() {
        XCTAssertEqual(error(#"{"status_code":200,"data":{}}"#, 200), .unexpectedResponse)
        XCTAssertEqual(error(#"{"image":{"url":"","url_viewer":null}}"#, 200), .unexpectedResponse)
        XCTAssertEqual(error(#"{"image":"https://x/v"}"#, 200), .unexpectedResponse)
        XCTAssertEqual(error("", 200), .unexpectedResponse)
    }

    func testImageInAnErrorAnswerIsNotASuccess() {
        // Only a 2xx answer counts, like the Windows app (HttpWebRequest throws for other statuses).
        XCTAssertEqual(error(Self.imageJSON, 400), .unexpectedResponse)
    }

    func testErrorCodes() {
        XCTAssertEqual(error(Self.errorJSON(100, "Invalid API key."), 400, member: true), .invalidKey(isMember: true))
        XCTAssertEqual(error(Self.errorJSON(100, "Invalid API key."), 400, member: false), .invalidKey(isMember: false))
        XCTAssertEqual(error(Self.errorJSON(100, "This API key format is no longer supported. Please generate a new API key."), 400), .oldKeyFormat)
        XCTAssertEqual(error(Self.errorJSON(101, "Yinelenen yükleme"), 400), .duplicate)
        XCTAssertEqual(error(Self.errorJSON(130, "Flooding detected. You can only upload 50 images per minute"), 400), .flood)
        XCTAssertEqual(error(Self.errorJSON(130, "Dakikada en fazla 50 dosya yükleyebilirsiniz"), 400), .rejected("Dakikada en fazla 50 dosya yükleyebilirsiniz"))
        XCTAssertEqual(error(Self.errorJSON(130, ""), 400), .emptySource)
        XCTAssertEqual(error(#"{"error":{"code":130}}"#, 400), .emptySource)
        XCTAssertEqual(error(Self.errorJSON(403, "Yasak"), 403), .forbidden)
        XCTAssertEqual(error(Self.errorJSON(600, "FFprobe error"), 400), .videoProcessing)
        XCTAssertEqual(error(Self.errorJSON(610, "Target width is greater than the original image width"), 400), .widthTooLarge)
        XCTAssertEqual(error(Self.errorJSON(614, "Disabled image format (mp4)"), 400), .fileTypeRejected)
        XCTAssertEqual(error(Self.errorJSON(310, "File too big - max 20 MB"), 400), .tooBig)
        XCTAssertEqual(error(Self.errorJSON(999, "Bilinmeyen hata"), 400), .rejected("Bilinmeyen hata"), "unknown code keeps the server message")
        XCTAssertEqual(error(#"{"error":{"code":"101","message":"x"}}"#, 400), .duplicate, "code as text")
    }

    func testKeyErrorsReportedWithCodeZero() {
        // Chevereto 4.5.7 ApiKey::verify throws these with code 0 (api.php returns the exception code).
        XCTAssertEqual(error(Self.errorJSON(0, "This API key format is no longer supported. Please generate a new API key."), 400), .oldKeyFormat)
        XCTAssertEqual(error(Self.errorJSON(0, "Invalid API key prefix"), 400, member: true), .invalidKey(isMember: true))
        XCTAssertEqual(error(Self.errorJSON(0, "Invalid API key prefix"), 400, member: false), .invalidKey(isMember: false))
        XCTAssertEqual(error(Self.errorJSON(0, "Something else"), 400), .rejected("Something else"))
    }

    func testAnswersWithoutJSON() {
        XCTAssertEqual(error("<html>404 Not Found</html>", 404), .apiDisabled)
        XCTAssertEqual(error("<html>413</html>", 413), .tooBig)
        XCTAssertEqual(error("<html>502</html>", 502), .server(502))
        XCTAssertEqual(error("", 500), .server(500))
        XCTAssertEqual(error("<html>Forbidden</html>", 403), .unexpectedResponse, "only the JSON error code 403 means forbidden")
        XCTAssertEqual(error("<html>Bad request</html>", 400), .unexpectedResponse)
        XCTAssertEqual(error(nil, nil), .connection)
        XCTAssertEqual(error(Self.errorJSON(404, "Route not found"), 404), .rejected("Route not found"), "a message wins over the status")
    }

    func testKeyCheck() {
        func check(_ text: String?, _ status: Int?) -> UplaKeyStatus {
            UplaResponseParser.parseKeyCheck(data: text.map { Data($0.utf8) }, statusCode: status)
        }

        XCTAssertEqual(check(Self.errorJSON(130, "Empty upload source"), 400), .valid)
        XCTAssertEqual(check(Self.errorJSON(100, "Invalid API key."), 400), .invalid)
        XCTAssertEqual(check(Self.errorJSON(100, "This API key format is no longer supported."), 400), .oldFormat)
        XCTAssertEqual(check(Self.errorJSON(0, "This API key format is no longer supported. Please generate a new API key."), 400), .oldFormat)
        XCTAssertEqual(check(Self.errorJSON(0, "Invalid API key prefix"), 400), .invalid)
        XCTAssertEqual(check(Self.errorJSON(403, "Forbidden"), 400), .noUploadPermission)
        XCTAssertEqual(check("<html/>", 503), .unknown("HTTP 503"))
        XCTAssertEqual(check(Self.errorJSON(999, "Bakım"), 400), .unknown("Bakım"))
        XCTAssertEqual(check(nil, nil), .unknown(""))
    }

    func testDescriptionHidesTheDeleteLink() throws {
        let result = try parse(Self.imageJSON, 200).get()
        XCTAssertFalse("\(result)".contains("0123456789abcdef"))
        XCTAssertFalse(String(reflecting: result).contains("0123456789abcdef"))
        XCTAssertTrue("\(result)".contains("https://upla.com.tr/image/AbC1"))
    }
}

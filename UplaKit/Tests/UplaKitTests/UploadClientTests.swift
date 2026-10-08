import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import UplaKit

/// The upload and key-check requests, sent to `StubURLProtocol` (no network).
final class UploadClientTests: XCTestCase {
    private var directory: TestDirectory!
    private var bodyDirectory: TestDirectory!
    private let base = URL(string: "https://upla.test")!

    override func setUpWithError() throws {
        directory = try TestDirectory()
        bodyDirectory = try TestDirectory()
        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
    }

    override func tearDown() {
        directory.remove()
        bodyDirectory.remove()
    }

    private func client(key: String = "chv_member_key", member: Bool = true, baseURL: URL? = nil) -> UplaClient {
        UplaClient(apiKey: key, isMember: member, baseURL: baseURL ?? base, configuration: StubURLProtocol.configuration(),
                   temporaryDirectory: bodyDirectory.url)
    }

    /// The single request the stub got, with its multipart fields by name (in order).
    private func sentRequest(file: StaticString = #filePath, line: UInt = #line) throws -> (request: StubURLProtocol.Captured, parts: [MultipartPart]) {
        let requests = StubURLProtocol.state.requests
        XCTAssertEqual(requests.count, 1, file: file, line: line)
        let request = try XCTUnwrap(requests.first, file: file, line: line)
        let boundary = try XCTUnwrap(MultipartParser.boundary(fromContentType: request.headers["content-type"]), file: file, line: line)
        let parts = try XCTUnwrap(MultipartParser.parse(request.body, boundary: boundary), "multipart body", file: file, line: line)
        return (request, parts)
    }

    private func fields(_ parts: [MultipartPart]) -> [String] {
        parts.filter { $0.fileName == nil }.map { "\($0.name ?? "")=\($0.text)" }
    }

    func testMemberUploadRequest() async throws {
        let image = TestImages.png(width: 800, height: 10)
        let file = try directory.file("ekran.png", image)
        let options = UplaUploadOptions(linkType: .directLink, album: "https://upla.com.tr/album/Tatil.AbCd", tags: " oyun ,#cs2",
                                        categoryID: 7, expiration: "P1W", maxWidth: 500)

        let result = try await client(key: " chv_member\n_key ").upload(fileURL: file, options: options)
        XCTAssertEqual(result.url, "https://upla.com.tr/images/2026/10/07/a.png")

        let (request, parts) = try sentRequest()
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "https://upla.test/api/1/upload")
        XCTAssertEqual(request.headers["x-api-key"], "chv_member_key", "normalized key in the header")
        XCTAssertTrue(request.headers["content-type"]?.hasPrefix("multipart/form-data; boundary=") == true)
        XCTAssertNil(request.headers["x-upla-app"])
        XCTAssertEqual(fields(parts), ["key=chv_member_key", "format=json", "album_id=AbCd", "tags=oyun,cs2", "category_id=7", "expiration=P1W", "width=500"])

        let filePart = try XCTUnwrap(parts.last)
        XCTAssertEqual(filePart.name, "source")
        XCTAssertEqual(filePart.fileName, "ekran.png")
        XCTAssertEqual(filePart.contentType, "image/png")
        XCTAssertEqual(filePart.body, image)
        XCTAssertEqual(bodyDirectory.contents, [], "the request body file is deleted")
    }

    func testWidthOnlyForWiderImages() async throws {
        let options = UplaUploadOptions(maxWidth: 500)
        let narrow = try directory.file("narrow.png", TestImages.png(width: 300, height: 10))
        _ = try await client().upload(fileURL: narrow, options: options)
        XCTAssertFalse(fields(try sentRequest().parts).contains { $0.hasPrefix("width=") }, "width sent for a narrow image")

        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
        let exact = try directory.file("exact.png", TestImages.png(width: 500, height: 10))
        _ = try await client().upload(fileURL: exact, options: options)
        XCTAssertFalse(fields(try sentRequest().parts).contains { $0.hasPrefix("width=") }, "width sent for an image exactly as wide")

        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
        let video = try directory.file("clip.mp4", Data(repeating: 0, count: 100))
        _ = try await client().upload(fileURL: video, options: options)
        let (_, parts) = try sentRequest()
        XCTAssertFalse(fields(parts).contains { $0.hasPrefix("width=") }, "width sent for a video")
        XCTAssertEqual(parts.last?.contentType, "video/mp4")

        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
        let unreadable = try directory.file("broken.jpg", Data("not really a jpeg".utf8))
        _ = try await client().upload(fileURL: unreadable, options: options)
        XCTAssertFalse(fields(try sentRequest().parts).contains { $0.hasPrefix("width=") }, "width sent for an image of unknown width")

        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
        let wide = try directory.file("wide.jpg", TestImages.jpegHeader(width: 4032, height: 3024))
        _ = try await client().upload(fileURL: wide, options: UplaUploadOptions(maxWidth: 1920))
        XCTAssertTrue(fields(try sentRequest().parts).contains("width=1920"))
    }

    func testExpirationOnlyFromThePresets() async throws {
        let file = try directory.file("a.png", TestImages.png(width: 10, height: 10))

        for (expiration, sent) in [("P9X", false), ("", false), ("p1d", false), ("PT5M", true), ("P1Y", true)] {
            StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
            _ = try await client().upload(fileURL: file, options: UplaUploadOptions(expiration: expiration))
            XCTAssertEqual(fields(try sentRequest().parts).contains("expiration=\(expiration)"), sent, expiration)
            XCTAssertEqual(fields(try sentRequest().parts).contains { $0.hasPrefix("expiration=") }, sent, expiration)
        }
    }

    func testGuestUploadSendsOnlyKeyAndFormat() async throws {
        let file = try directory.file("a.png", TestImages.png(width: 10, height: 10))
        let options = UplaUploadOptions(album: "AbCd", tags: "x", categoryID: 0, expiration: "", maxWidth: 0)
        _ = try await client(key: "guest_key", member: false).upload(fileURL: file, options: options)
        XCTAssertEqual(fields(try sentRequest().parts), ["key=guest_key", "format=json"])

        // A guest still sends the category and expiration.
        StubURLProtocol.state.reply(.json(200, UploadResponseParserTests.imageJSON), bodyDirectory: bodyDirectory.url)
        _ = try await client(key: "guest_key", member: false).upload(fileURL: file, options: UplaUploadOptions(album: "AbCd", categoryID: 2, expiration: "P1D"))
        XCTAssertEqual(fields(try sentRequest().parts), ["key=guest_key", "format=json", "category_id=2", "expiration=P1D"])
    }

    func testFileNameOverridesTheFile() async throws {
        let file = try directory.file("capture.tmp", TestImages.png(width: 10, height: 10))
        _ = try await client().upload(fileURL: file, fileName: "Ekran görüntüsü 1.PNG", options: UplaUploadOptions())
        let part = try XCTUnwrap(try sentRequest().parts.last)
        XCTAssertEqual(part.fileName, "Ekran görüntüsü 1.PNG")
        XCTAssertEqual(part.contentType, "image/png")
    }

    func testBaseURLWithPath() async throws {
        let file = try directory.file("a.gif", TestImages.gifHeader(width: 1, height: 1))
        _ = try await client(baseURL: URL(string: "https://upla.test/sub/")!).upload(fileURL: file, options: UplaUploadOptions())
        XCTAssertEqual(try sentRequest().request.url.absoluteString, "https://upla.test/sub/api/1/upload")
        XCTAssertEqual(UplaClient(apiKey: "k", isMember: false).baseURL, Upla.websiteURL)
    }

    func testChecksBeforeSending() async throws {
        let zip = try directory.file("arsiv.zip", Data(repeating: 0, count: 10))
        await assertUploadFails(client(), zip, .unsupportedFileType("zip"))

        let noExtension = try directory.file("README", Data(repeating: 0, count: 10))
        await assertUploadFails(client(), noExtension, .unsupportedFileType("README"))

        let mov = try directory.file("clip.MOV", Data(repeating: 0, count: 10))
        await assertUploadFails(client(), mov, .unsupportedFileType("MOV"))

        let guestLimit = Upla.guestMaxFileSize
        let tooBigForGuest = try directory.file("buyuk.png", size: guestLimit + 1)
        await assertUploadFails(client(member: false), tooBigForGuest, .fileTooLarge(size: guestLimit + 1, limit: guestLimit, isMember: false))

        // A link is measured by the file it points to, which is what would be sent.
        let link = directory.url.appendingPathComponent("link.png")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: tooBigForGuest)
        await assertUploadFails(client(member: false), link, .fileTooLarge(size: guestLimit + 1, limit: guestLimit, isMember: false))

        let tooBigForMember = try directory.file("buyuk.mp4", size: Upla.maxRequestSize + 1)
        await assertUploadFails(client(member: true), tooBigForMember, .fileTooLarge(size: Upla.maxRequestSize + 1, limit: Upla.maxRequestSize, isMember: true))

        await assertUploadFails(client(), directory.url.appendingPathComponent("missing.png"), .fileUnreadable)
        await assertUploadFails(client(), directory.url, .fileUnreadable, fileName: "folder.png")

        XCTAssertEqual(StubURLProtocol.state.requests.count, 0, "nothing is sent when a check fails")
    }

    func testFileAtTheLimitIsSent() async throws {
        let atGuestLimit = try directory.file("limit.webm", size: Upla.guestMaxFileSize)
        _ = try await client(member: false).upload(fileURL: atGuestLimit, options: UplaUploadOptions())
        XCTAssertEqual(StubURLProtocol.state.requests.count, 1)
    }

    func testServerErrorsAreThrown() async throws {
        let file = try directory.file("a.png", TestImages.png(width: 10, height: 10))

        StubURLProtocol.state.reply(.json(400, UploadResponseParserTests.errorJSON(100, "Invalid API key.")), bodyDirectory: bodyDirectory.url)
        await assertUploadFails(client(member: true), file, .invalidKey(isMember: true))

        StubURLProtocol.state.reply(.json(400, UploadResponseParserTests.errorJSON(100, "Invalid API key.")), bodyDirectory: bodyDirectory.url)
        await assertUploadFails(client(member: false), file, .invalidKey(isMember: false))

        StubURLProtocol.state.reply(.html(413), bodyDirectory: bodyDirectory.url)
        await assertUploadFails(client(), file, .tooBig)

        StubURLProtocol.state.reply(.html(503), bodyDirectory: bodyDirectory.url)
        await assertUploadFails(client(), file, .server(503))

        StubURLProtocol.state.reply(.json(400, UploadResponseParserTests.errorJSON(101, "Duplicated upload")), bodyDirectory: bodyDirectory.url)
        await assertUploadFails(client(), file, .duplicate)
        XCTAssertEqual(bodyDirectory.contents, [], "the request body file is deleted after a failure")
    }

    func testCancellation() async throws {
        let file = try directory.file("a.png", TestImages.png(width: 10, height: 10))
        StubURLProtocol.state.reset(bodyDirectory: bodyDirectory.url) { _ in .hang }
        let uploader = client()
        let task = Task { try await uploader.upload(fileURL: file, options: UplaUploadOptions()) }
        let arrived = await StubURLProtocol.state.waitForRequests(1)
        XCTAssertTrue(arrived)
        let started = Date()
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("a cancelled upload returned a result")
        } catch {
            XCTAssertEqual(error as? UplaUploadError, .cancelled)
        }

        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
        XCTAssertEqual(bodyDirectory.contents, [], "the request body file is deleted after cancelling")
    }

    func testCancelledBeforeStarting() async throws {
        let file = try directory.file("a.png", TestImages.png(width: 10, height: 10))
        let uploader = client()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await uploader.upload(fileURL: file, options: UplaUploadOptions())
        }

        do {
            _ = try await task.value
            XCTFail("a cancelled upload returned a result")
        } catch {
            XCTAssertEqual(error as? UplaUploadError, .cancelled)
        }

        XCTAssertEqual(StubURLProtocol.state.requests.count, 0)
    }

    func testKeyCheckRequest() async throws {
        StubURLProtocol.state.reply(.json(400, UploadResponseParserTests.errorJSON(130, "Empty upload source")))
        let status = await client(key: "chv_a+b/c=").checkKey()
        XCTAssertEqual(status, .valid)

        let request = try XCTUnwrap(StubURLProtocol.state.requests.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "https://upla.test/api/1/upload")
        XCTAssertEqual(request.headers["x-api-key"], "chv_a+b/c=")
        XCTAssertEqual(request.headers["content-type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(String(decoding: request.body, as: UTF8.self), "format=json&key=chv_a%2Bb%2Fc%3D")

        StubURLProtocol.state.reply(.json(400, UploadResponseParserTests.errorJSON(100, "Invalid API key.")))
        let invalid = await client().checkKey()
        XCTAssertEqual(invalid, .invalid)
        StubURLProtocol.state.reply(.json(403, UploadResponseParserTests.errorJSON(403, "Forbidden")))
        let forbidden = await client().checkKey()
        XCTAssertEqual(forbidden, .noUploadPermission)
        StubURLProtocol.state.reply(.html(502))
        let badGateway = await client().checkKey()
        XCTAssertEqual(badGateway, .unknown("HTTP 502"))
    }

    private func assertUploadFails(_ client: UplaClient, _ fileURL: URL, _ expected: UplaUploadError, fileName: String? = nil,
                                   file: StaticString = #filePath, line: UInt = #line) async {
        do {
            let result = try await client.upload(fileURL: fileURL, fileName: fileName, options: UplaUploadOptions())
            XCTFail("expected \(expected) but got \(result)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? UplaUploadError, expected, file: file, line: line)
        }
    }
}

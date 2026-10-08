import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import UplaKit

/// Requests over a real connection to `LoopbackServer` on 127.0.0.1: upload progress, the bytes on the wire,
/// cancelling while the server does not answer, time limits and refused connections.
final class TransferTests: XCTestCase {
    private var directory: TestDirectory!
    private var bodyDirectory: TestDirectory!
    private var server: LoopbackServer?

    override func setUpWithError() throws {
        directory = try TestDirectory()
        bodyDirectory = try TestDirectory()
    }

    override func tearDown() {
        server?.stop()
        directory.remove()
        bodyDirectory.remove()
    }

    private func start(_ handler: @escaping @Sendable (LoopbackServer.Request) -> LoopbackServer.Response?) throws -> LoopbackServer {
        let server = try LoopbackServer(handler: handler)
        self.server = server
        return server
    }

    private func uploader(_ baseURL: URL, member: Bool = true) -> UplaClient {
        UplaClient(apiKey: "chv_loopback_key", isMember: member, baseURL: baseURL, configuration: .ephemeral, temporaryDirectory: bodyDirectory.url)
    }

    func testUploadOverARealConnection() async throws {
        let server = try start { _ in
            LoopbackServer.Response(status: 200, headers: ["Content-Type": "application/json"], body: Data(UploadResponseParserTests.imageJSON.utf8))
        }

        // About 2.7 MB, so the body goes out in many pieces.
        let image = TestImages.png(width: 1200, height: 750, seed: 7)
        let file = try directory.file("büyük ekran.png", image)
        let progress = Recorder<Double>()
        let options = UplaUploadOptions(album: "AbCd", tags: "a,b", maxWidth: 1000)

        let result = try await uploader(server.baseURL).upload(fileURL: file, options: options) { progress.append($0) }
        XCTAssertEqual(result.url, "https://upla.com.tr/image/AbC1")

        let request = try XCTUnwrap(server.receivedRequests.first)
        XCTAssertEqual(server.receivedRequests.count, 1)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.path, "/api/1/upload")
        XCTAssertEqual(request.headers["x-api-key"], "chv_loopback_key")
        XCTAssertEqual(request.headers["content-length"], String(request.body.count), "sent with a length, not chunked")
        XCTAssertNil(request.headers["expect"])

        let boundary = try XCTUnwrap(MultipartParser.boundary(fromContentType: request.headers["content-type"]))
        let parts = try XCTUnwrap(MultipartParser.parse(request.body, boundary: boundary))
        XCTAssertEqual(parts.dropLast().map { "\($0.name ?? "")=\($0.text)" }, ["key=chv_loopback_key", "format=json", "album_id=AbCd", "tags=a,b", "width=1000"])
        XCTAssertEqual(parts.last?.fileName, "büyük ekran.png")
        XCTAssertEqual(parts.last?.body, image)

        let values = progress.values
        #if canImport(FoundationNetworking)
        // swift-corelibs-foundation reports every piece it sends.
        XCTAssertGreaterThan(values.count, 1, "progress is reported while the body is sent")
        #else
        // Apple's URLSession may report a fast loopback upload in a single callback.
        XCTAssertFalse(values.isEmpty, "progress is reported")
        #endif
        XCTAssertEqual(values, values.sorted(), "progress only grows")
        XCTAssertEqual(values.last ?? 0, 1, accuracy: 0.000_1)
        XCTAssertTrue(values.allSatisfy { $0 >= 0 && $0 <= 1 })
        XCTAssertEqual(bodyDirectory.contents, [])
    }

    func testUploadErrorOverARealConnection() async throws {
        let server = try start { _ in
            LoopbackServer.Response(status: 400, headers: ["Content-Type": "application/json"], body: Data(UploadResponseParserTests.errorJSON(100, "Invalid API key.").utf8))
        }

        let file = try directory.file("a.png", TestImages.png(width: 4, height: 4))

        do {
            _ = try await uploader(server.baseURL, member: true).upload(fileURL: file, options: UplaUploadOptions())
            XCTFail("an invalid key uploaded")
        } catch {
            XCTAssertEqual(error as? UplaUploadError, .invalidKey(isMember: true))
        }

        let status = await uploader(server.baseURL).checkKey()
        XCTAssertEqual(status, .invalid)
        XCTAssertEqual(server.receivedRequests.last.map { String(decoding: $0.body, as: UTF8.self) }, "format=json&key=chv_loopback_key")
    }

    func testCancelWhileTheServerDoesNotAnswer() async throws {
        let server = try start { _ in nil }
        let file = try directory.file("a.png", TestImages.png(width: 64, height: 64))
        let client = uploader(server.baseURL)
        let task = Task { try await client.upload(fileURL: file, options: UplaUploadOptions()) }
        let arrived = await server.waitForRequests(1)
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
        XCTAssertEqual(bodyDirectory.contents, [])
    }

    func testAccountRequestsOverARealConnection() async throws {
        let server = try start { request in
            switch request.path {
            case "/upla-app/login":
                return LoopbackServer.Response(status: 200, headers: ["Content-Type": "application/json"],
                                               body: Data(#"{"api_key":"chv_x","user":{"username":"ali","name":"Ali","url":"u"}}"#.utf8))
            default:
                return LoopbackServer.Response(status: 429, headers: ["Retry-After": "77"], body: Data("<html>slow down</html>".utf8))
            }
        }

        let accounts = UplaAccountClient(baseURL: server.baseURL, configuration: .ephemeral)
        let signedIn = await accounts.signIn(loginSubject: "ali", password: "pw", twoFactorCode: "1", deviceName: "Mac (1a2b3c4d)")
        XCTAssertEqual(signedIn.status, .success)
        XCTAssertEqual(signedIn.account?.username, "ali")

        let login = try XCTUnwrap(server.receivedRequests.first)
        XCTAssertEqual(login.headers["x-upla-app"], "1")
        XCTAssertEqual(login.headers["content-type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(String(decoding: login.body, as: UTF8.self), "login-subject=ali&password=pw&device=Mac+%281a2b3c4d%29&two-factor-code=1")

        let limited = await accounts.account(apiKey: "chv_x")
        XCTAssertEqual(limited.status, .tooManyAttempts)
        XCTAssertEqual(limited.retryAfterSeconds, 77)
        XCTAssertEqual(server.receivedRequests.last?.headers["x-api-key"], "chv_x")
    }

    func testAccountTimeLimit() async throws {
        let server = try start { _ in nil }
        let started = Date()
        let result = await UplaAccountClient(baseURL: server.baseURL, configuration: .ephemeral, timeout: 1).account(apiKey: "chv_x")
        XCTAssertEqual(result.status, .connectionError)
        XCTAssertLessThan(Date().timeIntervalSince(started), 10)
    }

    func testAccountCancellation() async throws {
        let server = try start { _ in nil }
        let accounts = UplaAccountClient(baseURL: server.baseURL, configuration: .ephemeral)
        let task = Task { await accounts.signOut(apiKey: "chv_x") }
        let arrived = await server.waitForRequests(1)
        XCTAssertTrue(arrived)
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result.status, .cancelled)
    }

    func testRefusedConnection() async throws {
        let closed = URL(string: "http://127.0.0.1:\(LoopbackServer.unusedPort())")!
        let file = try directory.file("a.png", TestImages.png(width: 4, height: 4))

        do {
            _ = try await uploader(closed).upload(fileURL: file, options: UplaUploadOptions())
            XCTFail("uploaded to a closed port")
        } catch {
            XCTAssertEqual(error as? UplaUploadError, .connection)
        }

        let keyStatus = await uploader(closed).checkKey()
        XCTAssertEqual(keyStatus, .unknown(""))
        let account = await UplaAccountClient(baseURL: closed, configuration: .ephemeral).signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x")
        XCTAssertEqual(account.status, .connectionError)
        XCTAssertEqual(bodyDirectory.contents, [])
    }
}

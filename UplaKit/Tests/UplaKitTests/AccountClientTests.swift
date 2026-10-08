import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import UplaKit

/// The sign-in, account and sign-out requests, sent to `StubURLProtocol` (no network).
final class AccountClientTests: XCTestCase {
    private let base = URL(string: "https://upla.test")!
    private static let signedIn = #"{"status_code":200,"api_key":"chv_new_device_key","user":{"username":"ali","name":"Ali Veli","url":"https://upla.test/ali"},"status_txt":"OK"}"#

    override func setUp() {
        StubURLProtocol.state.reply(.json(200, Self.signedIn))
    }

    private func client(baseURL: URL? = nil, timeout: TimeInterval = 30) -> UplaAccountClient {
        UplaAccountClient(baseURL: baseURL ?? base, configuration: StubURLProtocol.configuration(), timeout: timeout)
    }

    private func onlyRequest(file: StaticString = #filePath, line: UInt = #line) throws -> StubURLProtocol.Captured {
        let requests = StubURLProtocol.state.requests
        XCTAssertEqual(requests.count, 1, file: file, line: line)
        return try XCTUnwrap(requests.first, file: file, line: line)
    }

    func testSignInRequest() async throws {
        let result = await client().signIn(loginSubject: "  ali@example.com \n", password: " p@ss wörd&= ", twoFactorCode: "123 456",
                                           deviceName: "Alper’s MacBook (1a2b3c4d)")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.apiKey, "chv_new_device_key")
        XCTAssertEqual(result.account, UplaAccount(username: "ali", name: "Ali Veli", profileURL: "https://upla.test/ali"))

        let request = try onlyRequest()
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "https://upla.test/upla-app/login")
        XCTAssertEqual(request.headers["x-upla-app"], "1")
        XCTAssertEqual(request.headers["content-type"], "application/x-www-form-urlencoded")
        XCTAssertNil(request.headers["x-api-key"])
        XCTAssertEqual(String(decoding: request.body, as: UTF8.self),
                       "login-subject=ali%40example.com&password=+p%40ss+w%C3%B6rd%26%3D+&device=Alper%E2%80%99s+MacBook+%281a2b3c4d%29&two-factor-code=123456")
    }

    func testTwoFactorCodeIsSentOnlyWithDigits() async throws {
        for code in [nil, "", "abc", " - "] as [String?] {
            StubURLProtocol.state.reply(.json(401, #"{"error":{"code":"two_factor_required","message":"x"}}"#))
            let result = await client().signIn(loginSubject: "ali", password: "pw", twoFactorCode: code, deviceName: "Mac (1a2b3c4d)")
            XCTAssertEqual(result.status, .twoFactorRequired)
            XCTAssertEqual(String(decoding: try onlyRequest().body, as: UTF8.self), "login-subject=ali&password=pw&device=Mac+%281a2b3c4d%29", String(describing: code))
        }

        StubURLProtocol.state.reply(.json(200, Self.signedIn))
        _ = await client().signIn(loginSubject: "ali", password: "pw", twoFactorCode: "１２３４５６", deviceName: "Mac")
        XCTAssertTrue(String(decoding: try onlyRequest().body, as: UTF8.self).hasSuffix("&two-factor-code=123456"))
    }

    func testAccountRequest() async throws {
        StubURLProtocol.state.reply(.json(200, #"{"status_code":200,"user":{"username":"ali","name":"","url":"https://upla.test/ali"}}"#))
        let result = await client().account(apiKey: " chv_a\nb ")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.account?.username, "ali")
        XCTAssertEqual(result.apiKey, "")

        let request = try onlyRequest()
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.url.absoluteString, "https://upla.test/upla-app/me")
        XCTAssertEqual(request.headers["x-upla-app"], "1")
        XCTAssertEqual(request.headers["x-api-key"], "chv_ab")
        XCTAssertEqual(request.body, Data())
    }

    func testSignOutRequest() async throws {
        StubURLProtocol.state.reply(.json(200, #"{"status_code":200,"success":{"message":"Signed out."}}"#))
        let result = await client().signOut(apiKey: "chv_key")
        XCTAssertEqual(result.status, .success)

        let request = try onlyRequest()
        XCTAssertEqual(request.url.absoluteString, "https://upla.test/upla-app/logout")
        XCTAssertEqual(request.headers["x-api-key"], "chv_key")
        XCTAssertEqual(request.headers["x-upla-app"], "1")

        StubURLProtocol.state.reply(.json(401, #"{"error":{"code":"invalid_key","message":"Invalid API key."}}"#))
        let again = await client().signOut(apiKey: "chv_key")
        XCTAssertEqual(again.status, .invalidKey)
    }

    func testEmptyKeyIsNotSent() async throws {
        StubURLProtocol.state.reply(.json(401, #"{"error":{"code":"invalid_key","message":"Invalid API key."}}"#))
        let result = await client().account(apiKey: "  ")
        XCTAssertEqual(result.status, .invalidKey)
        XCTAssertNil(try onlyRequest().headers["x-api-key"])
    }

    func testRetryAfterHeader() async {
        StubURLProtocol.state.reply(.html(429, headers: ["Retry-After": "120"]))
        let cloudflare = await client().signIn(loginSubject: "ali", password: "pw", twoFactorCode: nil, deviceName: "Mac")
        XCTAssertEqual(cloudflare.status, .tooManyAttempts)
        XCTAssertEqual(cloudflare.retryAfterSeconds, 120)

        StubURLProtocol.state.reply(.json(429, #"{"error":{"code":"too_many_attempts","message":"x"},"retry_after":3600}"#, headers: ["Retry-After": "60"]))
        let upla = await client().signIn(loginSubject: "ali", password: "pw", twoFactorCode: nil, deviceName: "Mac")
        XCTAssertEqual(upla.status, .tooManyAttempts)
        XCTAssertEqual(upla.retryAfterSeconds, 3600, "retry_after wins over the header")

        StubURLProtocol.state.reply(.html(429, headers: ["Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT"]))
        let dated = await client().signIn(loginSubject: "ali", password: "pw", twoFactorCode: nil, deviceName: "Mac")
        XCTAssertEqual(dated.retryAfterSeconds, 0)
    }

    func testStatusesFromTheServer() async {
        StubURLProtocol.state.reply(.html(404))
        let missing = await client(baseURL: URL(string: "https://upla.test/no-such-site/")!).signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x")
        XCTAssertEqual(missing.status, .notSupported)
        XCTAssertEqual(StubURLProtocol.state.requests.first?.url.absoluteString, "https://upla.test/no-such-site/upla-app/login")

        StubURLProtocol.state.reply(.html(403, "403 Forbidden"))
        let blocked = await client().signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x")
        XCTAssertEqual(blocked.status, .blocked)

        StubURLProtocol.state.reply(.json(403, #"{"error":{"code":"account_banned","message":"This account is banned."}}"#))
        let banned = await client().signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x")
        XCTAssertEqual(banned.status, .accountBanned)

        StubURLProtocol.state.reply(.html(200, "<html>Bakım</html>"))
        let maintenance = await client().account(apiKey: "chv_x")
        XCTAssertEqual(maintenance.status, .unexpectedPage)
    }

    func testCancellation() async {
        StubURLProtocol.state.reset { _ in .hang }
        let accounts = client()
        let task = Task { await accounts.signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x") }
        let arrived = await StubURLProtocol.state.waitForRequests(1)
        XCTAssertTrue(arrived)
        let started = Date()
        task.cancel()
        let result = await task.value
        XCTAssertEqual(result.status, .cancelled)
        XCTAssertEqual(result.apiKey, "")
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    func testTimeoutIsAConnectionError() async {
        StubURLProtocol.state.reset { _ in .hang }
        let started = Date()
        let result = await client(timeout: 1).signIn(loginSubject: "a", password: "b", twoFactorCode: nil, deviceName: "x")
        XCTAssertEqual(result.status, .connectionError)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.9)
        XCTAssertLessThan(Date().timeIntervalSince(started), 10)
    }

    func testDefaults() {
        let accounts = UplaAccountClient()
        XCTAssertEqual(accounts.baseURL, Upla.websiteURL)
        XCTAssertEqual(accounts.timeout, 30)
    }
}

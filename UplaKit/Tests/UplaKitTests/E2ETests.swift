import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import UplaKit

/// End-to-end tests against a LOCAL Chevereto 4.5.7 test site that has the upla-app route, never upla.com.tr.
/// Skipped unless both variables are set:
///
///     UPLA_E2E_BASE_URL=http://localhost:8090 UPLA_E2E_CREDS=/path/to/e2e-creds.json swift test --filter E2ETests
///
/// The credentials file holds {"testuser": {"username", "password"}, "test2fa": {"username", "password", "totp_secret"},
/// "testbanned": {"username", "password"}}; nothing from it is ever printed. The wrong-password test is a failed sign-in
/// and the site allows 5 per hour from one IP, so reset the site's failed sign-ins before repeated runs.
/// Every key a test creates is signed out again (an account may hold at most 10 device keys).
final class E2ETests: XCTestCase {
    private struct Account {
        let username: String
        let password: String
        let totpSecret: String
    }

    // Signing in again with the same device name replaces that key, so interrupted runs never pile up keys.
    private let deviceName = "UplaKit E2E (e2e0c0de)"
    private var baseURL: URL!
    private var accounts: [String: Account] = [:]
    private var keysToSignOut: [String] = []
    private var directory: TestDirectory!

    override func setUpWithError() throws {
        let environment = ProcessInfo.processInfo.environment

        guard let base = environment["UPLA_E2E_BASE_URL"], !base.isEmpty,
              let credentialsPath = environment["UPLA_E2E_CREDS"], !credentialsPath.isEmpty else {
            throw XCTSkip("Set UPLA_E2E_BASE_URL and UPLA_E2E_CREDS to run the end-to-end tests against a local test site.")
        }

        let url = try XCTUnwrap(URL(string: base), "UPLA_E2E_BASE_URL is not a URL")
        let host = url.host?.lowercased() ?? ""

        // The tests sign in, upload and sign out, so they run only against a test site on this computer. An allowlist:
        // a denylist of upla.com.tr misses "upla.com.tr." and other names or addresses of the real server.
        guard ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host) else {
            throw XCTSkip("The end-to-end tests only run against a test site on this computer (localhost).")
        }

        baseURL = url
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: credentialsPath)))
        let root = try XCTUnwrap(json as? [String: Any], "credentials file is not a JSON object")

        for name in ["testuser", "test2fa", "testbanned"] {
            let entry = try XCTUnwrap(root[name] as? [String: Any], "credentials file lacks \(name)")
            let username = try XCTUnwrap(entry["username"] as? String, "credentials file lacks \(name).username")
            let password = try XCTUnwrap(entry["password"] as? String, "credentials file lacks \(name).password")
            accounts[name] = Account(username: username, password: password, totpSecret: entry["totp_secret"] as? String ?? "")
        }

        directory = try TestDirectory()
    }

    override func tearDown() async throws {
        let client = UplaAccountClient(baseURL: baseURL ?? URL(string: "http://127.0.0.1:9")!)

        for key in keysToSignOut {
            _ = await client.signOut(apiKey: key)
        }

        keysToSignOut = []
        directory?.remove()
    }

    private func account(_ name: String) throws -> Account {
        try XCTUnwrap(accounts[name], name)
    }

    func testMemberSignInUploadAndSignOut() async throws {
        let user = try account("testuser")
        let client = UplaAccountClient(baseURL: baseURL)

        let signIn = await client.signIn(loginSubject: "  \(user.username) ", password: user.password, twoFactorCode: nil, deviceName: deviceName)
        XCTAssertEqual(signIn.status, .success)
        guard signIn.isSuccess else {
            return
        }

        let key = signIn.apiKey
        keysToSignOut.append(key)
        XCTAssertTrue(key.hasPrefix("chv_"), "a Chevereto user key")
        XCTAssertEqual(signIn.account?.username.lowercased(), user.username.lowercased())
        XCTAssertFalse(signIn.account?.profileURL.isEmpty ?? true, "profile link")

        let me = await client.account(apiKey: key)
        XCTAssertEqual(me.status, .success)
        XCTAssertEqual(me.account?.username, signIn.account?.username)
        XCTAssertTrue(me.apiKey.isEmpty)

        let uploader = UplaClient(apiKey: key, isMember: true, baseURL: baseURL)
        let keyStatus = await uploader.checkKey()
        XCTAssertEqual(keyStatus, .valid)

        // A fresh image each run: Chevereto refuses the same file twice within a day (error 101).
        let seed = UInt64(Date().timeIntervalSince1970 * 1000)
        let image = try directory.file("uplakit-e2e.png", TestImages.png(width: 64, height: 48, seed: seed))
        let progress = Recorder<Double>()
        let uploaded = try await uploader.upload(fileURL: image, options: UplaUploadOptions(linkType: .viewerPage)) { progress.append($0) }
        XCTAssertTrue(uploaded.url.hasPrefix("http"), "a link to share")
        XCTAssertNotNil(uploaded.viewerURL)
        XCTAssertNotNil(uploaded.deletionURL)
        XCTAssertEqual(progress.values.last ?? 0, 1, accuracy: 0.000_1, "progress reaches the end")

        // The resize width goes out only because the image is wider; the server then resizes it (no error 610).
        let wide = try directory.file("uplakit-e2e-wide.png", TestImages.png(width: 96, height: 16, seed: seed &+ 1))
        let resized = try await uploader.upload(fileURL: wide, options: UplaUploadOptions(linkType: .directLink, tags: "uplakit,e2e", maxWidth: 32))
        XCTAssertTrue(resized.url.hasPrefix("http"))

        let signOut = await client.signOut(apiKey: key)
        XCTAssertEqual(signOut.status, .success)
        keysToSignOut.removeAll { $0 == key }

        let afterSignOut = await client.account(apiKey: key)
        XCTAssertEqual(afterSignOut.status, .invalidKey, "the key was deleted")
        let signOutAgain = await client.signOut(apiKey: key)
        XCTAssertEqual(signOutAgain.status, .invalidKey)

        do {
            let result = try await uploader.upload(fileURL: image, options: UplaUploadOptions())
            XCTFail("uploaded with a deleted key: \(result.url)")
        } catch {
            XCTAssertEqual(error as? UplaUploadError, .invalidKey(isMember: true))
        }

        let oldKeyStatus = await uploader.checkKey()
        XCTAssertEqual(oldKeyStatus, .invalid)
    }

    func testTwoStepSignIn() async throws {
        let user = try account("test2fa")
        XCTAssertFalse(user.totpSecret.isEmpty, "credentials file lacks test2fa.totp_secret")
        let client = UplaAccountClient(baseURL: baseURL)

        let withoutCode = await client.signIn(loginSubject: user.username, password: user.password, twoFactorCode: nil, deviceName: deviceName)
        XCTAssertEqual(withoutCode.status, .twoFactorRequired)
        XCTAssertTrue(withoutCode.apiKey.isEmpty)

        let code = try XCTUnwrap(TOTP.code(base32Secret: user.totpSecret), "TOTP secret is not base32")
        // Spaces as people type them from an authenticator app.
        let typed = String(code.prefix(3)) + " " + String(code.suffix(3))
        let withCode = await client.signIn(loginSubject: user.username, password: user.password, twoFactorCode: typed, deviceName: deviceName)
        XCTAssertEqual(withCode.status, .success)
        guard withCode.isSuccess else {
            return
        }

        keysToSignOut.append(withCode.apiKey)
        XCTAssertEqual(withCode.account?.username.lowercased(), user.username.lowercased())

        let signOut = await client.signOut(apiKey: withCode.apiKey)
        XCTAssertEqual(signOut.status, .success)
        keysToSignOut.removeAll { $0 == withCode.apiKey }
    }

    func testBannedAccount() async throws {
        let user = try account("testbanned")
        let result = await UplaAccountClient(baseURL: baseURL).signIn(loginSubject: user.username, password: user.password, twoFactorCode: nil, deviceName: deviceName)
        XCTAssertEqual(result.status, .accountBanned)
        XCTAssertTrue(result.apiKey.isEmpty)
    }

    func testWrongPassword() async throws {
        let user = try account("testuser")
        let result = await UplaAccountClient(baseURL: baseURL).signIn(loginSubject: user.username, password: user.password + "x", twoFactorCode: nil, deviceName: deviceName)
        XCTAssertEqual(result.status, .invalidCredentials)
        XCTAssertTrue(result.apiKey.isEmpty)
    }

    func testSiteWithoutTheRoute() async {
        // The route does not exist there, so no real password is needed.
        let result = await UplaAccountClient(baseURL: baseURL.appendingPathComponent("no-such-site")).signIn(loginSubject: "nobody", password: "whatever",
                                                                                                          twoFactorCode: nil, deviceName: deviceName)
        XCTAssertEqual(result.status, .notSupported)
    }
}

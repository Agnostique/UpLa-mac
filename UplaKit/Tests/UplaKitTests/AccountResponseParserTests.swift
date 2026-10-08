import XCTest
@testable import UplaKit

/// Answers of the upla-app route; the cases come from the Windows app's sign-in parser tests.
final class AccountResponseParserTests: XCTestCase {
    private func parse(_ text: String?, _ status: Int?, action: String = "login", retryAfterHeader: Int = 0) -> UplaAccountResult {
        UplaAccountClient.parseResponse(data: text.map { Data($0.utf8) }, statusCode: status, action: action, retryAfterHeader: retryAfterHeader)
    }

    private func accountError(_ status: Int, _ code: String, message: String = "x", extra: String = "") -> String {
        #"{"status_code":\#(status),"error":{"code":"\#(code)","message":"\#(message)"}\#(extra)}"#
    }

    func testSignInSuccess() {
        let result = parse(#"{"status_code":200,"api_key":" chv_Ab_1234 ","user":{"username":"ali","name":"Ali Veli","url":"https://upla.com.tr/ali"},"status_txt":"OK"}"#, 200)
        XCTAssertEqual(result.status, .success)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.apiKey, "chv_Ab_1234", "key is normalized")
        XCTAssertEqual(result.account, UplaAccount(username: "ali", name: "Ali Veli", profileURL: "https://upla.com.tr/ali"))
        XCTAssertEqual(result.retryAfterSeconds, 0)
    }

    func testAccountAndSignOutSuccess() {
        let me = parse(#"{"status_code":200,"user":{"username":"ali","name":"","url":""}}"#, 200, action: "me")
        XCTAssertTrue(me.isSuccess)
        XCTAssertEqual(me.apiKey, "")
        XCTAssertEqual(me.account?.username, "ali")
        XCTAssertEqual(me.account?.name, "")

        let logout = parse(#"{"status_code":200,"success":{"message":"Signed out."}}"#, 200, action: "logout")
        XCTAssertEqual(logout.status, .success)
        XCTAssertNil(logout.account)
    }

    func testIncompleteSuccessIsUnexpected() {
        XCTAssertEqual(parse(#"{"status_code":200,"user":{"username":"ali"}}"#, 200).status, .unexpectedResponse, "login 200 without a key")
        XCTAssertEqual(parse(#"{"status_code":200,"api_key":"chv_a_b_c"}"#, 200).status, .unexpectedResponse, "login 200 without a user")
        XCTAssertEqual(parse(#"{"status_code":200}"#, 200, action: "me").status, .unexpectedResponse, "me 200 without a user")
        XCTAssertEqual(parse(#"{"api_key":"chv_a","user":{"username":"ali"},"error":null}"#, 200).status, .unexpectedResponse, "an error member, even null")
        XCTAssertEqual(parse(#"{"api_key":"chv_a","user":{"username":"ali"}}"#, 201).status, .unexpectedResponse, "only 200 is a success")
    }

    func testErrorCodes() {
        let cases: [(Int, String, UplaAccountStatus)] = [
            (401, "two_factor_required", .twoFactorRequired),
            (401, "invalid_credentials", .invalidCredentials),
            (400, "missing_fields", .invalidCredentials),
            (401, "invalid_two_factor_code", .invalidTwoFactorCode),
            (403, "account_banned", .accountBanned),
            (403, "account_awaiting_confirmation", .accountAwaitingConfirmation),
            (403, "account_awaiting_email", .accountAwaitingEmail),
            (403, "account_not_valid", .accountNotValid),
            (401, "invalid_key", .invalidKey),
            (403, "api_disabled", .apiDisabled),
            (418, "something_new", .failed("x")),
            (500, "server_error", .failed("x"))
        ]

        for (status, code, expected) in cases {
            let result = parse(accountError(status, code) , status)
            XCTAssertEqual(result.status, expected, code)
            XCTAssertEqual(result.apiKey, "", "\(code) has no key")
            XCTAssertNil(result.account, code)
        }

        XCTAssertEqual(parse(accountError(400, "something_new", message: ""), 400).status, .unexpectedResponse, "unknown code without a message")
        XCTAssertEqual(parse(#"{"error":{"message":"Hata"}}"#, 400).status, .failed("Hata"), "no code")
    }

    func testTooManyAttempts() {
        let hour = parse(accountError(429, "too_many_attempts", extra: #","retry_after":3600"#), 429)
        XCTAssertEqual(hour.status, .tooManyAttempts)
        XCTAssertEqual(hour.retryAfterSeconds, 3600)

        let day = parse(accountError(429, "too_many_attempts", extra: #","retry_after":86400"#), 429, retryAfterHeader: 60)
        XCTAssertEqual(day.retryAfterSeconds, 86400, "retry_after wins over the header")

        let text = parse(accountError(429, "too_many_attempts", extra: #","retry_after":" 120 ""#), 429)
        XCTAssertEqual(text.retryAfterSeconds, 120, "retry_after as text")

        let headerOnly = parse(accountError(429, "too_many_attempts"), 429, retryAfterHeader: 3600)
        XCTAssertEqual(headerOnly.retryAfterSeconds, 3600, "the header when the JSON has none")

        let unreadable = parse(accountError(429, "too_many_attempts", extra: #","retry_after":"soon""#), 429, retryAfterHeader: 30)
        XCTAssertEqual(unreadable.retryAfterSeconds, 30)

        // Cloudflare: a JSON 429 without an upla code.
        let json429 = parse(#"{"error":{"code":1015}}"#, 429, retryAfterHeader: 0)
        XCTAssertEqual(json429.status, .tooManyAttempts)
        XCTAssertEqual(json429.retryAfterSeconds, 0)
    }

    func testAnswersWithoutJSON() {
        XCTAssertEqual(parse("<html>404</html>", 404).status, .notSupported, "no route on the server")
        XCTAssertEqual(parse("<html>Method Not Allowed</html>", 405).status, .notSupported)
        XCTAssertEqual(parse("403 Forbidden", 403).status, .blocked, "IP lockout")

        let cloudflare = parse("<html>error 1015</html>", 429, retryAfterHeader: 30)
        XCTAssertEqual(cloudflare.status, .tooManyAttempts)
        XCTAssertEqual(cloudflare.retryAfterSeconds, 30)
        XCTAssertEqual(parse("<html>1015</html>", 429, retryAfterHeader: 3600).retryAfterSeconds, 3600)

        XCTAssertEqual(parse("<html>maintenance</html>", 200).status, .unexpectedPage)
        XCTAssertEqual(parse("", 204).status, .unexpectedPage)
        XCTAssertEqual(parse("<html>bad gateway</html>", 502).status, .server(502))
        XCTAssertEqual(parse("", 500).status, .server(500))
        XCTAssertEqual(parse("<html>moved</html>", 302).status, .unexpectedResponse)
        XCTAssertEqual(parse("<html>bad</html>", 400).status, .unexpectedResponse)
        XCTAssertEqual(parse(nil, nil).status, .connectionError, "no response")
        XCTAssertEqual(parse(#"{"api_key":"chv_a"}"#, nil).status, .connectionError)
    }

    func testMalformedJSONIsNeverASuccess() {
        for text in [#"{"error":"x"}"#, #"{"user":null,"error":null}"#, #"{"user":[1,2],"api_key":{}}"#, "[]", #""text""#, "{", "null"] {
            let result = parse(text, 400)
            XCTAssertNotEqual(result.status, .success, text)
            XCTAssertEqual(result.apiKey, "", text)
        }

        XCTAssertEqual(parse(#"{"user":[1,2],"api_key":{}}"#, 200).status, .unexpectedResponse)
    }

    func testRetryAfterHeader() {
        XCTAssertEqual(UplaAccountClient.retryAfterSeconds("120"), 120)
        XCTAssertEqual(UplaAccountClient.retryAfterSeconds(" 30 "), 30)
        XCTAssertEqual(UplaAccountClient.retryAfterSeconds("Wed, 21 Oct 2026 07:28:00 GMT"), 0)
        XCTAssertEqual(UplaAccountClient.retryAfterSeconds("-5"), 0)
        XCTAssertEqual(UplaAccountClient.retryAfterSeconds(nil), 0)
    }

    func testTwoFactorCodeDigits() {
        XCTAssertEqual(UplaAccountClient.digits("123 456"), "123456")
        XCTAssertEqual(UplaAccountClient.digits(" 12-34-56\n"), "123456")
        XCTAssertEqual(UplaAccountClient.digits("abc"), "")
        XCTAssertEqual(UplaAccountClient.digits("１２３４５６"), "123456", "full-width digits")
        XCTAssertEqual(UplaAccountClient.digits("½²"), "", "other numbers are not digits")
    }

    func testDescriptionHidesTheKey() {
        let result = parse(#"{"api_key":"chv_secret_device_key","user":{"username":"veli"}}"#, 200)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse("\(result)".contains("chv_secret_device_key"))
        XCTAssertFalse(String(reflecting: result).contains("chv_secret_device_key"))
        XCTAssertTrue("\(result)".contains("veli"))
    }

    func testCodable() throws {
        let account = UplaAccount(username: "ali", name: "Ali", profileURL: "https://upla.com.tr/ali")
        XCTAssertEqual(try JSONDecoder().decode(UplaAccount.self, from: JSONEncoder().encode(account)), account)
        XCTAssertEqual(try JSONDecoder().decode(UplaAccount.self, from: Data(#"{"username":"ali"}"#.utf8)), UplaAccount(username: "ali"))

        let options = UplaUploadOptions(linkType: .shortLink, album: "AbCd", tags: "a,b", categoryID: 3, expiration: "P1D", maxWidth: 1920)
        XCTAssertEqual(try JSONDecoder().decode(UplaUploadOptions.self, from: JSONEncoder().encode(options)), options)
        XCTAssertEqual(try JSONDecoder().decode(UplaUploadOptions.self, from: Data("{}".utf8)), UplaUploadOptions())
        XCTAssertEqual(try JSONDecoder().decode(UplaUploadOptions.self, from: Data(#"{"linkType":"qrCode","album":"x"}"#.utf8)), UplaUploadOptions(album: "x"))
        XCTAssertEqual(UplaLinkType.allCases, [.viewerPage, .directLink, .shortLink])
    }
}

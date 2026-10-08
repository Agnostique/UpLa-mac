import XCTest
@testable import UplaKit

/// Checks of the test helpers themselves, so an E2E failure is never a broken helper.
final class SupportTests: XCTestCase {
    private func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    func testSHA1() {
        XCTAssertEqual(hex(TOTP.sha1([])), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssertEqual(hex(TOTP.sha1(Array("abc".utf8))), "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(hex(TOTP.sha1(Array("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".utf8))), "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
        XCTAssertEqual(hex(TOTP.sha1([UInt8](repeating: 0x61, count: 1_000))), "291e9a6c66994949b57ba5e650361e98fc36b1ba")
    }

    func testHMACSHA1() {
        // RFC 2202 test cases 2 and 6.
        XCTAssertEqual(hex(TOTP.hmacSHA1(key: Array("Jefe".utf8), message: Array("what do ya want for nothing?".utf8))), "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79")
        XCTAssertEqual(hex(TOTP.hmacSHA1(key: [UInt8](repeating: 0xAA, count: 80), message: Array("Test Using Larger Than Block-Size Key - Hash Key First".utf8))),
                       "aa4ae5e15272d00e95705637ce8a3b55ed402112")
    }

    func testTOTP() {
        // RFC 6238 appendix B (SHA-1 seed "12345678901234567890"), last 6 of the 8 digits.
        let secret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
        XCTAssertEqual(TOTP.code(base32Secret: secret, time: Date(timeIntervalSince1970: 59), digits: 8), "94287082")
        XCTAssertEqual(TOTP.code(base32Secret: secret, time: Date(timeIntervalSince1970: 1_111_111_109)), "081804")
        XCTAssertEqual(TOTP.code(base32Secret: secret, time: Date(timeIntervalSince1970: 1_234_567_890)), "005924")
        XCTAssertEqual(TOTP.code(base32Secret: secret.lowercased(), time: Date(timeIntervalSince1970: 2_000_000_000)), "279037")
        XCTAssertNil(TOTP.code(base32Secret: "not base32!"))
    }

    func testGeneratedPNGIsWellFormed() throws {
        let png = TestImages.png(width: 3, height: 2)
        XCTAssertEqual(Array(png.prefix(8)), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        XCTAssertEqual(Array(png.suffix(12)), [0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82], "IEND with its well-known CRC")
        XCTAssertNotEqual(TestImages.png(width: 3, height: 2, seed: 1), TestImages.png(width: 3, height: 2, seed: 2))
    }

    func testMultipartParserRejectsBrokenBodies() {
        XCTAssertNil(MultipartParser.parse(Data("--B\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\nx\r\n".utf8), boundary: "B"), "no closing boundary")
        XCTAssertNil(MultipartParser.parse(Data("junk--B--\r\n".utf8), boundary: "B"))
        XCTAssertEqual(MultipartParser.parse(Data("--B--\r\n".utf8), boundary: "B")?.count, 0)
    }
}

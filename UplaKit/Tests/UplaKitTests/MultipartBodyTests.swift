import XCTest
@testable import UplaKit

final class MultipartBodyTests: XCTestCase {
    private var directory: TestDirectory!

    override func setUpWithError() throws {
        directory = try TestDirectory()
    }

    override func tearDown() {
        directory.remove()
    }

    func testBoundary() {
        let boundary = MultipartBody.makeBoundary()
        XCTAssertTrue(boundary.hasPrefix(String(repeating: "-", count: 20)))
        XCTAssertEqual(boundary.count, 52)
        XCTAssertLessThanOrEqual(boundary.count, 70, "RFC 2046 limit")
        XCTAssertNotEqual(boundary, MultipartBody.makeBoundary())
        XCTAssertEqual(MultipartBody.contentType(boundary: "abc"), "multipart/form-data; boundary=abc")
    }

    func testLayoutMatchesTheWindowsApp() throws {
        let file = try directory.file("a.png", Data([1, 2, 3]))
        let output = directory.url.appendingPathComponent("body")
        try MultipartBody.write(fields: [("key", "k"), ("format", "json")], fileFieldName: "source", fileURL: file, fileName: "a.png",
                                mimeType: "image/png", boundary: "XYZ", to: output)

        let expected = "--XYZ\r\nContent-Disposition: form-data; name=\"key\"\r\n\r\nk\r\n"
            + "--XYZ\r\nContent-Disposition: form-data; name=\"format\"\r\n\r\njson\r\n"
            + "--XYZ\r\nContent-Disposition: form-data; name=\"source\"; filename=\"a.png\"\r\nContent-Type: image/png\r\n\r\n"
        XCTAssertEqual(try Data(contentsOf: output), Data(expected.utf8) + Data([1, 2, 3]) + Data("\r\n--XYZ--\r\n".utf8))
    }

    func testWriteThenParseBack() throws {
        let image = TestImages.png(width: 20, height: 10)
        let file = try directory.file("ekran görüntüsü.png", image)
        let output = directory.url.appendingPathComponent("body")
        let boundary = MultipartBody.makeBoundary()
        let fields = [("key", "chv_test"), ("format", "json"), ("tags", "oyun,ekran görüntüsü"), ("empty", ""), ("lines", "a\r\nb")]
        try MultipartBody.write(fields: fields, fileFieldName: "source", fileURL: file, fileName: "ekran görüntüsü.png", mimeType: "image/png",
                                boundary: boundary, to: output)

        let parts = try XCTUnwrap(MultipartParser.parse(try Data(contentsOf: output), boundary: boundary))
        XCTAssertEqual(parts.count, 6)
        XCTAssertEqual(parts.dropLast().map { $0.name }, ["key", "format", "tags", "empty", "lines"])
        XCTAssertEqual(parts.dropLast().map { $0.text }, ["chv_test", "json", "oyun,ekran görüntüsü", "", "a\r\nb"])
        XCTAssertTrue(parts.dropLast().allSatisfy { $0.fileName == nil && $0.contentType == nil })

        let filePart = try XCTUnwrap(parts.last)
        XCTAssertEqual(filePart.name, "source")
        XCTAssertEqual(filePart.fileName, "ekran görüntüsü.png")
        XCTAssertEqual(filePart.contentType, "image/png")
        XCTAssertEqual(filePart.body, image)
    }

    func testQuotesAndLineBreaksInNamesAreEscaped() throws {
        let file = try directory.file("x.gif", Data("GIF89a".utf8))
        let output = directory.url.appendingPathComponent("body")
        try MultipartBody.write(fields: [("a\"b\r\nc", "value \"quoted\"")], fileFieldName: "so\"urce", fileURL: file,
                                fileName: "evil\".png\r\nContent-Type: text/html", mimeType: "image/gif", boundary: "B", to: output)

        let text = String(decoding: try Data(contentsOf: output), as: UTF8.self)
        XCTAssertTrue(text.contains("Content-Disposition: form-data; name=\"a%22b%0D%0Ac\"\r\n\r\nvalue \"quoted\"\r\n"), text)
        XCTAssertTrue(text.contains("name=\"so%22urce\"; filename=\"evil%22.png%0D%0AContent-Type: text/html\"\r\nContent-Type: image/gif\r\n"), text)

        let parts = try XCTUnwrap(MultipartParser.parse(try Data(contentsOf: output), boundary: "B"))
        XCTAssertEqual(parts.count, 2)
        XCTAssertEqual(parts[1].headers.count, 2, "the file name cannot add a header line")
    }

    func testLargeFileIsStreamed() throws {
        // 24 MiB of a repeating pattern: larger than the copy buffer and than the guest limit.
        let size = 24 * 1024 * 1024
        let file = directory.url.appendingPathComponent("big.mp4")
        XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: nil))
        let writer = try FileHandle(forWritingTo: file)
        let block = Data((0..<(1024 * 1024)).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ $0 >> 8) })

        for index in 0..<(size / block.count) {
            var chunk = block
            chunk[0] = UInt8(index)
            try writer.write(contentsOf: chunk)
        }

        try writer.close()

        let output = directory.url.appendingPathComponent("body")
        try MultipartBody.write(fields: [("key", "k")], fileFieldName: "source", fileURL: file, fileName: "big.mp4", mimeType: "video/mp4",
                                boundary: "BOUNDARY", to: output)

        let head = Data("--BOUNDARY\r\nContent-Disposition: form-data; name=\"key\"\r\n\r\nk\r\n--BOUNDARY\r\nContent-Disposition: form-data; name=\"source\"; filename=\"big.mp4\"\r\nContent-Type: video/mp4\r\n\r\n".utf8)
        let tail = Data("\r\n--BOUNDARY--\r\n".utf8)
        let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
        XCTAssertEqual((attributes[.size] as? NSNumber)?.intValue, head.count + size + tail.count)

        // Compare the copied bytes block by block without loading either file whole.
        let source = try FileHandle(forReadingFrom: file)
        let body = try FileHandle(forReadingFrom: output)
        defer {
            try? source.close()
            try? body.close()
        }

        XCTAssertEqual(try body.read(upToCount: head.count), head)

        for _ in 0..<(size / block.count) {
            XCTAssertEqual(try body.read(upToCount: block.count), try source.read(upToCount: block.count))
        }

        XCTAssertEqual(try body.read(upToCount: 100), tail)
    }

    func testOutputIsPrivateAndReplaced() throws {
        let file = try directory.file("a.png", Data([1]))
        let output = try directory.file("body", Data(repeating: 7, count: 10_000))
        try MultipartBody.write(fields: [("key", "secret")], fileFieldName: "source", fileURL: file, fileName: "a.png", mimeType: "image/png",
                                boundary: "B", to: output)

        let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600, "the body holds the API key")
        XCTAssertLessThan((attributes[.size] as? NSNumber)?.intValue ?? 0, 10_000, "an old file is replaced, not appended to")
    }

    func testMissingFileFailsAndLeavesNoOutput() {
        let output = directory.url.appendingPathComponent("body")
        XCTAssertThrowsError(try MultipartBody.write(fields: [("key", "k")], fileFieldName: "source", fileURL: directory.url.appendingPathComponent("missing.png"),
                                                     fileName: "missing.png", mimeType: "image/png", boundary: "B", to: output))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }
}

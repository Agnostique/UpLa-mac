import XCTest
@testable import UplaKit

final class ImageWidthTests: XCTestCase {
    private var directory: TestDirectory!

    override func setUpWithError() throws {
        directory = try TestDirectory()
    }

    override func tearDown() {
        directory.remove()
    }

    private func width(_ data: Data, _ name: String = "image") throws -> Int? {
        ImageWidth.read(from: try directory.file(name, data))
    }

    func testPNG() throws {
        XCTAssertEqual(try width(TestImages.png(width: 800, height: 10)), 800)
        XCTAssertEqual(try width(TestImages.png(width: 1, height: 1)), 1)
    }

    func testJPEG() throws {
        XCTAssertEqual(try width(TestImages.jpegHeader(width: 4032, height: 3024)), 4032, "after 70 KB of EXIF segments")
        XCTAssertEqual(try width(TestImages.jpegHeader(width: 640, height: 480, progressive: true, exifSize: 0)), 640)
        XCTAssertEqual(try width(TestImages.jpegHeader(width: 65_535, height: 1, exifSize: 200_000)), 65_535)
    }

    func testGIFBMPAndWebP() throws {
        XCTAssertEqual(try width(TestImages.gifHeader(width: 320, height: 200)), 320)
        XCTAssertEqual(try width(TestImages.bmpHeader(width: 1024, height: -768)), 1024, "top-down bitmap")
        XCTAssertEqual(try width(TestImages.bmpHeader(width: 300, height: 20, coreHeader: true)), 300)
        XCTAssertEqual(try width(TestImages.webpLossy(width: 1920, height: 1080)), 1920)
        XCTAssertEqual(try width(TestImages.webpLossless(width: 512, height: 256)), 512)
        XCTAssertEqual(try width(TestImages.webpExtended(width: 5000, height: 3000)), 5000)
    }

    func testUnreadableImages() throws {
        XCTAssertNil(try width(Data("not an image at all, just text".utf8)))
        XCTAssertNil(try width(Data()))
        XCTAssertNil(try width(Data(TestImages.png(width: 10, height: 10).prefix(20))), "cut PNG")
        XCTAssertNil(try width(Data(TestImages.jpegHeader(width: 10, height: 10).prefix(70_010))), "JPEG cut before the frame header")
        XCTAssertNil(try width(Data([0xFF, 0xD8, 0xFF, 0xDA, 0, 2])), "scan before any frame header")
        XCTAssertNil(try width(TestImages.bmpHeader(width: -5, height: 5)))
        XCTAssertNil(ImageWidth.read(from: directory.url.appendingPathComponent("missing.png")))
        XCTAssertNil(ImageWidth.read(from: directory.url), "a folder")
    }
}

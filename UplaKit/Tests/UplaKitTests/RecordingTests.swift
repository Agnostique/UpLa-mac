import Foundation
import XCTest
@testable import UplaKit

/// The upload limit stop (numbers of UpLa for Windows), the elapsed time text, and the recorded area and video size.
final class RecordingTests: XCTestCase {
    // MARK: Upload limit

    func testGuestRecordingStopsAt18MiB() {
        let limit = RecordingLimit(isMember: false, willUpload: true, stopAtUploadLimit: true)
        XCTAssertEqual(limit.stopSize, 18_874_368)
        XCTAssertEqual(limit.stopSize, 18 * 1024 * 1024)
        XCTAssertEqual(limit.uploadLimit, 20_971_520)
        XCTAssertEqual(limit.uploadLimitText, "20 MB")
        // limit - max(2 MiB, 5% of limit)
        XCTAssertEqual(limit.uploadLimit - (limit.stopSize ?? 0), 2 * 1024 * 1024)
    }

    func testMemberRecordingStopsAt95MB() {
        let limit = RecordingLimit(isMember: true, willUpload: true, stopAtUploadLimit: true)
        XCTAssertEqual(limit.stopSize, 95_000_000)
        XCTAssertEqual(limit.uploadLimit, 100_000_000)
        XCTAssertEqual(limit.uploadLimitText, "100 MB")
        XCTAssertEqual(limit.uploadLimit - (limit.stopSize ?? 0), 5_000_000)
    }

    func testNoStopWithoutUploadOrSetting() {
        for isMember in [false, true] {
            XCTAssertNil(RecordingLimit(isMember: isMember, willUpload: false, stopAtUploadLimit: true).stopSize)
            XCTAssertNil(RecordingLimit(isMember: isMember, willUpload: true, stopAtUploadLimit: false).stopSize)
            XCTAssertNil(RecordingLimit(isMember: isMember, willUpload: false, stopAtUploadLimit: false).stopSize)
        }
    }

    func testShouldStop() {
        let guest = RecordingLimit(isMember: false, willUpload: true, stopAtUploadLimit: true)
        XCTAssertFalse(guest.shouldStop(fileSize: 0))
        XCTAssertFalse(guest.shouldStop(fileSize: 18_874_367))
        XCTAssertTrue(guest.shouldStop(fileSize: 18_874_368))
        XCTAssertTrue(guest.shouldStop(fileSize: 25_000_000))

        let member = RecordingLimit(isMember: true, willUpload: true, stopAtUploadLimit: true)
        XCTAssertFalse(member.shouldStop(fileSize: 94_999_999))
        XCTAssertTrue(member.shouldStop(fileSize: 95_000_000))

        let off = RecordingLimit(isMember: false, willUpload: true, stopAtUploadLimit: false)
        XCTAssertFalse(off.shouldStop(fileSize: Int64.max))
    }

    func testCanUploadUpToTheUploadLimit() {
        let guest = RecordingLimit(isMember: false, willUpload: true, stopAtUploadLimit: true)
        XCTAssertTrue(guest.canUpload(fileSize: 1))
        XCTAssertTrue(guest.canUpload(fileSize: 20_971_520))
        XCTAssertFalse(guest.canUpload(fileSize: 20_971_521))

        let member = RecordingLimit(isMember: true, willUpload: true, stopAtUploadLimit: true)
        XCTAssertTrue(member.canUpload(fileSize: 100_000_000))
        XCTAssertFalse(member.canUpload(fileSize: 100_000_001))

        // The upload limit applies whether or not the recording stopped at it.
        XCTAssertFalse(RecordingLimit(isMember: false, willUpload: true, stopAtUploadLimit: false).canUpload(fileSize: 30_000_000))
        XCTAssertTrue(RecordingLimit.canUpload(fileSize: 30_000_000, isMember: true))
        XCTAssertFalse(RecordingLimit.canUpload(fileSize: 30_000_000, isMember: false))
    }

    // MARK: Elapsed time

    func testElapsedTimeText() {
        let cases: [(Int, String)] = [
            (0, "0:00"), (5, "0:05"), (59, "0:59"), (60, "1:00"), (754, "12:34"), (3599, "59:59"),
            (3600, "1:00:00"), (3723, "1:02:03"), (36_000, "10:00:00"), (-5, "0:00")
        ]

        for (seconds, text) in cases {
            XCTAssertEqual(RecordingTime.text(seconds: seconds), text, "\(seconds) s")
        }
    }

    // MARK: Area and video size

    func testRegionOnARetinaScreen() {
        // AppKit coordinates: the selection's bottom is at y = 600, its top at y = 800 of a 900 point high screen.
        let area = RecordingVideo.area(selection: CGRect(x: 100, y: 600, width: 300, height: 200),
                                       screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 2)
        XCTAssertEqual(area?.sourceRect, CGRect(x: 100, y: 100, width: 300, height: 200))
        XCTAssertEqual(area?.width, 600)
        XCTAssertEqual(area?.height, 400)
    }

    func testRegionIsRoundedToEvenPixels() {
        let area = RecordingVideo.area(selection: CGRect(x: 10.4, y: 20.6, width: 301.2, height: 201.7),
                                       screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080), scale: 1)
        XCTAssertEqual(area?.sourceRect, CGRect(x: 10, y: 858, width: 300, height: 202))
        XCTAssertEqual(area?.width, 300)
        XCTAssertEqual(area?.height, 202)

        // Half points on a Retina screen land on whole pixels.
        let retina = RecordingVideo.area(selection: CGRect(x: 100.25, y: 100.25, width: 300.5, height: 200.5),
                                         screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 2)
        XCTAssertEqual(retina?.sourceRect, CGRect(x: 100.5, y: 599.5, width: 300, height: 200))
        XCTAssertEqual(retina?.width, 600)
        XCTAssertEqual(retina?.height, 400)
    }

    func testRegionOnOtherScreens() {
        // A screen to the left of the main display.
        let left = RecordingVideo.area(selection: CGRect(x: -1800, y: 100, width: 400, height: 300),
                                       screenFrame: CGRect(x: -1920, y: 0, width: 1920, height: 1080), scale: 1)
        XCTAssertEqual(left?.sourceRect, CGRect(x: 120, y: 680, width: 400, height: 300))

        // A screen above the main display.
        let above = RecordingVideo.area(selection: CGRect(x: 100, y: 1000, width: 200, height: 100),
                                        screenFrame: CGRect(x: 0, y: 900, width: 2560, height: 1440), scale: 1)
        XCTAssertEqual(above?.sourceRect, CGRect(x: 100, y: 1240, width: 200, height: 100))
        XCTAssertEqual(above?.width, 200)
        XCTAssertEqual(above?.height, 100)
    }

    func testRegionIsClippedToTheScreen() {
        let area = RecordingVideo.area(selection: CGRect(x: -50, y: -50, width: 200, height: 200),
                                       screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 2)
        XCTAssertEqual(area?.sourceRect, CGRect(x: 0, y: 750, width: 150, height: 150))
        XCTAssertEqual(area?.width, 300)
        XCTAssertEqual(area?.height, 300)

        // Dragged up and to the left: the rectangle has a negative size.
        let reversed = RecordingVideo.area(selection: CGRect(x: 400, y: 800, width: -300, height: -200),
                                           screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 2)
        XCTAssertEqual(reversed?.sourceRect, CGRect(x: 100, y: 100, width: 300, height: 200))

        XCTAssertNil(RecordingVideo.area(selection: CGRect(x: 2000, y: 0, width: 100, height: 100),
                                         screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 2))
        XCTAssertNil(RecordingVideo.area(selection: CGRect(x: 10, y: 10, width: 0.4, height: 0.4),
                                         screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900), scale: 1))
    }

    func testFullRetinaScreenIsRecordedAt1920() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let area = RecordingVideo.area(selection: screen, screenFrame: screen, scale: 2)
        XCTAssertEqual(area?.sourceRect, screen)
        XCTAssertEqual(area?.width, 1920)
        XCTAssertEqual(area?.height, 1200)
    }

    func testVideoSize() {
        let cases: [((Int, Int), (Int, Int))] = [
            ((3840, 2160), (1920, 1080)),
            ((2880, 1800), (1920, 1200)),
            ((3456, 2234), (1920, 1240)),
            ((1000, 3000), (640, 1920)),
            ((1921, 1081), (1920, 1080)),
            ((1919, 1079), (1918, 1078)),
            ((600, 400), (600, 400)),
            ((1, 1), (2, 2)),
            ((0, 0), (2, 2))
        ]

        for (pixels, expected) in cases {
            let size = RecordingVideo.size(pixelWidth: pixels.0, pixelHeight: pixels.1)
            XCTAssertEqual(size.width, expected.0, "\(pixels)")
            XCTAssertEqual(size.height, expected.1, "\(pixels)")
            XCTAssertEqual(size.width % 2, 0)
            XCTAssertEqual(size.height % 2, 0)
            XCTAssertLessThanOrEqual(max(size.width, size.height), RecordingVideo.maxLongSide)
        }
    }

    func testBitRate() {
        XCTAssertEqual(RecordingVideo.bitRate(width: 1920, height: 1080, framesPerSecond: 30), 3_110_400)
        XCTAssertEqual(RecordingVideo.bitRate(width: 1920, height: 1200, framesPerSecond: 60), 6_912_000)
        XCTAssertEqual(RecordingVideo.bitRate(width: 3840, height: 2160, framesPerSecond: 60), 8_000_000)
        XCTAssertEqual(RecordingVideo.bitRate(width: 320, height: 240, framesPerSecond: 30), 1_000_000)
    }
}

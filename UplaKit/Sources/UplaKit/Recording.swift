import Foundation

/// When a screen recording stops early, and whether a finished recording may be uploaded. The rules of
/// `ScreenRecordManager.GetRecordingSizeLimit` in UpLa for Windows: a recording that will be uploaded stops a little
/// below the upload limit (guests 20 MiB, members 100 MB) when the setting is on.
public struct RecordingLimit: Equatable, Sendable {
    /// Uploads use a member key (signed in, or a key entered by hand), so the member limit applies.
    public let isMember: Bool
    /// File size at which the recording stops; nil when it runs until the user stops it.
    public let stopSize: Int64?

    /// - Parameters:
    ///   - willUpload: the recording is uploaded after it stops ("Upload to upla.com.tr" is on).
    ///   - stopAtUploadLimit: the setting "Stop screen recordings that will be uploaded at the upload limit".
    public init(isMember: Bool, willUpload: Bool, stopAtUploadLimit: Bool) {
        self.isMember = isMember
        stopSize = willUpload && stopAtUploadLimit ? Upla.recordingSizeLimit(isMember: isMember) : nil
    }

    /// The largest file one upload can send.
    public var uploadLimit: Int64 {
        Upla.maxUploadSize(isMember: isMember)
    }

    /// "20 MB" or "100 MB", as the website states the limit.
    public var uploadLimitText: String {
        Upla.maxUploadSizeText(isMember: isMember)
    }

    /// The recording has to stop: its file reached the stop size.
    public func shouldStop(fileSize: Int64) -> Bool {
        guard let stopSize else {
            return false
        }

        return fileSize >= stopSize
    }

    /// Whether a finished recording of this size may be uploaded with this limit's account.
    public func canUpload(fileSize: Int64) -> Bool {
        Self.canUpload(fileSize: fileSize, isMember: isMember)
    }

    /// A recording above the upload limit is not sent (upla.com.tr would refuse it after the whole upload); the app
    /// keeps it in the save folder instead.
    public static func canUpload(fileSize: Int64, isMember: Bool) -> Bool {
        fileSize <= Upla.maxUploadSize(isMember: isMember)
    }
}

/// Elapsed recording time as the menu bar shows it: "0:05", "12:34", "1:02:03".
public enum RecordingTime {
    public static func text(seconds: Int) -> String {
        let total = max(0, seconds)
        let hours = total / 3600
        let minutes = total / 60 % 60
        let rest = total % 60

        if hours > 0 {
            return "\(hours):\(twoDigits(minutes)):\(twoDigits(rest))"
        }

        return "\(minutes):\(twoDigits(rest))"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

/// The part of a display a recording captures, in the units ScreenCaptureKit takes.
public struct RecordingArea: Equatable {
    /// Points from the display's top left corner (`SCStreamConfiguration.sourceRect`), on whole pixels.
    public var sourceRect: CGRect
    /// Size of the video in pixels (see `RecordingVideo.size`).
    public var width: Int
    public var height: Int

    public init(sourceRect: CGRect, width: Int, height: Int) {
        self.sourceRect = sourceRect
        self.width = width
        self.height = height
    }
}

/// Size and bit rate of the recorded H.264 video.
public enum RecordingVideo {
    /// The longer side of the video at most, so a full screen recording on a Retina display (about 1080p then) stays
    /// well within the upload limits and H.264's frame size limits; a small region keeps every pixel.
    public static let maxLongSide = 1920

    /// The area of a selection on one screen.
    /// - Parameters:
    ///   - selection: the selected rectangle in AppKit screen coordinates (origin at the bottom left of the main display).
    ///   - screenFrame: the frame of the screen it was selected on, in the same coordinates.
    ///   - scale: the screen's backing scale factor (pixels per point).
    /// - Returns: nil when the selection does not cover at least 2×2 pixels of the screen.
    public static func area(selection: CGRect, screenFrame: CGRect, scale: CGFloat) -> RecordingArea? {
        let factor = scale > 0 ? scale : CGFloat(1)
        let clipped = selection.standardized.intersection(screenFrame)

        guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else {
            return nil
        }

        // Whole pixels from the top left corner, and an even size, so the frame needs no scaling at 1:1.
        let screenWidth = Int((screenFrame.width * factor).rounded())
        let screenHeight = Int((screenFrame.height * factor).rounded())
        let pixelWidth = evenFloor(min(Int((clipped.width * factor).rounded()), screenWidth))
        let pixelHeight = evenFloor(min(Int((clipped.height * factor).rounded()), screenHeight))

        guard pixelWidth >= 2, pixelHeight >= 2 else {
            return nil
        }

        let left = min(Int(((clipped.minX - screenFrame.minX) * factor).rounded()), screenWidth - pixelWidth)
        let top = min(Int(((screenFrame.maxY - clipped.maxY) * factor).rounded()), screenHeight - pixelHeight)
        let sourceRect = CGRect(x: CGFloat(max(left, 0)) / factor, y: CGFloat(max(top, 0)) / factor,
                                width: CGFloat(pixelWidth) / factor, height: CGFloat(pixelHeight) / factor)
        let video = size(pixelWidth: pixelWidth, pixelHeight: pixelHeight)
        return RecordingArea(sourceRect: sourceRect, width: video.width, height: video.height)
    }

    /// Video size for content of the given pixel size: scaled down to `maxLongSide`, with even numbers (H.264 needs
    /// them), and at least 2×2.
    public static func size(pixelWidth: Int, pixelHeight: Int) -> (width: Int, height: Int) {
        var width = Double(max(pixelWidth, 2))
        var height = Double(max(pixelHeight, 2))
        let longSide = max(width, height)

        if longSide > Double(maxLongSide) {
            let factor = Double(maxLongSide) / longSide
            width = (width * factor).rounded()
            height = (height * factor).rounded()
        }

        return (max(evenFloor(Int(width)), 2), max(evenFloor(Int(height)), 2))
    }

    /// Average bit rate for the encoder: 0.05 bits per pixel and frame, between 1 and 8 Mbit/s. The cap keeps what the
    /// encoder holds back before writing (about a second) well inside the room the upload limit stop leaves.
    public static func bitRate(width: Int, height: Int, framesPerSecond: Int) -> Int {
        let bits = Double(max(width, 0)) * Double(max(height, 0)) * Double(max(framesPerSecond, 1)) * 0.05
        return min(max(Int(bits), 1_000_000), 8_000_000)
    }

    private static func evenFloor(_ value: Int) -> Int {
        value - value % 2
    }
}

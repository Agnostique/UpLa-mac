import Foundation

/// What happens after a capture, with the bits of `AfterCaptureTasks` in UpLa for Windows (ShareX/Enums.cs). UpLa
/// removed some ShareX tasks (1 << 10 and 1 << 16) and kept the others' bits, so the gaps are intended. Menus bind to
/// these values, never to a position (Windows 2.0.2 drew the checks by position and showed the wrong ones).
public struct AfterCaptureTasks: WindowsFlags, Codable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let showQuickTaskMenu = AfterCaptureTasks(rawValue: 1)
    public static let showAfterCaptureWindow = AfterCaptureTasks(rawValue: 1 << 1)
    public static let beautifyImage = AfterCaptureTasks(rawValue: 1 << 2)
    public static let addImageEffects = AfterCaptureTasks(rawValue: 1 << 3)
    public static let annotateImage = AfterCaptureTasks(rawValue: 1 << 4)
    public static let copyImageToClipboard = AfterCaptureTasks(rawValue: 1 << 5)
    public static let pinToScreen = AfterCaptureTasks(rawValue: 1 << 6)
    public static let sendImageToPrinter = AfterCaptureTasks(rawValue: 1 << 7)
    public static let saveImageToFile = AfterCaptureTasks(rawValue: 1 << 8)
    public static let saveImageToFileWithDialog = AfterCaptureTasks(rawValue: 1 << 9)
    public static let performActions = AfterCaptureTasks(rawValue: 1 << 11)
    public static let copyFileToClipboard = AfterCaptureTasks(rawValue: 1 << 12)
    public static let copyFilePathToClipboard = AfterCaptureTasks(rawValue: 1 << 13)
    public static let copyFolderPathToClipboard = AfterCaptureTasks(rawValue: 1 << 14)
    public static let showInExplorer = AfterCaptureTasks(rawValue: 1 << 15)
    public static let scanQRCode = AfterCaptureTasks(rawValue: 1 << 17)
    public static let doOCR = AfterCaptureTasks(rawValue: 1 << 18)
    public static let showBeforeUploadWindow = AfterCaptureTasks(rawValue: 1 << 19)
    public static let uploadImageToHost = AfterCaptureTasks(rawValue: 1 << 20)
    public static let deleteFile = AfterCaptureTasks(rawValue: 1 << 21)

    /// The default of UpLa for Windows (TaskSettings.cs): copy, save and upload (decision 9).
    public static let windowsDefault: AfterCaptureTasks = [.copyImageToClipboard, .saveImageToFile, .uploadImageToHost]

    public static var windowsNames: [(name: String, flag: AfterCaptureTasks)] {
        [
            ("ShowQuickTaskMenu", .showQuickTaskMenu),
            ("ShowAfterCaptureWindow", .showAfterCaptureWindow),
            ("BeautifyImage", .beautifyImage),
            ("AddImageEffects", .addImageEffects),
            ("AnnotateImage", .annotateImage),
            ("CopyImageToClipboard", .copyImageToClipboard),
            ("PinToScreen", .pinToScreen),
            ("SendImageToPrinter", .sendImageToPrinter),
            ("SaveImageToFile", .saveImageToFile),
            ("SaveImageToFileWithDialog", .saveImageToFileWithDialog),
            ("PerformActions", .performActions),
            ("CopyFileToClipboard", .copyFileToClipboard),
            ("CopyFilePathToClipboard", .copyFilePathToClipboard),
            ("CopyFolderPathToClipboard", .copyFolderPathToClipboard),
            ("ShowInExplorer", .showInExplorer),
            ("ScanQRCode", .scanQRCode),
            ("DoOCR", .doOCR),
            ("ShowBeforeUploadWindow", .showBeforeUploadWindow),
            ("UploadImageToHost", .uploadImageToHost),
            ("DeleteFile", .deleteFile)
        ]
    }

    public init(from decoder: Decoder) throws {
        self = try Self.decodeWindowsFlags(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeWindowsFlags(to: encoder)
    }
}

/// What happens after an upload, with the bits of `AfterUploadTasks` in UpLa for Windows (1 << 1, ShortenURL, was
/// removed).
public struct AfterUploadTasks: WindowsFlags, Codable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let showAfterUploadWindow = AfterUploadTasks(rawValue: 1)
    public static let shareURL = AfterUploadTasks(rawValue: 1 << 2)
    public static let copyURLToClipboard = AfterUploadTasks(rawValue: 1 << 3)
    public static let openURL = AfterUploadTasks(rawValue: 1 << 4)
    public static let showQRCode = AfterUploadTasks(rawValue: 1 << 5)

    public static let windowsDefault: AfterUploadTasks = .copyURLToClipboard

    public static var windowsNames: [(name: String, flag: AfterUploadTasks)] {
        [
            ("ShowAfterUploadWindow", .showAfterUploadWindow),
            ("ShareURL", .shareURL),
            ("CopyURLToClipboard", .copyURLToClipboard),
            ("OpenURL", .openURL),
            ("ShowQRCode", .showQRCode)
        ]
    }

    public init(from decoder: Decoder) throws {
        self = try Self.decodeWindowsFlags(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeWindowsFlags(to: encoder)
    }
}

import Foundation

/// The task kinds of UpLa for Windows (`HotkeyType` in ShareX/Enums.cs), in the Windows order; the raw value is the
/// Windows name stored in the settings files. The 22 kinds UpLa removed from ShareX (inventory §3.4) are not here.
public enum HotkeyType: String, WindowsNamedEnum, Hashable {
    case none = "None"
    // Upload
    case fileUpload = "FileUpload"
    case folderUpload = "FolderUpload"
    case clipboardUpload = "ClipboardUpload"
    case clipboardUploadWithContentViewer = "ClipboardUploadWithContentViewer"
    case uploadURL = "UploadURL"
    case dragDropUpload = "DragDropUpload"
    case stopUploads = "StopUploads"
    // Screen capture
    case printScreen = "PrintScreen"
    case activeWindow = "ActiveWindow"
    case customWindow = "CustomWindow"
    case activeMonitor = "ActiveMonitor"
    case rectangleRegion = "RectangleRegion"
    case rectangleLight = "RectangleLight"
    case rectangleTransparent = "RectangleTransparent"
    case customRegion = "CustomRegion"
    case lastRegion = "LastRegion"
    case scrollingCapture = "ScrollingCapture"
    // Screen record
    case screenRecorder = "ScreenRecorder"
    case screenRecorderActiveWindow = "ScreenRecorderActiveWindow"
    case screenRecorderCustomRegion = "ScreenRecorderCustomRegion"
    case startScreenRecorder = "StartScreenRecorder"
    case screenRecorderGIF = "ScreenRecorderGIF"
    case screenRecorderGIFActiveWindow = "ScreenRecorderGIFActiveWindow"
    case screenRecorderGIFCustomRegion = "ScreenRecorderGIFCustomRegion"
    case startScreenRecorderGIF = "StartScreenRecorderGIF"
    case stopScreenRecording = "StopScreenRecording"
    case pauseScreenRecording = "PauseScreenRecording"
    case abortScreenRecording = "AbortScreenRecording"
    // Tools
    case colorPicker = "ColorPicker"
    case screenColorPicker = "ScreenColorPicker"
    case ruler = "Ruler"
    case pinToScreen = "PinToScreen"
    case pinToScreenFromScreen = "PinToScreenFromScreen"
    case pinToScreenFromClipboard = "PinToScreenFromClipboard"
    case pinToScreenFromFile = "PinToScreenFromFile"
    case pinToScreenCloseAll = "PinToScreenCloseAll"
    case imageEditor = "ImageEditor"
    case imageBeautifier = "ImageBeautifier"
    case imageEffects = "ImageEffects"
    case imageViewer = "ImageViewer"
    case imageCombiner = "ImageCombiner"
    case ocr = "OCR"
    case qrCode = "QRCode"
    case qrCodeDecodeFromScreen = "QRCodeDecodeFromScreen"
    case qrCodeScanRegion = "QRCodeScanRegion"
    // Other
    case disableHotkeys = "DisableHotkeys"
    case openMainWindow = "OpenMainWindow"
    case openScreenshotsFolder = "OpenScreenshotsFolder"
    case openHistory = "OpenHistory"
    case openImageHistory = "OpenImageHistory"
    case toggleActionsToolbar = "ToggleActionsToolbar"
    case toggleTrayMenu = "ToggleTrayMenu"
    // The Windows name stays ShareX's; UpLa 1.0 wrote "ExitUpLa", which is read as this too.
    case exitShareX = "ExitShareX"

    public init?(windowsName name: String) {
        let wanted = name.trimmingCharacters(in: .whitespaces).lowercased()
        let shareXName = wanted.replacingOccurrences(of: "upla", with: "sharex")

        guard let match = Self.allCases.first(where: { $0.rawValue.lowercased() == wanted })
            ?? Self.allCases.first(where: { $0.rawValue.lowercased() == shareXName }) else {
            return nil
        }

        self = match
    }

    public enum Category: String, CaseIterable, Sendable {
        case upload = "Upload"
        case screenCapture = "Screen capture"
        case screenRecord = "Screen record"
        case tools = "Tools"
        case other = "Other"
    }

    public var category: Category? {
        switch self {
        case .none:
            return nil
        case .fileUpload, .folderUpload, .clipboardUpload, .clipboardUploadWithContentViewer, .uploadURL, .dragDropUpload,
             .stopUploads:
            return .upload
        case .printScreen, .activeWindow, .customWindow, .activeMonitor, .rectangleRegion, .rectangleLight,
             .rectangleTransparent, .customRegion, .lastRegion, .scrollingCapture:
            return .screenCapture
        case .screenRecorder, .screenRecorderActiveWindow, .screenRecorderCustomRegion, .startScreenRecorder,
             .screenRecorderGIF, .screenRecorderGIFActiveWindow, .screenRecorderGIFCustomRegion, .startScreenRecorderGIF,
             .stopScreenRecording, .pauseScreenRecording, .abortScreenRecording:
            return .screenRecord
        case .colorPicker, .screenColorPicker, .ruler, .pinToScreen, .pinToScreenFromScreen, .pinToScreenFromClipboard,
             .pinToScreenFromFile, .pinToScreenCloseAll, .imageEditor, .imageBeautifier, .imageEffects, .imageViewer,
             .imageCombiner, .ocr, .qrCode, .qrCodeDecodeFromScreen, .qrCodeScanRegion:
            return .tools
        case .disableHotkeys, .openMainWindow, .openScreenshotsFolder, .openHistory, .openImageHistory,
             .toggleActionsToolbar, .toggleTrayMenu, .exitShareX:
            return .other
        }
    }

    /// The English text of UpLa for Windows (HelpersLib Resources.resx, `HotkeyType_*`); MenuText.catalogKey turns it
    /// into the key of its translation ("Toggle tray menu" → "Toggle menu bar menu").
    public var windowsTitle: String {
        switch self {
        case .none: return "None"
        case .fileUpload: return "Upload file"
        case .folderUpload: return "Upload folder"
        case .clipboardUpload: return "Upload from clipboard"
        case .clipboardUploadWithContentViewer: return "Upload from clipboard with content viewer"
        case .uploadURL: return "Upload from URL"
        case .dragDropUpload: return "Drag and drop upload"
        case .stopUploads: return "Stop all active uploads"
        case .printScreen: return "Capture entire screen"
        case .activeWindow: return "Capture active window"
        case .customWindow: return "Capture pre configured window"
        case .activeMonitor: return "Capture active monitor"
        case .rectangleRegion: return "Capture region"
        case .rectangleLight: return "Capture region (Light)"
        case .rectangleTransparent: return "Capture region (Transparent)"
        case .customRegion: return "Capture pre configured region"
        case .lastRegion: return "Capture last region"
        case .scrollingCapture: return "Start/Stop scrolling capture"
        case .screenRecorder: return "Start/Stop screen recording"
        case .screenRecorderActiveWindow: return "Start/Stop screen recording using active window region"
        case .screenRecorderCustomRegion: return "Start/Stop screen recording using pre configured region"
        case .startScreenRecorder: return "Start/Stop screen recording using last region"
        case .screenRecorderGIF: return "Start/Stop screen recording (GIF)"
        case .screenRecorderGIFActiveWindow: return "Start/Stop screen recording (GIF) using active window region"
        case .screenRecorderGIFCustomRegion: return "Start/Stop screen recording (GIF) using pre configured region"
        case .startScreenRecorderGIF: return "Start/Stop screen recording (GIF) using last region"
        case .stopScreenRecording: return "Stop screen recording"
        case .pauseScreenRecording: return "Pause screen recording"
        case .abortScreenRecording: return "Abort screen recording"
        case .colorPicker: return "Color picker"
        case .screenColorPicker: return "Screen color picker"
        case .ruler: return "Ruler"
        case .pinToScreen: return "Pin to screen"
        case .pinToScreenFromScreen: return "Pin to screen (From screen)"
        case .pinToScreenFromClipboard: return "Pin to screen (From clipboard)"
        case .pinToScreenFromFile: return "Pin to screen (From file)"
        case .pinToScreenCloseAll: return "Pin to screen (Close all)"
        case .imageEditor: return "Image editor"
        case .imageBeautifier: return "Image beautifier"
        case .imageEffects: return "Image effects"
        case .imageViewer: return "Image viewer"
        case .imageCombiner: return "Image combiner"
        case .ocr: return "OCR"
        case .qrCode: return "QR code"
        case .qrCodeDecodeFromScreen: return "QR code (Scan screen)"
        case .qrCodeScanRegion: return "QR code (Scan region)"
        case .disableHotkeys: return "Disable/Enable hotkeys"
        case .openMainWindow: return "Open main window"
        case .openScreenshotsFolder: return "Open screenshots folder"
        case .openHistory: return "Open history window"
        case .openImageHistory: return "Open image history window"
        case .toggleActionsToolbar: return "Toggle actions toolbar"
        case .toggleTrayMenu: return "Toggle tray menu"
        case .exitShareX: return "Exit UpLa"
        }
    }

    /// Whether the Mac app can run this task today. The others are hidden in lists and menus, and their hotkeys are
    /// kept but not registered, until the phase that builds them (plan §5, decision 10). The active window runs 0.1's
    /// window selection until the real active window capture comes (phase 1), so ⌥⇧⌘5 keeps working; a click on the
    /// menu bar icon already toggles its menu.
    public var isAvailableOnMac: Bool {
        switch self {
        case .fileUpload, .clipboardUpload, .stopUploads, .printScreen, .activeWindow, .rectangleRegion, .screenRecorder,
             .stopScreenRecording, .abortScreenRecording, .openHistory, .toggleTrayMenu, .exitShareX:
            return true
        default:
            return false
        }
    }
}

/// A Mac shortcut: the virtual key code (kVK_*, layout independent), Carbon modifier flags and the key's character for
/// display. Windows stores a WinForms `Keys` value here, which has no Mac meaning, so only the field name is shared.
public struct HotkeyInfo: Codable, Equatable, Hashable, Sendable {
    // Carbon's modifier bits (cmdKey, shiftKey, optionKey, controlKey), so UplaKit needs no Carbon import.
    public static let commandModifier: UInt32 = 1 << 8
    public static let shiftModifier: UInt32 = 1 << 9
    public static let optionModifier: UInt32 = 1 << 11
    public static let controlModifier: UInt32 = 1 << 12

    /// nil: no shortcut ("None" on Windows).
    public var keyCode: UInt32?
    public var modifiers: UInt32
    public var key: String

    public init(keyCode: UInt32?, modifiers: UInt32, key: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.key = key
    }

    public static let none = HotkeyInfo(keyCode: nil, modifiers: 0, key: "")

    public var isNone: Bool {
        keyCode == nil
    }

    /// "⌥⇧⌘4", in macOS's modifier order; the app shows special keys (arrows, F keys) with its own names.
    public var displayText: String {
        guard keyCode != nil else {
            return ""
        }

        var text = ""

        if modifiers & Self.controlModifier != 0 {
            text += "⌃"
        }
        if modifiers & Self.optionModifier != 0 {
            text += "⌥"
        }
        if modifiers & Self.shiftModifier != 0 {
            text += "⇧"
        }
        if modifiers & Self.commandModifier != 0 {
            text += "⌘"
        }

        return text + key.uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case keyCode = "KeyCode"
        case modifiers = "Modifiers"
        case key = "Key"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = container.value(.keyCode, nil)
        modifiers = container.value(.modifiers, 0)
        key = container.value(.key, "")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(keyCode, forKey: .keyCode)
        try container.encode(modifiers, forKey: .modifiers)
        try container.encode(key, forKey: .key)
    }
}

extension HotkeyInfo {
    // kVK_ANSI_3 … kVK_ANSI_7 (the number row is not in key order: 6 is 0x16, 5 is 0x17).
    static let digitKeyCodes: [String: UInt32] = ["3": 0x14, "4": 0x15, "5": 0x17, "6": 0x16, "7": 0x1A]

    static func optionShiftCommand(_ digit: String) -> HotkeyInfo {
        HotkeyInfo(keyCode: digitKeyCodes[digit], modifiers: optionModifier | shiftModifier | commandModifier, key: digit)
    }
}

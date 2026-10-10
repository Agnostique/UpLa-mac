import Foundation

// The menus of UpLa for Windows as data (inventory §1.2–1.8, §1.12, §2.2): order, English text, Fugue icon and what
// each item does. The app turns them into NSMenus (MenuBuilder), so the main window, the menu bar icon and the app
// menu show the same items from one place. Titles are the exact Windows English texts, which are also the keys of the
// translations (MenuText.catalogKey adapts them to the Mac).

public enum MenuIcon: Equatable, Sendable {
    /// A Fugue icon by its Windows resource name ("image_pencil"); the app's asset catalog has it as "Fugue/<name>".
    case fugue(String)
    /// The UpLa logo (the account item).
    case appLogo
}

/// Whether the Mac shows an item (decision 10: unfinished items are hidden, not greyed out).
public enum MenuAvailability: Equatable, Sendable {
    /// Works in the Mac app today.
    case available
    /// Comes in this phase of the plan (§5); hidden until then.
    case planned(phase: Int)
    /// Never on the Mac (plan §6, decision 7).
    case windowsOnly

    public var isAvailable: Bool {
        self == .available
    }
}

/// What a plain item does when clicked.
public enum MenuCommand: String, CaseIterable, Sendable {
    // Capture
    case captureFullscreen, captureRegion, captureRegionLight, captureRegionTransparent, captureLastRegion
    case screenRecording, screenRecordingGIF, scrollingCapture
    // Upload
    case uploadFile, uploadFolder, uploadFromClipboard, uploadFromURL, dragDropUpload
    // Tools
    case colorPicker, screenColorPicker, ruler, pinToScreen, imageEditor, imageBeautifier, imageEffects, imageViewer
    case imageCombiner, ocr, qrCode
    // Settings and windows
    case applicationSettings, taskSettings, hotkeySettings, destinationSettings, toggleHotkeys
    case screenshotsFolder, history, imageHistory, debugLog, testImageUpload, about
    // Menu bar menu only
    case restartAsAdmin, toggleActionsToolbar, openMainWindow, exit
}

/// A setting an item shows with a check mark (and changes when it is a toggle). Bound to the value, never to the
/// item's position: Windows 2.0.2 checked the wrong After capture items because of that (inventory §12.1).
public enum MenuCheck: Equatable, Sendable {
    case afterCapture(AfterCaptureTasks)
    case afterUpload(AfterUploadTasks)
    case showCursor
    /// One of the delay choices (radio).
    case screenshotDelay(Double)
    /// The "Screenshot delay" item itself: checked while there is a delay.
    case screenshotDelayActive
    case imageDestination(ImageDestination)
    /// upla.com.tr under Image uploader › File uploader: chooses the file uploader for images.
    case imageFileDestination(FileDestination)
    case textDestination(TextDestination)
    case textFileDestination(FileDestination)
    case fileDestination(FileDestination)
    case urlSharingService(URLSharingService)
}

/// Menus whose items are made when they open.
public enum DynamicMenu: String, CaseIterable, Sendable {
    case windows, monitors, workflows, account, recentLinks
}

/// The "{0}" of a title like "Screenshot delay: {0}s".
public enum MenuTitleArgument: Equatable, Sendable {
    case screenshotDelay, imageUploader, textUploader, fileUploader, urlSharingService
}

public enum MenuItemKind: Equatable, Sendable {
    case command(MenuCommand)
    /// Clicking changes the item's `check`.
    case toggle
    case submenu([MenuItem])
    case dynamic(DynamicMenu)
    case separator
}

public struct MenuItem: Equatable, Sendable {
    public var id: String
    /// The exact English text of UpLa for Windows; empty for a separator.
    public var title: String
    /// The catalog key when the title is not enough: two Windows texts with the same English but a different Turkish
    /// get their own key in tools/windows-strings.txt. nil uses MenuText.catalogKey(title).
    public var titleKey: String?
    public var titleArgument: MenuTitleArgument?
    public var icon: MenuIcon?
    /// The hotkey whose shortcut the item shows. Windows shows shortcuts only on the Workflows items (MainForm.cs), so
    /// the fixed menus below set none.
    public var shortcut: HotkeyType?
    public var kind: MenuItemKind
    public var check: MenuCheck?
    public var availability: MenuAvailability
    /// Title and icon while hotkeys are disabled ("Enable hotkeys").
    public var alternateTitle: String?
    public var alternateIcon: MenuIcon?

    public init(id: String, title: String, titleKey: String? = nil, titleArgument: MenuTitleArgument? = nil,
                icon: MenuIcon? = nil, shortcut: HotkeyType? = nil, kind: MenuItemKind, check: MenuCheck? = nil,
                availability: MenuAvailability, alternateTitle: String? = nil, alternateIcon: MenuIcon? = nil) {
        self.id = id
        self.title = title
        self.titleKey = titleKey
        self.titleArgument = titleArgument
        self.icon = icon
        self.shortcut = shortcut
        self.kind = kind
        self.check = check
        self.availability = availability
        self.alternateTitle = alternateTitle
        self.alternateIcon = alternateIcon
    }

    public static func separator(_ id: String) -> MenuItem {
        MenuItem(id: id, title: "", kind: .separator, availability: .available)
    }

    public var isSeparator: Bool {
        kind == .separator
    }

    public var children: [MenuItem] {
        if case .submenu(let items) = kind {
            return items
        }
        return []
    }
}

public enum MenuSpec {
    private static func fugue(_ name: String) -> MenuIcon {
        .fugue(name)
    }

    private static func command(_ id: String, _ title: String, _ icon: String?, _ command: MenuCommand,
                                _ availability: MenuAvailability, titleKey: String? = nil) -> MenuItem {
        MenuItem(id: id, title: title, titleKey: titleKey, icon: icon.map(fugue), kind: .command(command),
                 availability: availability)
    }

    // MARK: Capture ▸ (inventory §1.3; the same in the main window and the menu bar menu)

    public static let screenshotDelays: [(seconds: Double, title: String)] = [
        (0, "No delay"), (1, "1 second"), (2, "2 seconds"), (3, "3 seconds"), (4, "4 seconds"), (5, "5 seconds")
    ]

    public static var captureMenu: [MenuItem] {
        let delays = screenshotDelays.map { delay in
            MenuItem(id: "capture.delay.\(Int(delay.seconds))", title: delay.title, kind: .toggle,
                     check: .screenshotDelay(delay.seconds), availability: .planned(phase: 1))
        }

        return [
            command("capture.fullscreen", "Fullscreen", "layer_fullscreen", .captureFullscreen, .available),
            MenuItem(id: "capture.window", title: "Window", icon: fugue("application_blue"), kind: .dynamic(.windows),
                     availability: .planned(phase: 1)),
            MenuItem(id: "capture.monitor", title: "Monitor", icon: fugue("monitor"), kind: .dynamic(.monitors),
                     availability: .planned(phase: 1)),
            command("capture.region", "Region", "layer_shape", .captureRegion, .available),
            command("capture.regionLight", "Region (Light)", "Rectangle", .captureRegionLight, .planned(phase: 4)),
            command("capture.regionTransparent", "Region (Transparent)", "layer_transparent", .captureRegionTransparent,
                    .planned(phase: 4)),
            command("capture.lastRegion", "Last region", "layers", .captureLastRegion, .planned(phase: 4)),
            command("capture.screenRecording", "Screen recording", "camcorder_image", .screenRecording, .available),
            command("capture.screenRecordingGIF", "Screen recording (GIF)", "film", .screenRecordingGIF, .planned(phase: 4)),
            command("capture.scrollingCapture", "Scrolling capture...", "ui_scroll_pane_image", .scrollingCapture,
                    .planned(phase: 4)),
            .separator("capture.separator"),
            MenuItem(id: "capture.showCursor", title: "Show cursor", icon: fugue("cursor"), kind: .toggle, check: .showCursor,
                     availability: .planned(phase: 1)),
            MenuItem(id: "capture.delay", title: "Screenshot delay: {0}s", titleArgument: .screenshotDelay,
                     icon: fugue("clock_select"), kind: .submenu(delays), check: .screenshotDelayActive,
                     availability: .planned(phase: 1))
        ]
    }

    // MARK: Upload ▸ (§1.4; the menu bar menu adds the clipboard and URL items, §2.2)

    public static var uploadMenu: [MenuItem] {
        [
            command("upload.file", "Upload file...", "folder_open_document", .uploadFile, .available),
            command("upload.folder", "Upload folder...", "folder", .uploadFolder, .planned(phase: 1)),
            command("upload.dragDrop", "Drag and drop upload...", "inbox", .dragDropUpload, .planned(phase: 2))
        ]
    }

    public static var trayUploadMenu: [MenuItem] {
        [
            command("upload.file", "Upload file...", "folder_open_document", .uploadFile, .available),
            command("upload.folder", "Upload folder...", "folder", .uploadFolder, .planned(phase: 1)),
            command("upload.clipboard", "Upload from clipboard...", "clipboard", .uploadFromClipboard, .available),
            command("upload.url", "Upload from URL...", "drive", .uploadFromURL, .planned(phase: 2)),
            command("upload.dragDrop", "Drag and drop upload...", "inbox", .dragDropUpload, .planned(phase: 2))
        ]
    }

    // MARK: Tools ▸ (§1.5)

    public static var toolsMenu: [MenuItem] {
        [
            command("tools.colorPicker", "Color picker...", "color", .colorPicker, .planned(phase: 3)),
            command("tools.screenColorPicker", "Screen color picker...", "pipette", .screenColorPicker, .planned(phase: 3)),
            command("tools.ruler", "Ruler...", "ruler_triangle", .ruler, .planned(phase: 3)),
            command("tools.pinToScreen", "Pin to screen...", "pin", .pinToScreen, .planned(phase: 3)),
            .separator("tools.separator1"),
            command("tools.imageEditor", "Image editor...", "image_pencil", .imageEditor, .planned(phase: 5)),
            command("tools.imageBeautifier", "Image beautifier...", "picture_sunset", .imageBeautifier, .planned(phase: 3)),
            command("tools.imageEffects", "Image effects...", "image_reflection", .imageEffects, .planned(phase: 3)),
            command("tools.imageViewer", "Image viewer...", "images_flickr", .imageViewer, .planned(phase: 3)),
            command("tools.imageCombiner", "Image combiner...", "document_break", .imageCombiner, .planned(phase: 3)),
            .separator("tools.separator2"),
            // Windows uses edit_drop_cap_white and barcode_2d_white on dark themes; the asset catalog keeps them as
            // the dark appearance of the same image.
            command("tools.ocr", "OCR...", "edit_drop_cap", .ocr, .planned(phase: 3)),
            command("tools.qrCode", "QR code...", "barcode_2d", .qrCode, .planned(phase: 3))
        ]
    }

    // MARK: After capture tasks ▸ (§1.6, the 20 tasks in Windows order)

    /// The After capture tasks with their Windows text (HelpersLib `AfterCaptureTasks_*`), icon and phase.
    public static let afterCaptureTasks: [(task: AfterCaptureTasks, title: String, icon: String, availability: MenuAvailability)] = [
        (.showQuickTaskMenu, "Show quick task menu", "ui_menu_blue", .planned(phase: 2)),
        (.showAfterCaptureWindow, "Show \"After capture\" window", "application_text_image", .planned(phase: 2)),
        (.beautifyImage, "Beautify image", "picture_sunset", .planned(phase: 3)),
        // On Windows also a submenu of the image effect presets.
        (.addImageEffects, "Add image effects", "image_saturation", .planned(phase: 3)),
        (.annotateImage, "Open in image editor", "image_pencil", .planned(phase: 5)),
        (.copyImageToClipboard, "Copy image to clipboard", "clipboard_paste_image", .available),
        (.pinToScreen, "Pin to screen", "pin", .planned(phase: 3)),
        (.sendImageToPrinter, "Print image", "printer", .planned(phase: 2)),
        (.saveImageToFile, "Save image to file", "disk", .available),
        (.saveImageToFileWithDialog, "Save image to file as...", "disk_rename", .planned(phase: 1)),
        (.performActions, "Perform actions", "application_terminal", .planned(phase: 4)),
        (.copyFileToClipboard, "Copy file to clipboard", "clipboard_block", .planned(phase: 1)),
        (.copyFilePathToClipboard, "Copy file path to clipboard", "clipboard_list", .planned(phase: 1)),
        (.copyFolderPathToClipboard, "Copy folder path to clipboard", "folder_bookmark", .planned(phase: 1)),
        (.showInExplorer, "Show file in explorer", "folder_stand", .planned(phase: 1)),
        (.scanQRCode, "Scan QR code", "barcode_2d", .planned(phase: 3)),
        (.doOCR, "Recognize text (OCR)", "edit_drop_cap", .planned(phase: 3)),
        (.showBeforeUploadWindow, "Show \"Before upload\" window", "application__arrow", .planned(phase: 2)),
        (.uploadImageToHost, "Upload image to host", "upload_cloud", .available),
        (.deleteFile, "Delete file locally", "bin", .planned(phase: 1))
    ]

    public static var afterCaptureMenu: [MenuItem] {
        afterCaptureTasks.map { entry in
            MenuItem(id: "afterCapture.\(entry.task.rawValue)", title: entry.title, icon: fugue(entry.icon), kind: .toggle,
                     check: .afterCapture(entry.task), availability: entry.availability)
        }
    }

    // MARK: After upload tasks ▸ (§1.7)

    /// "Copy URL to clipboard" waits for the task pipeline: 0.1 copies every link and cannot turn it off yet.
    public static let afterUploadTasks: [(task: AfterUploadTasks, title: String, icon: String, availability: MenuAvailability)] = [
        (.showAfterUploadWindow, "Show \"After upload\" window", "application_browser", .planned(phase: 2)),
        (.shareURL, "Share URL", "globe_share", .planned(phase: 2)),
        (.copyURLToClipboard, "Copy URL to clipboard", "clipboard_paste_document_text", .planned(phase: 1)),
        (.openURL, "Open URL", "globe__arrow", .planned(phase: 1)),
        (.showQRCode, "Show QR code window", "barcode_2d", .planned(phase: 3))
    ]

    public static var afterUploadMenu: [MenuItem] {
        afterUploadTasks.map { entry in
            MenuItem(id: "afterUpload.\(entry.task.rawValue)", title: entry.title, icon: fugue(entry.icon), kind: .toggle,
                     check: .afterUpload(entry.task), availability: entry.availability)
        }
    }

    // MARK: Destinations ▸ (§1.8; the menu bar menu has all four, §2.2). Only the four uploader items have icons.

    private static let uplaTitle = "upla.com.tr"

    static var imageUploaderItem: MenuItem {
        let fileUploader = MenuItem(id: "destinations.image.fileUploader", title: "File uploader", kind: .submenu([
            MenuItem(id: "destinations.image.fileUploader.upla", title: uplaTitle, kind: .toggle,
                     check: .imageFileDestination(.chevereto), availability: .planned(phase: 1))
        ]), check: .imageDestination(.fileUploader), availability: .planned(phase: 1))

        return MenuItem(id: "destinations.image", title: "Image uploader: {0}", titleArgument: .imageUploader,
                        icon: fugue("image"), kind: .submenu([
                            MenuItem(id: "destinations.image.upla", title: uplaTitle, kind: .toggle,
                                     check: .imageDestination(.chevereto), availability: .planned(phase: 1)),
                            fileUploader
                        ]), availability: .planned(phase: 1))
    }

    public static var destinationsMenu: [MenuItem] {
        [imageUploaderItem]
    }

    public static var trayDestinationsMenu: [MenuItem] {
        let textFileUploader = MenuItem(id: "destinations.text.fileUploader", title: "File uploader", kind: .submenu([
            MenuItem(id: "destinations.text.fileUploader.upla", title: uplaTitle, kind: .toggle,
                     check: .textFileDestination(.chevereto), availability: .planned(phase: 1))
        ]), check: .textDestination(.fileUploader), availability: .planned(phase: 1))

        let services = URLSharingService.allCases.map { service in
            MenuItem(id: "destinations.urlSharing.\(service.rawValue)", title: service.rawValue, kind: .toggle,
                     check: .urlSharingService(service), availability: .planned(phase: 2))
        }

        return [
            imageUploaderItem,
            MenuItem(id: "destinations.text", title: "Text uploader: {0}", titleArgument: .textUploader,
                     icon: fugue("notebook"), kind: .submenu([textFileUploader]), availability: .planned(phase: 1)),
            MenuItem(id: "destinations.file", title: "File uploader: {0}", titleArgument: .fileUploader,
                     icon: fugue("application_block"), kind: .submenu([
                         MenuItem(id: "destinations.file.upla", title: uplaTitle, kind: .toggle,
                                  check: .fileDestination(.chevereto), availability: .planned(phase: 1))
                     ]), availability: .planned(phase: 1)),
            MenuItem(id: "destinations.urlSharing", title: "URL sharing service: {0}", titleArgument: .urlSharingService,
                     icon: fugue("globe_share"), kind: .submenu(services), availability: .planned(phase: 2))
        ]
    }

    // MARK: Debug ▸ (§1.12; the main window shows these two)

    public static var debugMenu: [MenuItem] {
        [
            command("debug.log", "Debug log...", "application_monitor", .debugLog, .planned(phase: 2)),
            command("debug.testImageUpload", "Test image upload", "image", .testImageUpload, .planned(phase: 2))
        ]
    }

    // MARK: The main window's left panel (§1.2, 16 items)

    public static var mainWindowPanel: [MenuItem] {
        [
            MenuItem(id: "capture", title: "Capture", icon: fugue("camera"), kind: .submenu(captureMenu), availability: .available),
            MenuItem(id: "upload", title: "Upload", icon: fugue("arrow_090"), kind: .submenu(uploadMenu), availability: .available),
            MenuItem(id: "tools", title: "Tools", icon: fugue("toolbox"), kind: .submenu(toolsMenu), availability: .available),
            .separator("panel.separator1"),
            MenuItem(id: "afterCapture", title: "After capture tasks", icon: fugue("image_export"), kind: .submenu(afterCaptureMenu),
                     availability: .available),
            MenuItem(id: "afterUpload", title: "After upload tasks", icon: fugue("upload_cloud"), kind: .submenu(afterUploadMenu),
                     availability: .available),
            MenuItem(id: "destinations", title: "Destinations", icon: fugue("drive_globe"), kind: .submenu(destinationsMenu),
                     availability: .available),
            .separator("panel.separator2"),
            // The current Settings window, on its General, Hotkeys and upla.com.tr tabs, until the four windows come.
            command("applicationSettings", "Application settings...", "wrench_screwdriver", .applicationSettings, .available),
            command("taskSettings", "Task settings...", "gear", .taskSettings, .planned(phase: 1)),
            command("hotkeySettings", "Hotkey settings...", "keyboard", .hotkeySettings, .available),
            command("destinationSettings", "Destination settings...", "globe_pencil", .destinationSettings, .available),
            // The button shows the user name when signed in (§1.10).
            MenuItem(id: "account", title: "Sign in", icon: .appLogo, kind: .dynamic(.account), availability: .available),
            .separator("panel.separator3"),
            command("screenshotsFolder", "Screenshots folder...", "folder_open_image", .screenshotsFolder, .planned(phase: 1)),
            command("history", "History...", "application_blog", .history, .available),
            command("imageHistory", "Image history...", "application_icon_large", .imageHistory, .planned(phase: 2)),
            .separator("panel.separator4"),
            MenuItem(id: "debug", title: "Debug", icon: fugue("traffic_cone"), kind: .submenu(debugMenu), availability: .available),
            command("about", "About...", "crown", .about, .available)
        ]
    }

    // MARK: The menu bar menu (the Windows tray menu, §2.2, 25 items)

    public static var trayMenu: [MenuItem] {
        [
            MenuItem(id: "capture", title: "Capture", icon: fugue("camera"), kind: .submenu(captureMenu), availability: .available),
            MenuItem(id: "upload", title: "Upload", icon: fugue("arrow_090"), kind: .submenu(trayUploadMenu), availability: .available),
            MenuItem(id: "workflows", title: "Workflows", icon: fugue("categories"), kind: .dynamic(.workflows),
                     availability: .planned(phase: 1)),
            MenuItem(id: "tools", title: "Tools", icon: fugue("toolbox"), kind: .submenu(toolsMenu), availability: .available),
            .separator("tray.separator1"),
            MenuItem(id: "afterCapture", title: "After capture tasks", icon: fugue("image_export"), kind: .submenu(afterCaptureMenu),
                     availability: .available),
            MenuItem(id: "afterUpload", title: "After upload tasks", icon: fugue("upload_cloud"), kind: .submenu(afterUploadMenu),
                     availability: .available),
            MenuItem(id: "destinations", title: "Destinations", icon: fugue("drive_globe"), kind: .submenu(trayDestinationsMenu),
                     availability: .available),
            .separator("tray.separator2"),
            command("applicationSettings", "Application settings...", "wrench_screwdriver", .applicationSettings, .available),
            command("taskSettings", "Task settings...", "gear", .taskSettings, .planned(phase: 1)),
            command("hotkeySettings", "Hotkey settings...", "keyboard", .hotkeySettings, .available),
            MenuItem(id: "toggleHotkeys", title: "Disable hotkeys", icon: fugue("keyboard__minus"), kind: .command(.toggleHotkeys),
                     availability: .planned(phase: 1), alternateTitle: "Enable hotkeys", alternateIcon: fugue("keyboard__plus")),
            command("destinationSettings", "Destination settings...", "globe_pencil", .destinationSettings, .available),
            MenuItem(id: "account", title: "upla.com.tr account", icon: .appLogo, kind: .dynamic(.account), availability: .available),
            .separator("tray.separator3"),
            command("screenshotsFolder", "Screenshots folder...", "folder_open_image", .screenshotsFolder, .planned(phase: 1)),
            command("history", "History...", "application_blog", .history, .available),
            command("imageHistory", "Image history...", "application_icon_large", .imageHistory, .planned(phase: 2)),
            .separator("tray.separator4"),
            command("restartAsAdmin", "Restart UpLa as admin", "uac", .restartAsAdmin, .windowsOnly),
            // Shown only when there are recent tasks (the app's dynamic items decide).
            MenuItem(id: "recentLinks", title: "Recent links", icon: fugue("clipboard_list"), kind: .dynamic(.recentLinks),
                     availability: .available),
            command("toggleActionsToolbar", "Toggle actions toolbar", "ui_toolbar__arrow", .toggleActionsToolbar, .planned(phase: 2)),
            // "UpLa penceresini göster" here, "Ana pencereyi aç" as a task type: same English, two keys.
            command("openMainWindow", "Open main window", "tick_button", .openMainWindow, .planned(phase: 1),
                    titleKey: "Open main window (menu bar menu)"),
            command("exit", "Exit", "cross_button", .exit, .available)
        ]
    }

    // MARK: State

    /// Whether the setting behind a check mark is on.
    public static func isChecked(_ check: MenuCheck, in task: TaskSettings) -> Bool {
        switch check {
        case .afterCapture(let flag):
            return task.afterCaptureJob.contains(flag)
        case .afterUpload(let flag):
            return task.afterUploadJob.contains(flag)
        case .showCursor:
            return task.captureSettings.showCursor
        case .screenshotDelay(let seconds):
            return task.captureSettings.screenshotDelay == seconds
        case .screenshotDelayActive:
            return task.captureSettings.screenshotDelay > 0
        case .imageDestination(let destination):
            return task.imageDestination == destination
        case .imageFileDestination(let destination):
            return task.imageDestination == .fileUploader && task.imageFileDestination == destination
        case .textDestination(let destination):
            return task.textDestination == destination
        case .textFileDestination(let destination):
            return task.textDestination == .fileUploader && task.textFileDestination == destination
        case .fileDestination(let destination):
            return task.fileDestination == destination
        case .urlSharingService(let service):
            return task.urlSharingServiceDestination == service
        }
    }

    /// The settings after a click on the item: flags and Show cursor switch, the other choices are selected.
    public static func applying(_ check: MenuCheck, to task: TaskSettings) -> TaskSettings {
        var task = task

        switch check {
        case .afterCapture(let flag):
            if task.afterCaptureJob.contains(flag) {
                task.afterCaptureJob.remove(flag)
            } else {
                task.afterCaptureJob.insert(flag)
            }
        case .afterUpload(let flag):
            if task.afterUploadJob.contains(flag) {
                task.afterUploadJob.remove(flag)
            } else {
                task.afterUploadJob.insert(flag)
            }
        case .showCursor:
            task.captureSettings.showCursor.toggle()
        case .screenshotDelay(let seconds):
            task.captureSettings.screenshotDelay = seconds
        case .screenshotDelayActive:
            break
        case .imageDestination(let destination):
            task.imageDestination = destination
        case .imageFileDestination(let destination):
            task.imageDestination = .fileUploader
            task.imageFileDestination = destination
        case .textDestination(let destination):
            task.textDestination = destination
        case .textFileDestination(let destination):
            task.textDestination = .fileUploader
            task.textFileDestination = destination
        case .fileDestination(let destination):
            task.fileDestination = destination
        case .urlSharingService(let service):
            task.urlSharingServiceDestination = service
        }

        return task
    }

    /// The text for "{0}" in a title.
    public static func titleArgumentText(_ argument: MenuTitleArgument, in task: TaskSettings) -> String {
        switch argument {
        case .screenshotDelay:
            return delayText(task.captureSettings.screenshotDelay)
        case .imageUploader, .textUploader, .fileUploader:
            // Every uploader is upla.com.tr, also through the file uploader (Windows shows the file destination then).
            return uplaTitle
        case .urlSharingService:
            return task.urlSharingServiceDestination.rawValue
        }
    }

    /// Seconds like .NET's "0.#": "0", "2", "1.5".
    public static func delayText(_ seconds: Double) -> String {
        let tenths = (seconds * 10).rounded()

        if tenths.truncatingRemainder(dividingBy: 10) == 0 {
            return String(Int(tenths / 10))
        }

        return String(format: "%.1f", tenths / 10)
    }

    /// The items to show: available ones (and planned ones too in test builds), without submenus that end up empty
    /// and without separators at the ends or next to each other.
    public static func visibleItems(_ items: [MenuItem], includePlanned: Bool = false) -> [MenuItem] {
        var result: [MenuItem] = []

        for var item in items {
            switch item.availability {
            case .available:
                break
            case .planned:
                guard includePlanned else {
                    continue
                }
            case .windowsOnly:
                continue
            }

            if case .submenu(let children) = item.kind {
                let visible = visibleItems(children, includePlanned: includePlanned)

                guard !visible.isEmpty else {
                    continue
                }

                item.kind = .submenu(visible)
            }

            if item.isSeparator && (result.isEmpty || result.last?.isSeparator == true) {
                continue
            }

            result.append(item)
        }

        while result.last?.isSeparator == true {
            result.removeLast()
        }

        return result
    }
}

/// How a Windows text becomes the key of the Mac's String Catalog, the same way tools/import_windows_strings.py makes
/// the keys (the platform words of plan §3.2 are in MenuText.macReplacements, which that script generates).
public enum MenuText {
    /// Decision 6c ("…" instead of "...") and "{0}" as "%@", so the localized text can be used as a format.
    public static func catalogKey(_ windowsText: String) -> String {
        (macReplacements[windowsText] ?? windowsText)
            .replacingOccurrences(of: "...", with: "…")
            .replacingOccurrences(of: "{0}", with: "%@")
    }

    /// The key of an item's title, or of its alternate title ("Enable hotkeys").
    public static func catalogKey(of item: MenuItem, alternate: Bool = false) -> String {
        if alternate, let title = item.alternateTitle {
            return catalogKey(title)
        }

        return item.titleKey ?? catalogKey(item.title)
    }
}

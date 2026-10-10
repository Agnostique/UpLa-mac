import Foundation

// ApplicationConfig.json of UpLa for Windows (ShareX/ApplicationConfig.cs): the default task settings and the
// Application settings window. Fields marked "Mac" have no Windows counterpart (plan §2.3, §3.1, decisions 1–4).

public enum TaskViewMode: String, WindowsNamedEnum {
    case listView = "ListView"
    case thumbnailView = "ThumbnailView"
}

/// Mac: the languages the app has; Windows lists 25 (plan §3.1).
public enum SupportedLanguage: String, WindowsNamedEnum {
    case automatic = "Automatic"
    case english = "English"
    case turkish = "Turkish"
}

/// Mac (decision 4): the Theme page offers the system appearance, light or dark instead of ShareX's theme editor.
public enum AppAppearance: String, WindowsNamedEnum {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

/// A finished task kept for the next launch and the Recent links menu (ShareX/RecentTask.cs).
public struct RecentTask: Codable, Equatable, Sendable {
    public var filePath: String?
    public var url: String?
    public var thumbnailURL: String?
    // Lets anyone delete the file, like the history: the settings file is written for the user only (0600).
    public var deletionURL: String?
    public var shortenedURL: String?
    public var time: Date

    public init(filePath: String? = nil, url: String? = nil, thumbnailURL: String? = nil, deletionURL: String? = nil,
                shortenedURL: String? = nil, time: Date = Date()) {
        self.filePath = filePath
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.deletionURL = deletionURL
        self.shortenedURL = shortenedURL
        self.time = time
    }

    /// What the menu shows, copies and opens: the short link, the link, or the file (RecentTask.ToString).
    public var text: String {
        for value in [shortenedURL, url, filePath] {
            if let value, !value.isEmpty {
                return value
            }
        }
        return ""
    }

    enum CodingKeys: String, CodingKey {
        case filePath = "FilePath"
        case url = "URL"
        case thumbnailURL = "ThumbnailURL"
        case deletionURL = "DeletionURL"
        case shortenedURL = "ShortenedURL"
        case time = "Time"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filePath = container.value(.filePath, nil)
        url = container.value(.url, nil)
        thumbnailURL = container.value(.thumbnailURL, nil)
        deletionURL = container.value(.deletionURL, nil)
        shortenedURL = container.value(.shortenedURL, nil)
        time = container.value(.time, Date(timeIntervalSince1970: 0))
    }
}

public struct ApplicationConfig: Codable, Equatable, Sendable {
    public var defaultTaskSettings = TaskSettings()

    public var fileUploadDefaultDirectory = ""

    // Main window
    public var firstTimeMinimizeToTray = true

    // General
    public var language: SupportedLanguage = .automatic
    public var showTray = true
    public var silentRun = false
    public var trayIconProgressEnabled = true
    /// The Dock icon's progress on the Mac (the taskbar button's on Windows).
    public var taskbarProgressEnabled = true
    public var rememberMainFormPosition = false
    public var rememberMainFormSize = false
    /// Decision 3: a click on the menu bar icon opens its menu (Windows: Capture region), the rest as on Windows.
    public var trayLeftClickAction: HotkeyType = .toggleTrayMenu
    public var trayLeftDoubleClickAction: HotkeyType = .openMainWindow
    public var trayMiddleClickAction: HotkeyType = .clipboardUploadWithContentViewer
    public var autoCheckUpdate = true
    /// Mac (decision 1): the Dock icon is shown while the main window is open; off, never.
    public var showDockIcon = true
    // Launch at login is not stored: like Windows, the Integration page reads the system's state (SMAppService).

    // Theme
    /// Mac (decision 4).
    public var appearance: AppAppearance = .system

    // Paths
    public var useCustomScreenshotsPath = false
    public var customScreenshotsPath = ""
    public var saveImageSubFolderPattern = ApplicationConfig.defaultSaveImageSubFolderPattern
    public var saveImageSubFolderPatternWindow = ""

    // Main window
    public var showMenu = true
    public var taskViewMode: TaskViewMode = .thumbnailView
    public var showThumbnailTitle = true

    // Upload
    public var uploadLimit = 5
    public var maxUploadFailRetry = 1

    // History
    public var historySaveTasks = true
    public var recentTasksSave = true
    public var recentTasksMaxCount = 10
    public var recentTasksShowInMainWindow = true
    public var recentTasksShowInTrayMenu = true
    public var recentTasksTrayMenuMostRecentFirst = false
    /// Oldest first; null on Windows when there are none.
    public var recentTasks: [RecentTask]?

    // Advanced
    public var binaryUnits = false
    public var showMostRecentTaskFirst = false
    public var workflowsOnlyShowEdited = false
    public var trayAutoExpandCaptureMenu = false
    public var showMainWindowTip = true
    public var autoSelectLastCompletedTask = false
    public var disableHotkeys = false
    public var disableHotkeysOnFullscreen = false
    public var hotkeyRepeatLimit = 500
    public var showClipboardContentViewer = true
    public var disableUpload = false
    public var showUploadWarning = true
    public var showMultiUploadWarning = true
    /// Megabytes; 0 turns the warning off.
    public var showLargeFileSizeWarning = 100

    public init() {}

    /// RecentTaskManager keeps 1–100 tasks.
    public static let recentTasksCountRange = 1...100

    /// Adds a finished task and drops the oldest beyond RecentTasksMaxCount.
    public mutating func addRecentTask(_ task: RecentTask) {
        guard recentTasksSave else {
            return
        }

        var tasks = recentTasks ?? []
        tasks.append(task)
        let limit = min(max(recentTasksMaxCount, Self.recentTasksCountRange.lowerBound), Self.recentTasksCountRange.upperBound)

        if tasks.count > limit {
            tasks.removeFirst(tasks.count - limit)
        }

        recentTasks = tasks
    }

    /// The month subfolder of Windows (decision 9).
    public static let defaultSaveImageSubFolderPattern = "%y-%mo"

    /// The folder choice of the 0.1 Settings window, which has no subfolder setting. A chosen folder gets the files
    /// directly, as in 0.1 and after the migration; an empty path brings back the Windows folder with its month
    /// subfolder. Choosing again inside the month folder therefore never nests a second one.
    public mutating func setLegacySaveFolder(_ path: String) {
        let path = path.trimmingCharacters(in: .whitespaces)
        customScreenshotsPath = path
        useCustomScreenshotsPath = !path.isEmpty
        saveImageSubFolderPattern = path.isEmpty ? Self.defaultSaveImageSubFolderPattern : ""
    }

    /// The folder screenshots go to before the subfolder: the custom one, or `defaultParent`
    /// (~/Documents/UpLa/Screenshots, like `<personal folder>\Screenshots` on Windows).
    public func screenshotsParentFolder(defaultParent: URL) -> URL {
        let custom = customScreenshotsPath.trimmingCharacters(in: .whitespaces)

        guard useCustomScreenshotsPath, !custom.isEmpty else {
            return defaultParent
        }

        return URL(fileURLWithPath: (custom as NSString).expandingTildeInPath, isDirectory: true)
    }

    /// The parent folder with the subfolder pattern applied ("%y-%mo" → "2026-10"). Only the date parts %y, %mo and
    /// %d are expanded here; the full name parser comes with the task pipeline.
    public func screenshotsFolder(defaultParent: URL, date: Date = Date(), calendar: Calendar = .current) -> URL {
        let parent = screenshotsParentFolder(defaultParent: defaultParent)
        let pattern = saveImageSubFolderPattern.trimmingCharacters(in: .whitespaces)

        guard !pattern.isEmpty else {
            return parent
        }

        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let subfolder = pattern
            .replacingOccurrences(of: "%mo", with: Self.twoDigits(parts.month ?? 1))
            .replacingOccurrences(of: "%y", with: String(parts.year ?? 2000))
            .replacingOccurrences(of: "%d", with: Self.twoDigits(parts.day ?? 1))
        return parent.appendingPathComponent(subfolder, isDirectory: true)
    }

    private static func twoDigits(_ number: Int) -> String {
        number < 10 ? "0\(number)" : String(number)
    }

    enum CodingKeys: String, CodingKey {
        case defaultTaskSettings = "DefaultTaskSettings"
        case fileUploadDefaultDirectory = "FileUploadDefaultDirectory"
        case firstTimeMinimizeToTray = "FirstTimeMinimizeToTray"
        case language = "Language"
        case showTray = "ShowTray"
        case silentRun = "SilentRun"
        case trayIconProgressEnabled = "TrayIconProgressEnabled"
        case taskbarProgressEnabled = "TaskbarProgressEnabled"
        case rememberMainFormPosition = "RememberMainFormPosition"
        case rememberMainFormSize = "RememberMainFormSize"
        case trayLeftClickAction = "TrayLeftClickAction"
        case trayLeftDoubleClickAction = "TrayLeftDoubleClickAction"
        case trayMiddleClickAction = "TrayMiddleClickAction"
        case autoCheckUpdate = "AutoCheckUpdate"
        case showDockIcon = "ShowDockIcon"
        case appearance = "Appearance"
        case useCustomScreenshotsPath = "UseCustomScreenshotsPath"
        case customScreenshotsPath = "CustomScreenshotsPath"
        case saveImageSubFolderPattern = "SaveImageSubFolderPattern"
        case saveImageSubFolderPatternWindow = "SaveImageSubFolderPatternWindow"
        case showMenu = "ShowMenu"
        case taskViewMode = "TaskViewMode"
        case showThumbnailTitle = "ShowThumbnailTitle"
        case uploadLimit = "UploadLimit"
        case maxUploadFailRetry = "MaxUploadFailRetry"
        case historySaveTasks = "HistorySaveTasks"
        case recentTasksSave = "RecentTasksSave"
        case recentTasksMaxCount = "RecentTasksMaxCount"
        case recentTasksShowInMainWindow = "RecentTasksShowInMainWindow"
        case recentTasksShowInTrayMenu = "RecentTasksShowInTrayMenu"
        case recentTasksTrayMenuMostRecentFirst = "RecentTasksTrayMenuMostRecentFirst"
        case recentTasks = "RecentTasks"
        case binaryUnits = "BinaryUnits"
        case showMostRecentTaskFirst = "ShowMostRecentTaskFirst"
        case workflowsOnlyShowEdited = "WorkflowsOnlyShowEdited"
        case trayAutoExpandCaptureMenu = "TrayAutoExpandCaptureMenu"
        case showMainWindowTip = "ShowMainWindowTip"
        case autoSelectLastCompletedTask = "AutoSelectLastCompletedTask"
        case disableHotkeys = "DisableHotkeys"
        case disableHotkeysOnFullscreen = "DisableHotkeysOnFullscreen"
        case hotkeyRepeatLimit = "HotkeyRepeatLimit"
        case showClipboardContentViewer = "ShowClipboardContentViewer"
        case disableUpload = "DisableUpload"
        case showUploadWarning = "ShowUploadWarning"
        case showMultiUploadWarning = "ShowMultiUploadWarning"
        case showLargeFileSizeWarning = "ShowLargeFileSizeWarning"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ApplicationConfig()
        defaultTaskSettings = c.value(.defaultTaskSettings, d.defaultTaskSettings)
        fileUploadDefaultDirectory = c.value(.fileUploadDefaultDirectory, d.fileUploadDefaultDirectory)
        firstTimeMinimizeToTray = c.value(.firstTimeMinimizeToTray, d.firstTimeMinimizeToTray)
        language = c.value(.language, d.language)
        showTray = c.value(.showTray, d.showTray)
        silentRun = c.value(.silentRun, d.silentRun)
        trayIconProgressEnabled = c.value(.trayIconProgressEnabled, d.trayIconProgressEnabled)
        taskbarProgressEnabled = c.value(.taskbarProgressEnabled, d.taskbarProgressEnabled)
        rememberMainFormPosition = c.value(.rememberMainFormPosition, d.rememberMainFormPosition)
        rememberMainFormSize = c.value(.rememberMainFormSize, d.rememberMainFormSize)
        trayLeftClickAction = c.value(.trayLeftClickAction, d.trayLeftClickAction)
        trayLeftDoubleClickAction = c.value(.trayLeftDoubleClickAction, d.trayLeftDoubleClickAction)
        trayMiddleClickAction = c.value(.trayMiddleClickAction, d.trayMiddleClickAction)
        autoCheckUpdate = c.value(.autoCheckUpdate, d.autoCheckUpdate)
        showDockIcon = c.value(.showDockIcon, d.showDockIcon)
        appearance = c.value(.appearance, d.appearance)
        useCustomScreenshotsPath = c.value(.useCustomScreenshotsPath, d.useCustomScreenshotsPath)
        customScreenshotsPath = c.value(.customScreenshotsPath, d.customScreenshotsPath)
        saveImageSubFolderPattern = c.value(.saveImageSubFolderPattern, d.saveImageSubFolderPattern)
        saveImageSubFolderPatternWindow = c.value(.saveImageSubFolderPatternWindow, d.saveImageSubFolderPatternWindow)
        showMenu = c.value(.showMenu, d.showMenu)
        taskViewMode = c.value(.taskViewMode, d.taskViewMode)
        showThumbnailTitle = c.value(.showThumbnailTitle, d.showThumbnailTitle)
        uploadLimit = c.value(.uploadLimit, d.uploadLimit)
        maxUploadFailRetry = c.value(.maxUploadFailRetry, d.maxUploadFailRetry)
        historySaveTasks = c.value(.historySaveTasks, d.historySaveTasks)
        recentTasksSave = c.value(.recentTasksSave, d.recentTasksSave)
        recentTasksMaxCount = c.value(.recentTasksMaxCount, d.recentTasksMaxCount)
        recentTasksShowInMainWindow = c.value(.recentTasksShowInMainWindow, d.recentTasksShowInMainWindow)
        recentTasksShowInTrayMenu = c.value(.recentTasksShowInTrayMenu, d.recentTasksShowInTrayMenu)
        recentTasksTrayMenuMostRecentFirst = c.value(.recentTasksTrayMenuMostRecentFirst, d.recentTasksTrayMenuMostRecentFirst)
        recentTasks = c.value(.recentTasks, d.recentTasks)
        binaryUnits = c.value(.binaryUnits, d.binaryUnits)
        showMostRecentTaskFirst = c.value(.showMostRecentTaskFirst, d.showMostRecentTaskFirst)
        workflowsOnlyShowEdited = c.value(.workflowsOnlyShowEdited, d.workflowsOnlyShowEdited)
        trayAutoExpandCaptureMenu = c.value(.trayAutoExpandCaptureMenu, d.trayAutoExpandCaptureMenu)
        showMainWindowTip = c.value(.showMainWindowTip, d.showMainWindowTip)
        autoSelectLastCompletedTask = c.value(.autoSelectLastCompletedTask, d.autoSelectLastCompletedTask)
        disableHotkeys = c.value(.disableHotkeys, d.disableHotkeys)
        disableHotkeysOnFullscreen = c.value(.disableHotkeysOnFullscreen, d.disableHotkeysOnFullscreen)
        hotkeyRepeatLimit = c.value(.hotkeyRepeatLimit, d.hotkeyRepeatLimit)
        showClipboardContentViewer = c.value(.showClipboardContentViewer, d.showClipboardContentViewer)
        disableUpload = c.value(.disableUpload, d.disableUpload)
        showUploadWarning = c.value(.showUploadWarning, d.showUploadWarning)
        showMultiUploadWarning = c.value(.showMultiUploadWarning, d.showMultiUploadWarning)
        showLargeFileSizeWarning = c.value(.showLargeFileSizeWarning, d.showLargeFileSizeWarning)
    }
}

/// One row of the Hotkey settings window (ShareX/HotkeySettings.cs): the shortcut and its task. The task's
/// UseDefault* flags say which parts follow the default task settings.
public struct HotkeySettings: Codable, Equatable, Sendable {
    public var hotkeyInfo: HotkeyInfo
    public var taskSettings: TaskSettings

    public init(job: HotkeyType, hotkey: HotkeyInfo = .none) {
        hotkeyInfo = hotkey
        taskSettings = TaskSettings()
        taskSettings.job = job
    }

    enum CodingKeys: String, CodingKey {
        case hotkeyInfo = "HotkeyInfo"
        case taskSettings = "TaskSettings"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotkeyInfo = container.value(.hotkeyInfo, HotkeyInfo.none)
        taskSettings = container.value(.taskSettings, TaskSettings())
    }
}

/// HotkeysConfig.json.
public struct HotkeysConfig: Codable, Equatable, Sendable {
    public var hotkeys: [HotkeySettings]

    /// Decision 8: the five Windows hotkeys on ⌥⇧⌘3–7, next to macOS's own ⇧⌘3/4/5. The GIF recording hotkey is in
    /// the list from the start, so it needs no migration later, but it is neither shown nor registered before phase
    /// 4 (HotkeyType.isAvailableOnMac).
    public static let defaultHotkeys: [HotkeySettings] = [
        HotkeySettings(job: .printScreen, hotkey: .optionShiftCommand("3")),
        HotkeySettings(job: .rectangleRegion, hotkey: .optionShiftCommand("4")),
        HotkeySettings(job: .activeWindow, hotkey: .optionShiftCommand("5")),
        HotkeySettings(job: .screenRecorder, hotkey: .optionShiftCommand("6")),
        HotkeySettings(job: .screenRecorderGIF, hotkey: .optionShiftCommand("7"))
    ]

    public init(hotkeys: [HotkeySettings] = HotkeysConfig.defaultHotkeys) {
        self.hotkeys = hotkeys
    }

    /// The hotkeys the Mac can run today, for the Workflows menu and registration.
    public var availableHotkeys: [HotkeySettings] {
        hotkeys.filter { $0.taskSettings.job.isAvailableOnMac }
    }

    /// Sets the shortcut of the first hotkey with this job, adding one when there is none. A shortcut that another
    /// hotkey used is taken from it, so one key never runs two tasks.
    public mutating func setHotkey(_ info: HotkeyInfo, for job: HotkeyType) {
        if !info.isNone {
            for index in hotkeys.indices where hotkeys[index].hotkeyInfo == info && hotkeys[index].taskSettings.job != job {
                hotkeys[index].hotkeyInfo = .none
            }
        }

        if let index = hotkeys.firstIndex(where: { $0.taskSettings.job == job }) {
            hotkeys[index].hotkeyInfo = info
        } else {
            hotkeys.append(HotkeySettings(job: job, hotkey: info))
        }
    }

    enum CodingKeys: String, CodingKey {
        case hotkeys = "Hotkeys"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hotkeys = container.value(.hotkeys, HotkeysConfig.defaultHotkeys)
    }
}

/// The upla.com.tr options of the Destination settings window (UplaSettings in UploadersConfig.json on Windows). The
/// account (key, user name) stays in the keychain and AccountStore.
public struct UplaSettings: Codable, Equatable, Sendable {
    public var linkType: UplaLinkType = .viewerPage
    public var album = ""
    public var tags = ""
    public var categoryID = 0
    /// One of Upla.expirationPresets, empty for no automatic deletion.
    public var expiration = ""
    /// Screen recordings that will be uploaded stop at the upload limit (a Windows UpLa setting of this page).
    public var stopRecordingAtUploadLimit = true
    public var maxWidth = 0

    public init() {}

    public var uploadOptions: UplaUploadOptions {
        UplaUploadOptions(linkType: linkType, album: album, tags: tags, categoryID: max(0, categoryID),
                          expiration: Upla.expirationPresets.contains(expiration) ? expiration : "", maxWidth: max(0, maxWidth))
    }

    // Windows writes the link type as "ViewerPage"; UplaLinkType's own raw value is "viewerPage".
    static func windowsName(_ linkType: UplaLinkType) -> String {
        let raw = linkType.rawValue
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    static func linkType(windowsName name: String) -> UplaLinkType? {
        UplaLinkType.allCases.first { $0.rawValue.lowercased() == name.trimmingCharacters(in: .whitespaces).lowercased() }
    }

    enum CodingKeys: String, CodingKey {
        case linkType = "LinkType"
        case album = "Album"
        case tags = "Tags"
        case categoryID = "CategoryID"
        case expiration = "Expiration"
        case stopRecordingAtUploadLimit = "StopRecordingAtUploadLimit"
        case maxWidth = "MaxWidth"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = UplaSettings()
        linkType = Self.linkType(windowsName: container.value(.linkType, "")) ?? defaults.linkType
        album = container.value(.album, defaults.album)
        tags = container.value(.tags, defaults.tags)
        categoryID = container.value(.categoryID, defaults.categoryID)
        expiration = container.value(.expiration, defaults.expiration)
        stopRecordingAtUploadLimit = container.value(.stopRecordingAtUploadLimit, defaults.stopRecordingAtUploadLimit)
        maxWidth = container.value(.maxWidth, defaults.maxWidth)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.windowsName(linkType), forKey: .linkType)
        try container.encode(album, forKey: .album)
        try container.encode(tags, forKey: .tags)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(expiration, forKey: .expiration)
        try container.encode(stopRecordingAtUploadLimit, forKey: .stopRecordingAtUploadLimit)
        try container.encode(maxWidth, forKey: .maxWidth)
    }
}

/// UploadersConfig.json; only the upla.com.tr page exists.
public struct UploadersConfig: Codable, Equatable, Sendable {
    public var uplaSettings = UplaSettings()

    public init() {}

    enum CodingKeys: String, CodingKey {
        case uplaSettings = "UplaSettings"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uplaSettings = container.value(.uplaSettings, UplaSettings())
    }
}

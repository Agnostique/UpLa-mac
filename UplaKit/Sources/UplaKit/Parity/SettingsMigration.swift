import Foundation

/// The three settings files together.
public struct ConfigSet: Equatable, Sendable {
    public var application: ApplicationConfig
    public var hotkeys: HotkeysConfig
    public var uploaders: UploadersConfig

    public init(application: ApplicationConfig = ApplicationConfig(), hotkeys: HotkeysConfig = HotkeysConfig(),
                uploaders: UploadersConfig = UploadersConfig()) {
        self.application = application
        self.hotkeys = hotkeys
        self.uploaders = uploaders
    }
}

/// Moves the settings of UpLa for Mac 0.1 (UserDefaults) to the Windows model (plan §2.6). Only keys the user really
/// stored are passed in (the persistent domain, not the registered defaults), so a value the user chose is kept and
/// everything never touched gets the Windows default (decision 9). The old keys are left as they are, so going back
/// to 0.1 still works.
public enum SettingsMigration {
    /// The UserDefaults keys of 0.1 (App/Sources/AppSettings.swift and HotKeyCenter.swift).
    public enum LegacyKey {
        public static let showNotifications = "ShowNotifications"
        public static let uploadAfterCapture = "UploadAfterCapture"
        public static let copyImageAfterCapture = "CopyImageAfterCapture"
        public static let saveAfterCapture = "SaveAfterCapture"
        public static let saveFolderPath = "SaveFolderPath"
        public static let linkType = "LinkType"
        public static let album = "Album"
        public static let tags = "Tags"
        public static let categoryID = "CategoryID"
        public static let expiration = "Expiration"
        public static let maxWidth = "MaxWidth"
        public static let stopRecordingAtUploadLimit = "StopRecordingAtUploadLimit"
        public static let recordingFramesPerSecond = "RecordingFramesPerSecond"
        public static let recordingShowsCursor = "RecordingShowsCursor"
        public static let recordingCapturesAudio = "RecordingCapturesAudio"
        public static let showUploadWarning = "ShowUploadWarning"

        /// "HotKey.<action>": a dictionary with keyCode, modifiers and key; an empty one means the user removed it.
        public static let hotkeyPrefix = "HotKey."
    }

    /// 0.1's hotkey actions and their Windows task. 0.1's "window" picked a window; decision 8 puts the active window
    /// on that place, so a shortcut the user set for it moves there.
    public static let legacyHotkeyJobs: [(action: String, job: HotkeyType)] = [
        ("fullScreen", .printScreen),
        ("region", .rectangleRegion),
        ("window", .activeWindow),
        ("recording", .screenRecorder)
    ]

    /// The frame rates 0.1 offered.
    static let legacyFrameRates = [30, 60]

    /// - Parameters:
    ///   - legacy: the stored 0.1 values (`UserDefaults.persistentDomain(forName:)`).
    ///   - legacyDefaultSaveFolder: 0.1's default save folder (~/Pictures/UpLa).
    public static func migrate(legacy: [String: Any], legacyDefaultSaveFolder: String) -> ConfigSet {
        var configs = ConfigSet()
        var task = TaskSettings()

        if let show = bool(legacy[LegacyKey.showNotifications]) {
            task.generalSettings.showToastNotificationAfterTaskCompleted = show
        }

        // 0.1's "Upload to upla.com.tr and copy the link" is two Windows tasks. Turned off, only the upload goes:
        // 0.1 copied the link of every upload, including files chosen by hand, which the After upload task covers.
        if let upload = bool(legacy[LegacyKey.uploadAfterCapture]) {
            if upload {
                task.afterCaptureJob.insert(.uploadImageToHost)
                task.afterUploadJob.insert(.copyURLToClipboard)
            } else {
                task.afterCaptureJob.remove(.uploadImageToHost)
            }
        }

        if let copy = bool(legacy[LegacyKey.copyImageAfterCapture]) {
            set(.copyImageToClipboard, copy, in: &task.afterCaptureJob)
        }

        let save = bool(legacy[LegacyKey.saveAfterCapture])

        if let save {
            set(.saveImageToFile, save, in: &task.afterCaptureJob)
        }

        // A folder the user chose, or 0.1's default folder for someone who turned saving on, stays where the files
        // went: as the custom screenshots folder, without the Windows month subfolder. Everyone else gets the Windows
        // folder (Documents/UpLa/Screenshots/yyyy-MM).
        let folder = string(legacy[LegacyKey.saveFolderPath])?.trimmingCharacters(in: .whitespaces) ?? ""

        if !folder.isEmpty || save == true {
            configs.application.useCustomScreenshotsPath = true
            configs.application.customScreenshotsPath = folder.isEmpty ? legacyDefaultSaveFolder : folder
            configs.application.saveImageSubFolderPattern = ""
        }

        if let rate = int(legacy[LegacyKey.recordingFramesPerSecond]), legacyFrameRates.contains(rate) {
            task.captureSettings.screenRecordFPS = rate
        }

        if let cursor = bool(legacy[LegacyKey.recordingShowsCursor]) {
            task.captureSettings.screenRecordShowCursor = cursor
        }

        if let audio = bool(legacy[LegacyKey.recordingCapturesAudio]) {
            task.captureSettings.ffmpegOptions.audioSource = audio ? FFmpegOptions.systemAudioSource : ""
        }

        if let warning = bool(legacy[LegacyKey.showUploadWarning]) {
            configs.application.showUploadWarning = warning
        }

        configs.application.defaultTaskSettings = task
        configs.uploaders.uplaSettings = migrateUplaSettings(legacy)
        configs.hotkeys = migrateHotkeys(legacy)
        return configs
    }

    static func migrateUplaSettings(_ legacy: [String: Any]) -> UplaSettings {
        var settings = UplaSettings()

        if let name = string(legacy[LegacyKey.linkType]), let linkType = UplaLinkType(rawValue: name) {
            settings.linkType = linkType
        }
        if let album = string(legacy[LegacyKey.album]) {
            settings.album = album
        }
        if let tags = string(legacy[LegacyKey.tags]) {
            settings.tags = tags
        }
        if let categoryID = int(legacy[LegacyKey.categoryID]) {
            settings.categoryID = max(0, categoryID)
        }
        if let expiration = string(legacy[LegacyKey.expiration]), Upla.expirationPresets.contains(expiration) {
            settings.expiration = expiration
        }
        if let maxWidth = int(legacy[LegacyKey.maxWidth]) {
            settings.maxWidth = max(0, maxWidth)
        }
        if let stop = bool(legacy[LegacyKey.stopRecordingAtUploadLimit]) {
            settings.stopRecordingAtUploadLimit = stop
        }

        return settings
    }

    static func migrateHotkeys(_ legacy: [String: Any]) -> HotkeysConfig {
        var config = HotkeysConfig()

        for (action, job) in legacyHotkeyJobs {
            guard let stored = legacy[LegacyKey.hotkeyPrefix + action] as? [String: Any] else {
                continue
            }

            config.setHotkey(legacyHotkey(stored) ?? HotkeyInfo.none, for: job)
        }

        return config
    }

    // nil for an empty or unreadable dictionary: the user removed the shortcut.
    static func legacyHotkey(_ stored: [String: Any]) -> HotkeyInfo? {
        guard let keyCode = int(stored["keyCode"]).flatMap({ UInt32(exactly: $0) }),
              let modifiers = int(stored["modifiers"]).flatMap({ UInt32(exactly: $0) }) else {
            return nil
        }

        return HotkeyInfo(keyCode: keyCode, modifiers: modifiers, key: string(stored["key"]) ?? "")
    }

    private static func set(_ flag: AfterCaptureTasks, _ on: Bool, in tasks: inout AfterCaptureTasks) {
        if on {
            tasks.insert(flag)
        } else {
            tasks.remove(flag)
        }
    }

    // Property list values arrive as NSNumber on macOS; Linux tests pass Swift values.
    static func bool(_ value: Any?) -> Bool? {
        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? Int {
            return number != 0
        }
        return nil
    }

    static func int(_ value: Any?) -> Int? {
        if let number = value as? Int {
            return number
        }
        if let number = value as? Double, let exact = Int(exactly: number) {
            return exact
        }
        return nil
    }

    static func string(_ value: Any?) -> String? {
        value as? String
    }
}

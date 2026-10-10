import Foundation
import XCTest
#if canImport(Carbon)
import Carbon
#endif
@testable import UplaKit

/// The settings model of the Windows parity work: flag bits and their JSON form, defaults, round trips and the
/// settings files.
final class ParityModelTests: XCTestCase {
    // MARK: Flags

    // ShareX/Enums.cs of UpLa for Windows, with UpLa's gaps (1 << 10 and 1 << 16 were removed).
    func testAfterCaptureBitsMatchWindows() {
        let expected: [(String, Int)] = [
            ("ShowQuickTaskMenu", 1), ("ShowAfterCaptureWindow", 1 << 1), ("BeautifyImage", 1 << 2),
            ("AddImageEffects", 1 << 3), ("AnnotateImage", 1 << 4), ("CopyImageToClipboard", 1 << 5),
            ("PinToScreen", 1 << 6), ("SendImageToPrinter", 1 << 7), ("SaveImageToFile", 1 << 8),
            ("SaveImageToFileWithDialog", 1 << 9), ("PerformActions", 1 << 11), ("CopyFileToClipboard", 1 << 12),
            ("CopyFilePathToClipboard", 1 << 13), ("CopyFolderPathToClipboard", 1 << 14), ("ShowInExplorer", 1 << 15),
            ("ScanQRCode", 1 << 17), ("DoOCR", 1 << 18), ("ShowBeforeUploadWindow", 1 << 19),
            ("UploadImageToHost", 1 << 20), ("DeleteFile", 1 << 21)
        ]

        XCTAssertEqual(AfterCaptureTasks.windowsNames.map(\.name), expected.map(\.0))
        XCTAssertEqual(AfterCaptureTasks.windowsNames.map(\.flag.rawValue), expected.map(\.1))
        XCTAssertEqual(AfterCaptureTasks.copyImageToClipboard.rawValue, 32)
        XCTAssertEqual(AfterCaptureTasks.saveImageToFile.rawValue, 256)
        XCTAssertEqual(AfterCaptureTasks.uploadImageToHost.rawValue, 1_048_576)
    }

    func testAfterUploadBitsMatchWindows() {
        XCTAssertEqual(AfterUploadTasks.windowsNames.map(\.name),
                       ["ShowAfterUploadWindow", "ShareURL", "CopyURLToClipboard", "OpenURL", "ShowQRCode"])
        XCTAssertEqual(AfterUploadTasks.windowsNames.map(\.flag.rawValue), [1, 4, 8, 16, 32])
    }

    func testWindowsDefaults() {
        XCTAssertEqual(AfterCaptureTasks.windowsDefault.rawValue, 32 | 256 | 1_048_576)
        XCTAssertEqual(AfterUploadTasks.windowsDefault, .copyURLToClipboard)

        let task = TaskSettings()
        XCTAssertEqual(task.afterCaptureJob, [.copyImageToClipboard, .saveImageToFile, .uploadImageToHost])
        XCTAssertEqual(task.afterUploadJob, [.copyURLToClipboard])
        XCTAssertEqual(task.imageSettings.imageFormat, .png)
        XCTAssertEqual(task.uploadSettings.nameFormatPattern, "%ra{10}")
        XCTAssertTrue(task.captureSettings.showCursor)
        XCTAssertEqual(task.captureSettings.screenshotDelay, 0)
        XCTAssertEqual(task.captureSettings.screenRecordFPS, 30)
        XCTAssertTrue(task.generalSettings.playSoundAfterCapture)
        XCTAssertTrue(task.generalSettings.showToastNotificationAfterTaskCompleted)
        XCTAssertFalse(task.generalSettings.useMacOSNotifications)

        let config = ApplicationConfig()
        XCTAssertEqual(config.taskViewMode, .thumbnailView)
        XCTAssertEqual(config.recentTasksMaxCount, 10)
        XCTAssertEqual(config.uploadLimit, 5)
        XCTAssertEqual(config.saveImageSubFolderPattern, "%y-%mo")
        XCTAssertTrue(config.showUploadWarning)
        XCTAssertEqual(config.trayLeftClickAction, .toggleTrayMenu)
        XCTAssertEqual(config.trayLeftDoubleClickAction, .openMainWindow)
        XCTAssertEqual(config.trayMiddleClickAction, .clipboardUploadWithContentViewer)
        XCTAssertTrue(config.showDockIcon)
        XCTAssertTrue(UplaSettings().stopRecordingAtUploadLimit)
    }

    func testFlagStringsLikeNewtonsoft() {
        XCTAssertEqual(AfterCaptureTasks.windowsDefault.windowsString, "CopyImageToClipboard, SaveImageToFile, UploadImageToHost")
        XCTAssertEqual(AfterCaptureTasks().windowsString, "None")
        XCTAssertEqual(AfterUploadTasks([.openURL, .copyURLToClipboard]).windowsString, "CopyURLToClipboard, OpenURL")
    }

    func testFlagStringsAreReadTolerantly() {
        XCTAssertEqual(AfterCaptureTasks(windowsString: "uploadimagetohost,  SaveImageToFile"), [.uploadImageToHost, .saveImageToFile])
        XCTAssertEqual(AfterCaptureTasks(windowsString: "None"), [])
        // A task this version does not know (UpLa removed AnalyzeImage) is dropped, the rest is kept.
        XCTAssertEqual(AfterCaptureTasks(windowsString: "AnalyzeImage, CopyImageToClipboard"), [.copyImageToClipboard])
        XCTAssertNil(AfterCaptureTasks(windowsString: "AnalyzeImage"))
    }

    func testFlagsDecodeFromStringsAndNumbers() throws {
        struct Box: Decodable {
            var job: AfterCaptureTasks
        }

        let decoder = ConfigJSON.decoder()
        let text = try decoder.decode(Box.self, from: Data(#"{"job": "CopyImageToClipboard, UploadImageToHost"}"#.utf8))
        XCTAssertEqual(text.job, [.copyImageToClipboard, .uploadImageToHost])
        // 1 << 10 is no flag any more and is dropped.
        let number = try decoder.decode(Box.self, from: Data(#"{"job": \#(32 | 1024)}"#.utf8))
        XCTAssertEqual(number.job, .copyImageToClipboard)
    }

    func testFlagFieldFallsBackToDefaultWhenUnreadable() throws {
        let json = #"{"AfterCaptureJob": "SomethingNew", "AfterUploadJob": "OpenURL"}"#
        let task = try ConfigJSON.decoder().decode(TaskSettings.self, from: Data(json.utf8))
        XCTAssertEqual(task.afterCaptureJob, .windowsDefault)
        XCTAssertEqual(task.afterUploadJob, .openURL)
    }

    // MARK: JSON

    func testTaskSettingsUseWindowsFieldNames() throws {
        var task = TaskSettings()
        task.afterUploadJob = [.copyURLToClipboard, .openURL]
        let object = try jsonObject(task)

        XCTAssertEqual(object["AfterCaptureJob"] as? String, "CopyImageToClipboard, SaveImageToFile, UploadImageToHost")
        XCTAssertEqual(object["AfterUploadJob"] as? String, "CopyURLToClipboard, OpenURL")
        XCTAssertEqual(object["Job"] as? String, "None")
        XCTAssertEqual(object["UseDefaultAfterCaptureJob"] as? Bool, true)
        XCTAssertEqual(object["ImageDestination"] as? String, "Chevereto")
        XCTAssertEqual(object["URLSharingServiceDestination"] as? String, "Facebook")

        let capture = try XCTUnwrap(object["CaptureSettings"] as? [String: Any])
        XCTAssertEqual(capture["ShowCursor"] as? Bool, true)
        XCTAssertEqual(capture["ScreenRecordFPS"] as? Int, 30)
        XCTAssertEqual(capture["GIFFPS"] as? Int, 15)
        let image = try XCTUnwrap(object["ImageSettings"] as? [String: Any])
        XCTAssertEqual(image["ImageFormat"] as? String, "PNG")
        let upload = try XCTUnwrap(object["UploadSettings"] as? [String: Any])
        XCTAssertEqual(upload["NameFormatPattern"] as? String, "%ra{10}")
    }

    func testApplicationConfigRoundTrip() throws {
        var config = ApplicationConfig()
        config.defaultTaskSettings.afterCaptureJob = [.saveImageToFile, .showInExplorer]
        config.defaultTaskSettings.captureSettings.screenshotDelay = 2.5
        config.defaultTaskSettings.captureSettings.ffmpegOptions.audioSource = FFmpegOptions.systemAudioSource
        config.taskViewMode = .listView
        config.useCustomScreenshotsPath = true
        config.customScreenshotsPath = "/Users/test/Shots"
        config.showUploadWarning = false
        config.language = .turkish
        config.addRecentTask(RecentTask(filePath: "/tmp/a.png", url: "https://upla.com.tr/i/Ornek",
                                        deletionURL: "https://upla.com.tr/delete/x", time: Date(timeIntervalSince1970: 1_760_000_000.5)))

        let data = try ConfigJSON.encoder().encode(config)
        let decoded = try ConfigJSON.decoder().decode(ApplicationConfig.self, from: data)
        XCTAssertEqual(decoded, config)

        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["TaskViewMode"] as? String, "ListView")
        XCTAssertEqual(object["UseCustomScreenshotsPath"] as? Bool, true)
        XCTAssertEqual(object["TrayLeftClickAction"] as? String, "ToggleTrayMenu")
        let recent = try XCTUnwrap((object["RecentTasks"] as? [[String: Any]])?.first)
        XCTAssertEqual(recent["URL"] as? String, "https://upla.com.tr/i/Ornek")
        XCTAssertNotNil(recent["Time"] as? String)
    }

    func testEmptyAndPartialFilesGetDefaults() throws {
        XCTAssertEqual(try ConfigJSON.decoder().decode(ApplicationConfig.self, from: Data("{}".utf8)), ApplicationConfig())

        // A Windows-like file: unknown fields, a .NET date and a value of the wrong type.
        let json = """
        {
          "DefaultTaskSettings": { "AfterCaptureJob": "UploadImageToHost", "CaptureSettings": { "ShowCursor": false } },
          "FirstTimeRunDate": "2026-10-10T14:03:12.1234567+03:00",
          "TaskViewMode": "listview",
          "UploadLimit": "five",
          "RecentTasks": [ { "URL": "https://upla.com.tr/i/A", "Time": "2026-10-10T14:03:12.1234567+03:00" } ],
          "Themes": [ { "Name": "Dark" } ]
        }
        """
        let config = try ConfigJSON.decoder().decode(ApplicationConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.defaultTaskSettings.afterCaptureJob, .uploadImageToHost)
        XCTAssertFalse(config.defaultTaskSettings.captureSettings.showCursor)
        XCTAssertEqual(config.defaultTaskSettings.captureSettings.screenRecordFPS, 30)
        XCTAssertEqual(config.taskViewMode, .listView)
        XCTAssertEqual(config.uploadLimit, 5)
        let time = try XCTUnwrap(config.recentTasks?.first?.time)
        XCTAssertEqual(time.timeIntervalSince1970, 1_791_630_192.123, accuracy: 0.001)
    }

    func testRecentTasksKeepTheNewestTen() {
        var config = ApplicationConfig()

        for index in 1...12 {
            config.addRecentTask(RecentTask(url: "https://upla.com.tr/i/\(index)"))
        }

        XCTAssertEqual(config.recentTasks?.count, 10)
        XCTAssertEqual(config.recentTasks?.first?.url, "https://upla.com.tr/i/3")
        XCTAssertEqual(config.recentTasks?.last?.url, "https://upla.com.tr/i/12")

        config.recentTasksSave = false
        config.addRecentTask(RecentTask(url: "https://upla.com.tr/i/13"))
        XCTAssertEqual(config.recentTasks?.last?.url, "https://upla.com.tr/i/12")
    }

    func testUplaSettingsUseWindowsLinkTypeNames() throws {
        var settings = UplaSettings()
        settings.linkType = .directLink
        let object = try jsonObject(settings)
        XCTAssertEqual(object["LinkType"] as? String, "DirectLink")
        XCTAssertEqual(object["StopRecordingAtUploadLimit"] as? Bool, true)
        XCTAssertEqual(try ConfigJSON.decoder().decode(UplaSettings.self, from: ConfigJSON.encoder().encode(settings)), settings)

        let shortLink = try ConfigJSON.decoder().decode(UplaSettings.self, from: Data(#"{"LinkType": "ShortLink"}"#.utf8))
        XCTAssertEqual(shortLink.linkType, .shortLink)
    }

    func testScreenshotsFolder() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        let date = Date(timeIntervalSince1970: 1_791_630_192) // 2026-10-10
        let parent = URL(fileURLWithPath: "/Users/test/Documents/UpLa/Screenshots", isDirectory: true)

        var config = ApplicationConfig()
        XCTAssertEqual(config.screenshotsFolder(defaultParent: parent, date: date, calendar: calendar).path,
                       "/Users/test/Documents/UpLa/Screenshots/2026-10")

        config.useCustomScreenshotsPath = true
        config.customScreenshotsPath = "/Volumes/Shots"
        config.saveImageSubFolderPattern = ""
        XCTAssertEqual(config.screenshotsFolder(defaultParent: parent, date: date, calendar: calendar).path, "/Volumes/Shots")

        // An empty custom path falls back to the default folder, like Windows.
        config.customScreenshotsPath = "  "
        XCTAssertEqual(config.screenshotsParentFolder(defaultParent: parent), parent)
    }

    // The 0.1 Settings window: a chosen folder has no month subfolder, going back to the default brings it back.
    func testLegacySaveFolderChoice() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        let date = Date(timeIntervalSince1970: 1_791_630_192) // 2026-10-10
        let parent = URL(fileURLWithPath: "/Users/test/Documents/UpLa/Screenshots", isDirectory: true)

        var config = ApplicationConfig()
        config.setLegacySaveFolder("/Volumes/Shots")
        XCTAssertTrue(config.useCustomScreenshotsPath)
        XCTAssertEqual(config.screenshotsFolder(defaultParent: parent, date: date, calendar: calendar).path, "/Volumes/Shots")

        config.setLegacySaveFolder("")
        XCTAssertFalse(config.useCustomScreenshotsPath)
        XCTAssertEqual(config.saveImageSubFolderPattern, ApplicationConfig.defaultSaveImageSubFolderPattern)
        XCTAssertEqual(config.screenshotsFolder(defaultParent: parent, date: date, calendar: calendar).path,
                       "/Users/test/Documents/UpLa/Screenshots/2026-10")
    }

    // MARK: Hotkeys

    func testHotkeyTypeNamesAndOrder() {
        XCTAssertEqual(HotkeyType.allCases.count, 54)
        XCTAssertEqual(HotkeyType.allCases.filter { $0.category != nil }.count, 53)
        XCTAssertEqual(HotkeyType.allCases.first, HotkeyType.none)
        XCTAssertEqual(HotkeyType.printScreen.rawValue, "PrintScreen")
        XCTAssertEqual(HotkeyType.printScreen.windowsTitle, "Capture entire screen")
        XCTAssertEqual(HotkeyType(windowsName: "ExitUpLa"), .exitShareX)
        XCTAssertEqual(HotkeyType(windowsName: "rectangleregion"), .rectangleRegion)
        XCTAssertNil(HotkeyType(windowsName: "ShortenURL"))

        let categories = HotkeyType.allCases.compactMap(\.category)
        XCTAssertEqual(categories.filter { $0 == .upload }.count, 7)
        XCTAssertEqual(categories.filter { $0 == .screenCapture }.count, 10)
        XCTAssertEqual(categories.filter { $0 == .screenRecord }.count, 11)
        XCTAssertEqual(categories.filter { $0 == .tools }.count, 17)
        XCTAssertEqual(categories.filter { $0 == .other }.count, 8)
    }

    func testDefaultHotkeysOfDecision8() {
        let hotkeys = HotkeysConfig().hotkeys
        XCTAssertEqual(hotkeys.map(\.taskSettings.job), [.printScreen, .rectangleRegion, .activeWindow, .screenRecorder, .screenRecorderGIF])
        XCTAssertEqual(hotkeys.map(\.hotkeyInfo.displayText), ["⌥⇧⌘3", "⌥⇧⌘4", "⌥⇧⌘5", "⌥⇧⌘6", "⌥⇧⌘7"])
        XCTAssertEqual(hotkeys.map(\.hotkeyInfo.keyCode), [0x14, 0x15, 0x17, 0x16, 0x1A])
        XCTAssertTrue(hotkeys.allSatisfy { $0.taskSettings.isUsingDefaultSettings })
        // The GIF recording is in the list but not offered before phase 4. ⌥⇧⌘5 stays: until the active window
        // capture comes it runs 0.1's window selection.
        XCTAssertEqual(HotkeysConfig().availableHotkeys.map(\.taskSettings.job),
                       [.printScreen, .rectangleRegion, .activeWindow, .screenRecorder])
        // The default click action of the menu bar icon (decision 3) can be offered.
        XCTAssertTrue(ApplicationConfig().trayLeftClickAction.isAvailableOnMac)
    }

    #if canImport(Carbon)
    // UplaKit spells out Carbon's numbers; the Mac's own constants must agree.
    func testHotkeyNumbersMatchCarbon() {
        XCTAssertEqual(HotkeyInfo.commandModifier, UInt32(cmdKey))
        XCTAssertEqual(HotkeyInfo.shiftModifier, UInt32(shiftKey))
        XCTAssertEqual(HotkeyInfo.optionModifier, UInt32(optionKey))
        XCTAssertEqual(HotkeyInfo.controlModifier, UInt32(controlKey))
        XCTAssertEqual(HotkeyInfo.digitKeyCodes["3"], UInt32(kVK_ANSI_3))
        XCTAssertEqual(HotkeyInfo.digitKeyCodes["4"], UInt32(kVK_ANSI_4))
        XCTAssertEqual(HotkeyInfo.digitKeyCodes["5"], UInt32(kVK_ANSI_5))
        XCTAssertEqual(HotkeyInfo.digitKeyCodes["6"], UInt32(kVK_ANSI_6))
        XCTAssertEqual(HotkeyInfo.digitKeyCodes["7"], UInt32(kVK_ANSI_7))
    }
    #endif

    func testSetHotkeyMovesATakenShortcut() {
        var config = HotkeysConfig()
        let four = HotkeyInfo.optionShiftCommand("4")
        config.setHotkey(four, for: .printScreen)
        XCTAssertEqual(config.hotkeys[0].hotkeyInfo, four)
        XCTAssertTrue(config.hotkeys[1].hotkeyInfo.isNone)

        config.setHotkey(.none, for: .openHistory)
        XCTAssertEqual(config.hotkeys.last?.taskSettings.job, .openHistory)
    }

    func testHotkeysConfigRoundTrip() throws {
        var config = HotkeysConfig()
        config.hotkeys[2].taskSettings.useDefaultAfterCaptureJob = false
        config.hotkeys[2].taskSettings.afterCaptureJob = [.copyImageToClipboard]
        config.hotkeys[3].hotkeyInfo = .none

        let data = try ConfigJSON.encoder().encode(config)
        XCTAssertEqual(try ConfigJSON.decoder().decode(HotkeysConfig.self, from: data), config)

        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let rows = try XCTUnwrap(object["Hotkeys"] as? [[String: Any]])
        let task = try XCTUnwrap(rows[2]["TaskSettings"] as? [String: Any])
        XCTAssertEqual(task["Job"] as? String, "ActiveWindow")
        XCTAssertEqual(task["UseDefaultAfterCaptureJob"] as? Bool, false)
        XCTAssertNil((rows[3]["HotkeyInfo"] as? [String: Any])?["KeyCode"])
    }

    func testResolvedTaskSettingsFollowTheDefaults() {
        var defaults = TaskSettings()
        defaults.afterCaptureJob = [.saveImageToFile]
        defaults.captureSettings.showCursor = false

        var hotkey = TaskSettings()
        hotkey.useDefaultAfterCaptureJob = false
        hotkey.afterCaptureJob = [.copyImageToClipboard]

        let resolved = hotkey.resolved(with: defaults)
        XCTAssertEqual(resolved.afterCaptureJob, [.copyImageToClipboard])
        XCTAssertFalse(resolved.captureSettings.showCursor)
        XCTAssertFalse(hotkey.isUsingDefaultSettings)
    }

    // MARK: ConfigStore

    func testStoreSavesAndLoads() throws {
        let store = ConfigStore(directory: try makeDirectory())
        var config = ApplicationConfig()
        config.showUploadWarning = false
        try store.save(config, to: ConfigStore.applicationConfigFileName)

        guard case .loaded(let loaded) = store.load(ApplicationConfig.self, from: ConfigStore.applicationConfigFileName) else {
            return XCTFail("not loaded")
        }
        XCTAssertEqual(loaded, config)

        #if !os(Windows)
        let attributes = try FileManager.default.attributesOfItem(atPath: store.fileURL(ConfigStore.applicationConfigFileName).path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
        #endif

        // A second save replaces the file and leaves no temporary file behind.
        config.uploadLimit = 3
        try store.save(config, to: ConfigStore.applicationConfigFileName)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: store.directory.path).sorted(),
                       [ConfigStore.applicationConfigFileName, ConfigStore.applicationConfigFileName + ".bak"])

        guard case .missing = store.load(HotkeysConfig.self, from: ConfigStore.hotkeysConfigFileName) else {
            return XCTFail("expected missing")
        }
    }

    func testStoreKeepsAnUnreadableFileAndUsesTheBackup() throws {
        let directory = try makeDirectory()
        let store = ConfigStore(directory: directory)
        var first = ApplicationConfig()
        first.uploadLimit = 3
        try store.save(first, to: ConfigStore.applicationConfigFileName)
        var second = first
        second.uploadLimit = 4
        // The second save keeps the first as ApplicationConfig.json.bak.
        try store.save(second, to: ConfigStore.applicationConfigFileName)

        let url = store.fileURL(ConfigStore.applicationConfigFileName)
        try Data("{ not json".utf8).write(to: url)

        guard case .damaged(let preserved, let backup) = store.load(ApplicationConfig.self, from: ConfigStore.applicationConfigFileName) else {
            return XCTFail("expected damaged")
        }

        let preservedURL = try XCTUnwrap(preserved)
        XCTAssertEqual(try String(contentsOf: preservedURL, encoding: .utf8), "{ not json")
        XCTAssertTrue(preservedURL.lastPathComponent.hasPrefix("ApplicationConfig-unreadable-"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(backup?.uploadLimit, 3)

        // loadAll uses the backup instead of the 0.1 settings and writes a good file again.
        try Data("{ not json".utf8).write(to: url)
        let result = store.loadAll(legacy: { [SettingsMigration.LegacyKey.showUploadWarning: false] },
                                   legacyDefaultSaveFolder: "/tmp")
        XCTAssertEqual(result.configs.application.uploadLimit, 3)
        XCTAssertTrue(result.configs.application.showUploadWarning)

        guard case .loaded(let rewritten) = store.load(ApplicationConfig.self, from: ConfigStore.applicationConfigFileName) else {
            return XCTFail("not rewritten")
        }
        XCTAssertEqual(rewritten.uploadLimit, 3)
    }

    func testDamagedFileWithoutBackupIsMigrated() throws {
        let store = ConfigStore(directory: try makeDirectory())
        try store.save(HotkeysConfig(), to: ConfigStore.hotkeysConfigFileName)
        try store.save(UploadersConfig(), to: ConfigStore.uploadersConfigFileName)
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try Data("[]".utf8).write(to: store.fileURL(ConfigStore.applicationConfigFileName))

        let result = store.loadAll(legacy: { [SettingsMigration.LegacyKey.showUploadWarning: false] }, legacyDefaultSaveFolder: "/tmp")
        XCTAssertTrue(result.migrated)
        XCTAssertFalse(result.configs.application.showUploadWarning)
        let files = try FileManager.default.contentsOfDirectory(atPath: store.directory.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("ApplicationConfig-unreadable-") })
    }

    func testLoadAllMigratesOnceAndThenReadsTheFiles() throws {
        let store = ConfigStore(directory: try makeDirectory())
        var legacyCalls = 0
        let legacy: () -> [String: Any] = {
            legacyCalls += 1
            return [SettingsMigration.LegacyKey.uploadAfterCapture: false]
        }

        let first = store.loadAll(legacy: legacy, legacyDefaultSaveFolder: "/tmp/Pictures/UpLa")
        XCTAssertTrue(first.migrated)
        XCTAssertEqual(legacyCalls, 1)
        XCTAssertFalse(first.configs.application.defaultTaskSettings.afterCaptureJob.contains(.uploadImageToHost))

        for name in [ConfigStore.applicationConfigFileName, ConfigStore.hotkeysConfigFileName, ConfigStore.uploadersConfigFileName] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL(name).path), name)
        }

        let second = store.loadAll(legacy: legacy, legacyDefaultSaveFolder: "/tmp/Pictures/UpLa")
        XCTAssertFalse(second.migrated)
        XCTAssertEqual(legacyCalls, 1)
        XCTAssertEqual(second.configs, first.configs)
    }

    // MARK: Helpers

    private func jsonObject<T: Encodable>(_ value: T) throws -> [String: Any] {
        let data = try ConfigJSON.encoder().encode(value)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("UplaKitConfig-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }
}

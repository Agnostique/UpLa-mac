import Foundation
import XCTest
@testable import UplaKit

/// The move from the 0.1 UserDefaults to the Windows model (plan §2.6), and the menus as data (inventory §1, §2.2).
final class SettingsMigrationTests: XCTestCase {
    private typealias Key = SettingsMigration.LegacyKey
    private let legacyFolder = "/Users/test/Pictures/UpLa"

    private func migrate(_ legacy: [String: Any]) -> ConfigSet {
        SettingsMigration.migrate(legacy: legacy, legacyDefaultSaveFolder: legacyFolder)
    }

    func testFreshInstallGetsWindowsDefaults() {
        let configs = migrate([:])
        XCTAssertEqual(configs, ConfigSet())
        XCTAssertEqual(configs.application.defaultTaskSettings.afterCaptureJob, [.copyImageToClipboard, .saveImageToFile, .uploadImageToHost])
        XCTAssertEqual(configs.application.defaultTaskSettings.afterUploadJob, [.copyURLToClipboard])
        XCTAssertFalse(configs.application.useCustomScreenshotsPath)
        XCTAssertEqual(configs.application.saveImageSubFolderPattern, "%y-%mo")
        XCTAssertEqual(configs.hotkeys, HotkeysConfig())
    }

    // A 0.1 user who only ever kept the defaults but switched the copy and save toggles off explicitly.
    func testUploadOnlyUserKeepsUploadOnly() {
        let configs = migrate([Key.uploadAfterCapture: true, Key.copyImageAfterCapture: false, Key.saveAfterCapture: false])
        XCTAssertEqual(configs.application.defaultTaskSettings.afterCaptureJob, [.uploadImageToHost])
        XCTAssertEqual(configs.application.defaultTaskSettings.afterUploadJob, [.copyURLToClipboard])
        XCTAssertFalse(configs.application.useCustomScreenshotsPath)
    }

    func testUploadTurnedOffKeepsCopyingLinksOfOtherUploads() {
        let configs = migrate([Key.uploadAfterCapture: false])
        let task = configs.application.defaultTaskSettings
        XCTAssertFalse(task.afterCaptureJob.contains(.uploadImageToHost))
        // Copy and save were never touched: the Windows defaults.
        XCTAssertTrue(task.afterCaptureJob.contains(.copyImageToClipboard))
        XCTAssertTrue(task.afterCaptureJob.contains(.saveImageToFile))
        XCTAssertEqual(task.afterUploadJob, [.copyURLToClipboard])
    }

    func testCopyAndSaveChosenWithTheDefaultFolder() {
        // NSNumber-like values from a property list (Int instead of Bool) are read too.
        let configs = migrate([Key.copyImageAfterCapture: 1, Key.saveAfterCapture: true, Key.uploadAfterCapture: false])
        let application = configs.application
        XCTAssertEqual(application.defaultTaskSettings.afterCaptureJob, [.copyImageToClipboard, .saveImageToFile])
        // Files keep going where 0.1 saved them.
        XCTAssertTrue(application.useCustomScreenshotsPath)
        XCTAssertEqual(application.customScreenshotsPath, legacyFolder)
        XCTAssertEqual(application.saveImageSubFolderPattern, "")
    }

    func testCustomFolderIsKept() {
        let configs = migrate([Key.saveFolderPath: "/Volumes/Shots", Key.saveAfterCapture: false])
        let application = configs.application
        XCTAssertTrue(application.useCustomScreenshotsPath)
        XCTAssertEqual(application.customScreenshotsPath, "/Volumes/Shots")
        XCTAssertEqual(application.saveImageSubFolderPattern, "")
        XCTAssertFalse(application.defaultTaskSettings.afterCaptureJob.contains(.saveImageToFile))
    }

    func testOtherSettingsAreCarriedOver() {
        let configs = migrate([
            Key.showNotifications: false, Key.showUploadWarning: false,
            Key.linkType: "directLink", Key.album: "https://upla.com.tr/album/A.b", Key.tags: "a,b", Key.categoryID: 4,
            Key.expiration: "P1D", Key.maxWidth: 1920, Key.stopRecordingAtUploadLimit: false,
            Key.recordingFramesPerSecond: 60, Key.recordingShowsCursor: false, Key.recordingCapturesAudio: true
        ])
        let task = configs.application.defaultTaskSettings
        XCTAssertFalse(task.generalSettings.showToastNotificationAfterTaskCompleted)
        XCTAssertFalse(configs.application.showUploadWarning)
        XCTAssertEqual(task.captureSettings.screenRecordFPS, 60)
        XCTAssertFalse(task.captureSettings.screenRecordShowCursor)
        XCTAssertEqual(task.captureSettings.ffmpegOptions.audioSource, FFmpegOptions.systemAudioSource)

        let upla = configs.uploaders.uplaSettings
        XCTAssertEqual(upla.linkType, .directLink)
        XCTAssertEqual(upla.album, "https://upla.com.tr/album/A.b")
        XCTAssertEqual(upla.tags, "a,b")
        XCTAssertEqual(upla.categoryID, 4)
        XCTAssertEqual(upla.expiration, "P1D")
        XCTAssertEqual(upla.maxWidth, 1920)
        XCTAssertFalse(upla.stopRecordingAtUploadLimit)
    }

    func testInvalidValuesGetDefaults() {
        let configs = migrate([Key.recordingFramesPerSecond: 24, Key.expiration: "forever", Key.linkType: "bogus", Key.maxWidth: -5])
        XCTAssertEqual(configs.application.defaultTaskSettings.captureSettings.screenRecordFPS, 30)
        XCTAssertEqual(configs.uploaders.uplaSettings.expiration, "")
        XCTAssertEqual(configs.uploaders.uplaSettings.linkType, .viewerPage)
        XCTAssertEqual(configs.uploaders.uplaSettings.maxWidth, 0)
    }

    func testHotkeysAreCarriedOver() {
        let ctrlOptionR: [String: Any] = ["keyCode": 15, "modifiers": Int(HotkeyInfo.controlModifier | HotkeyInfo.optionModifier), "key": "r"]
        let configs = migrate([
            Key.hotkeyPrefix + "region": ctrlOptionR,
            // An empty dictionary: the user removed the shortcut.
            Key.hotkeyPrefix + "fullScreen": [String: Any](),
            Key.hotkeyPrefix + "window": ["keyCode": 0x17, "modifiers": Int(HotkeyInfo.commandModifier | HotkeyInfo.shiftModifier), "key": "5"]
        ])

        let byJob = Dictionary(uniqueKeysWithValues: configs.hotkeys.hotkeys.map { ($0.taskSettings.job, $0.hotkeyInfo) })
        XCTAssertEqual(byJob[.rectangleRegion], HotkeyInfo(keyCode: 15, modifiers: HotkeyInfo.controlModifier | HotkeyInfo.optionModifier, key: "r"))
        XCTAssertEqual(byJob[.rectangleRegion]?.displayText, "⌃⌥R")
        XCTAssertEqual(byJob[.printScreen]?.isNone, true)
        // 0.1's window shortcut goes to the active window (decision 8).
        XCTAssertEqual(byJob[.activeWindow]?.displayText, "⇧⌘5")
        // Not stored: the defaults.
        XCTAssertEqual(byJob[.screenRecorder], .optionShiftCommand("6"))
        XCTAssertEqual(byJob[.screenRecorderGIF], .optionShiftCommand("7"))
        XCTAssertEqual(configs.hotkeys.hotkeys.count, 5)
    }

    func testHotkeyTakenFromAnotherAction() {
        // 0.1 moved a shortcut between actions; here region got ⌥⇧⌘3, which full screen had by default.
        let configs = migrate([Key.hotkeyPrefix + "region": ["keyCode": 0x14, "modifiers": Int(HotkeyInfo.optionModifier | HotkeyInfo.shiftModifier | HotkeyInfo.commandModifier), "key": "3"]])
        let byJob = Dictionary(uniqueKeysWithValues: configs.hotkeys.hotkeys.map { ($0.taskSettings.job, $0.hotkeyInfo) })
        XCTAssertEqual(byJob[.rectangleRegion]?.displayText, "⌥⇧⌘3")
        XCTAssertEqual(byJob[.printScreen]?.isNone, true)
    }
}

final class MenuSpecTests: XCTestCase {
    func testMainWindowPanelOrder() {
        let panel = MenuSpec.mainWindowPanel
        XCTAssertEqual(panel.filter { !$0.isSeparator }.map(\.title), [
            "Capture", "Upload", "Tools", "After capture tasks", "After upload tasks", "Destinations",
            "Application settings...", "Task settings...", "Hotkey settings...", "Destination settings...", "Sign in",
            "Screenshots folder...", "History...", "Image history...", "Debug", "About..."
        ])
        XCTAssertEqual(panel.map(\.isSeparator).enumerated().filter(\.element).map(\.offset), [3, 7, 13, 17])
        XCTAssertEqual(panel.compactMap(\.icon), [
            .fugue("camera"), .fugue("arrow_090"), .fugue("toolbox"), .fugue("image_export"), .fugue("upload_cloud"),
            .fugue("drive_globe"), .fugue("wrench_screwdriver"), .fugue("gear"), .fugue("keyboard"), .fugue("globe_pencil"),
            .appLogo, .fugue("folder_open_image"), .fugue("application_blog"), .fugue("application_icon_large"),
            .fugue("traffic_cone"), .fugue("crown")
        ])
    }

    func testCaptureMenu() {
        let menu = MenuSpec.captureMenu
        XCTAssertEqual(menu.map(\.title), [
            "Fullscreen", "Window", "Monitor", "Region", "Region (Light)", "Region (Transparent)", "Last region",
            "Screen recording", "Screen recording (GIF)", "Scrolling capture...", "", "Show cursor", "Screenshot delay: {0}s"
        ])
        XCTAssertEqual(menu.last?.children.map(\.title), ["No delay", "1 second", "2 seconds", "3 seconds", "4 seconds", "5 seconds"])
        // Windows shows shortcuts only on the Workflows items.
        XCTAssertTrue(menu.allSatisfy { $0.shortcut == nil })
    }

    func testUploadMenus() {
        XCTAssertEqual(MenuSpec.uploadMenu.map(\.title), ["Upload file...", "Upload folder...", "Drag and drop upload..."])
        XCTAssertEqual(MenuSpec.trayUploadMenu.map(\.title),
                       ["Upload file...", "Upload folder...", "Upload from clipboard...", "Upload from URL...", "Drag and drop upload..."])
    }

    func testToolsMenu() {
        XCTAssertEqual(MenuSpec.toolsMenu.map(\.title), [
            "Color picker...", "Screen color picker...", "Ruler...", "Pin to screen...", "", "Image editor...",
            "Image beautifier...", "Image effects...", "Image viewer...", "Image combiner...", "", "OCR...", "QR code..."
        ])
    }

    func testAfterCaptureMenuHasTheTwentyTasksInWindowsOrder() {
        let menu = MenuSpec.afterCaptureMenu
        XCTAssertEqual(menu.count, 20)
        XCTAssertEqual(menu.map(\.title), [
            "Show quick task menu", "Show \"After capture\" window", "Beautify image", "Add image effects",
            "Open in image editor", "Copy image to clipboard", "Pin to screen", "Print image", "Save image to file",
            "Save image to file as...", "Perform actions", "Copy file to clipboard", "Copy file path to clipboard",
            "Copy folder path to clipboard", "Show file in explorer", "Scan QR code", "Recognize text (OCR)",
            "Show \"Before upload\" window", "Upload image to host", "Delete file locally"
        ])
        // Every item is bound to its own flag, in the order of the bits.
        let flags = menu.compactMap { item -> AfterCaptureTasks? in
            if case .afterCapture(let flag) = item.check {
                return flag
            }
            return nil
        }
        XCTAssertEqual(flags, AfterCaptureTasks.windowsNames.map(\.flag))
        XCTAssertEqual(menu.filter { $0.availability.isAvailable }.map(\.title),
                       ["Copy image to clipboard", "Save image to file", "Upload image to host"])
    }

    func testAfterUploadMenu() {
        XCTAssertEqual(MenuSpec.afterUploadMenu.map(\.title),
                       ["Show \"After upload\" window", "Share URL", "Copy URL to clipboard", "Open URL", "Show QR code window"])
    }

    // Windows 2.0.2 checked by position: with the defaults it showed "Upload image to host" unchecked and "Open URL"
    // checked (inventory §12.1). Here the checks come from the values.
    func testChecksShowTheRealDefaults() {
        let task = TaskSettings()
        let checkedCapture = MenuSpec.afterCaptureMenu.filter { MenuSpec.isChecked($0.check!, in: task) }.map(\.title)
        XCTAssertEqual(checkedCapture, ["Copy image to clipboard", "Save image to file", "Upload image to host"])
        let checkedUpload = MenuSpec.afterUploadMenu.filter { MenuSpec.isChecked($0.check!, in: task) }.map(\.title)
        XCTAssertEqual(checkedUpload, ["Copy URL to clipboard"])
    }

    func testTogglesChangeOnlyTheirFlag() {
        var task = TaskSettings()
        let upload = MenuSpec.afterCaptureMenu.first { $0.title == "Upload image to host" }!
        task = MenuSpec.applying(upload.check!, to: task)
        XCTAssertEqual(task.afterCaptureJob, [.copyImageToClipboard, .saveImageToFile])
        task = MenuSpec.applying(upload.check!, to: task)
        XCTAssertEqual(task.afterCaptureJob, .windowsDefault)

        task = MenuSpec.applying(.showCursor, to: task)
        XCTAssertFalse(task.captureSettings.showCursor)

        task = MenuSpec.applying(.screenshotDelay(3), to: task)
        XCTAssertTrue(MenuSpec.isChecked(.screenshotDelay(3), in: task))
        XCTAssertFalse(MenuSpec.isChecked(.screenshotDelay(0), in: task))
        XCTAssertTrue(MenuSpec.isChecked(.screenshotDelayActive, in: task))
        XCTAssertEqual(MenuSpec.titleArgumentText(.screenshotDelay, in: task), "3")

        // A delay set elsewhere that the menu does not offer checks none of the choices.
        task.captureSettings.screenshotDelay = 2.5
        XCTAssertEqual(MenuSpec.screenshotDelays.filter { MenuSpec.isChecked(.screenshotDelay($0.seconds), in: task) }.count, 0)
        XCTAssertEqual(MenuSpec.titleArgumentText(.screenshotDelay, in: task), "2.5")
    }

    func testDestinations() {
        XCTAssertEqual(MenuSpec.destinationsMenu.map(\.title), ["Image uploader: {0}"])
        XCTAssertEqual(MenuSpec.trayDestinationsMenu.map(\.title),
                       ["Image uploader: {0}", "Text uploader: {0}", "File uploader: {0}", "URL sharing service: {0}"])
        XCTAssertEqual(MenuSpec.trayDestinationsMenu.last?.children.map(\.title),
                       ["Facebook", "Reddit", "Pinterest", "Tumblr", "LinkedIn", "VK"])

        let image = MenuSpec.destinationsMenu[0]
        XCTAssertEqual(image.children.map(\.title), ["upla.com.tr", "File uploader"])
        XCTAssertEqual(image.children[1].children.map(\.title), ["upla.com.tr"])

        var task = TaskSettings()
        XCTAssertTrue(MenuSpec.isChecked(.imageDestination(.chevereto), in: task))
        XCTAssertFalse(MenuSpec.isChecked(.imageFileDestination(.chevereto), in: task))
        task = MenuSpec.applying(.imageFileDestination(.chevereto), to: task)
        XCTAssertTrue(MenuSpec.isChecked(.imageDestination(.fileUploader), in: task))
        XCTAssertTrue(MenuSpec.isChecked(.imageFileDestination(.chevereto), in: task))
        XCTAssertEqual(MenuSpec.titleArgumentText(.imageUploader, in: task), "upla.com.tr")
        XCTAssertEqual(MenuSpec.titleArgumentText(.urlSharingService, in: task), "Facebook")
    }

    func testTrayMenuOrder() {
        let tray = MenuSpec.trayMenu
        XCTAssertEqual(tray.count, 25)
        XCTAssertEqual(tray.map(\.title), [
            "Capture", "Upload", "Workflows", "Tools", "", "After capture tasks", "After upload tasks", "Destinations", "",
            "Application settings...", "Task settings...", "Hotkey settings...", "Disable hotkeys", "Destination settings...",
            "upla.com.tr account", "", "Screenshots folder...", "History...", "Image history...", "",
            "Restart UpLa as admin", "Recent links", "Toggle actions toolbar", "Open main window", "Exit"
        ])
        let toggle = tray[12]
        XCTAssertEqual(toggle.alternateTitle, "Enable hotkeys")
        XCTAssertEqual(toggle.icon, .fugue("keyboard__minus"))
        XCTAssertEqual(toggle.alternateIcon, .fugue("keyboard__plus"))
        XCTAssertEqual(tray[20].availability, .windowsOnly)
    }

    func testDebugMenu() {
        XCTAssertEqual(MenuSpec.debugMenu.map(\.title), ["Debug log...", "Test image upload"])
    }

    func testItemIDsAreUniqueInEachMenu() {
        func check(_ items: [MenuItem], _ name: String) {
            let ids = items.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, name)

            for item in items {
                check(item.children, item.id)
            }
        }

        check(MenuSpec.mainWindowPanel, "panel")
        check(MenuSpec.trayMenu, "tray")
    }

    func testVisibleItemsHideUnfinishedOnesAndTidySeparators() {
        let visible = MenuSpec.visibleItems(MenuSpec.trayMenu)
        XCTAssertEqual(visible.map(\.title), [
            "Capture", "Upload", "", "After capture tasks", "",
            "Application settings...", "Hotkey settings...", "Destination settings...", "upla.com.tr account", "",
            "History...", "", "Recent links", "Exit"
        ])
        XCTAssertEqual(visible[0].children.map(\.title), ["Fullscreen", "Region", "Screen recording"])
        XCTAssertEqual(visible[1].children.map(\.title), ["Upload file...", "Upload from clipboard..."])
        XCTAssertEqual(visible[3].children.count, 3)

        let all = MenuSpec.visibleItems(MenuSpec.trayMenu, includePlanned: true)
        XCTAssertFalse(all.contains { $0.title == "Restart UpLa as admin" })
        XCTAssertEqual(all.count, 24)
    }

    func testCatalogKeys() {
        XCTAssertEqual(MenuText.catalogKey("Upload file..."), "Upload file…")
        XCTAssertEqual(MenuText.catalogKey("Screenshot delay: {0}s"), "Screenshot delay: %@s")
        XCTAssertEqual(MenuText.catalogKey("Show file in explorer"), "Show file in Finder")
        XCTAssertEqual(MenuText.catalogKey("Capture"), "Capture")
        XCTAssertEqual(MenuText.catalogKey(HotkeyType.toggleTrayMenu.windowsTitle), "Toggle menu bar menu")

        // The menu bar menu's item has its own key ("UpLa penceresini göster"), the task type the plain one.
        let openMainWindow = MenuSpec.trayMenu.first { $0.id == "openMainWindow" }
        XCTAssertEqual(openMainWindow.map { MenuText.catalogKey(of: $0) }, "Open main window (menu bar menu)")
        XCTAssertEqual(MenuText.catalogKey(HotkeyType.openMainWindow.windowsTitle), "Open main window")

        let toggleHotkeys = MenuSpec.trayMenu.first { $0.id == "toggleHotkeys" }
        XCTAssertEqual(toggleHotkeys.map { MenuText.catalogKey(of: $0, alternate: true) }, "Enable hotkeys")
    }

    // Every text the menus and the task type lists look up is in the String Catalog, with its Turkish. The catalog
    // is in the app (App/Resources); UPLA_CATALOG points at it when the package was copied elsewhere.
    func testEveryMenuAndTaskTypeKeyIsInTheCatalog() throws {
        let environment = ProcessInfo.processInfo.environment["UPLA_CATALOG"]
        let nextToPackage = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Resources/Localizable.xcstrings")
        let url = environment.map { URL(fileURLWithPath: $0) } ?? nextToPackage

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("Localizable.xcstrings not found; set UPLA_CATALOG to its path.")
        }

        let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let strings = try XCTUnwrap(catalog?["strings"] as? [String: Any])

        func turkish(_ key: String) -> String? {
            let entry = strings[key] as? [String: Any]
            let localizations = entry?["localizations"] as? [String: Any]
            let tr = localizations?["tr"] as? [String: Any]
            let unit = tr?["stringUnit"] as? [String: Any]
            return unit?["value"] as? String
        }

        // Shown as they are: the site name and the URL sharing services.
        let verbatim: Set<String> = Set(["upla.com.tr"] + URLSharingService.allCases.map(\.rawValue))

        func keys(_ items: [MenuItem]) -> [String] {
            items.flatMap { item -> [String] in
                guard !item.isSeparator, item.availability != .windowsOnly else {
                    return []
                }

                var result = verbatim.contains(item.title) ? [] : [MenuText.catalogKey(of: item)]
                if item.alternateTitle != nil {
                    result.append(MenuText.catalogKey(of: item, alternate: true))
                }
                return result + keys(item.children)
            }
        }

        let menuKeys = keys(MenuSpec.mainWindowPanel) + keys(MenuSpec.trayMenu)
        let taskKeys = HotkeyType.allCases.map { MenuText.catalogKey($0.windowsTitle) }

        for key in Set(menuKeys + taskKeys) {
            XCTAssertNotNil(turkish(key), "\(key) is not in the catalog")
        }

        XCTAssertEqual(turkish("Open main window (menu bar menu)"), "UpLa penceresini göster")
        XCTAssertEqual(turkish("Open main window"), "Ana pencereyi aç")
    }

    func testEveryIconIsAFugueResourceName() {
        func icons(_ items: [MenuItem]) -> [String] {
            items.flatMap { item -> [String] in
                var names: [String] = []
                if case .fugue(let name) = item.icon {
                    names.append(name)
                }
                if case .fugue(let name) = item.alternateIcon {
                    names.append(name)
                }
                return names + icons(item.children)
            }
        }

        let names = Set(icons(MenuSpec.mainWindowPanel) + icons(MenuSpec.trayMenu))
        // Windows resource names: lower case with underscores (Rectangle is the one exception).
        for name in names {
            XCTAssertTrue(name == "Rectangle" || name.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }, name)
        }
        XCTAssertEqual(names.count, 72)
    }
}

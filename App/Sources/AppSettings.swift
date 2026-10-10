import Combine
import Foundation
import UplaKit

// User settings, kept like UpLa for Windows in ApplicationConfig.json, HotkeysConfig.json and UploadersConfig.json in
// ~/Library/Application Support/UpLa (UplaKit's ConfigStore). The first launch of this version moves the 0.1
// settings from UserDefaults there; the old keys are left alone, so 0.1 still finds them after a downgrade. The
// properties below are the 0.1 interface over the new model, so the rest of the app is unchanged. The account and its
// key live in AccountStore (key in the keychain).
@MainActor
final class AppSettings: ObservableObject {
    // The frame rates a recording can use.
    static let recordingFrameRates = [30, 60]

    private let store: ConfigStore

    // Saved whenever they change.
    @Published var config: ApplicationConfig { didSet { save(config, oldValue, ConfigStore.applicationConfigFileName) } }
    @Published var hotkeysConfig: HotkeysConfig { didSet { save(hotkeysConfig, oldValue, ConfigStore.hotkeysConfigFileName) } }
    @Published var uploadersConfig: UploadersConfig {
        didSet { save(uploadersConfig, oldValue, ConfigStore.uploadersConfigFileName) }
    }

    // ~/Library/Application Support/UpLa, next to history.json.
    nonisolated static var configDirectory: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return support.appendingPathComponent("UpLa", isDirectory: true)
    }

    // Where screenshots go unless the user chose a folder: Documents/UpLa/Screenshots, like the personal folder of
    // UpLa for Windows (decision 9); the month subfolder comes from the settings.
    nonisolated static var defaultSaveFolder: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
        return documents.appendingPathComponent("UpLa", isDirectory: true).appendingPathComponent("Screenshots", isDirectory: true)
    }

    // 0.1's save folder, kept for users who saved there (SettingsMigration). Also the fallback for captures that must
    // be kept when the chosen folder fails: unlike Documents, Pictures asks for no permission, so it cannot fail too.
    nonisolated static var legacyDefaultSaveFolder: URL {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures", isDirectory: true)
        return pictures.appendingPathComponent("UpLa", isDirectory: true)
    }

    init(store: ConfigStore = ConfigStore(directory: AppSettings.configDirectory), defaults: UserDefaults = .standard) {
        self.store = store
        // Only what the user stored (not registered defaults), so untouched settings get the Windows defaults.
        let domain = Bundle.main.bundleIdentifier ?? "tr.com.upla.UpLa"
        let loaded = store.loadAll(legacy: { defaults.persistentDomain(forName: domain) ?? [:] },
                                   legacyDefaultSaveFolder: AppSettings.legacyDefaultSaveFolder.path)
        config = loaded.configs.application
        hotkeysConfig = loaded.configs.hotkeys
        uploadersConfig = loaded.configs.uploaders

        if loaded.migrated {
            appLog.notice("Settings were created from the UserDefaults of an earlier version")
        }
    }

    private func save<Value: Encodable & Equatable>(_ value: Value, _ oldValue: Value, _ fileName: String) {
        guard value != oldValue else {
            return
        }

        do {
            try store.save(value, to: fileName)
        } catch {
            appLog.error("Saving \(fileName, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: The 0.1 interface

    var taskSettings: TaskSettings {
        get { config.defaultTaskSettings }
        set { config.defaultTaskSettings = newValue }
    }

    // Notifications about finished uploads; failures are always reported.
    var showNotifications: Bool {
        get { taskSettings.generalSettings.showToastNotificationAfterTaskCompleted }
        set { taskSettings.generalSettings.showToastNotificationAfterTaskCompleted = newValue }
    }

    // 0.1's "Upload to upla.com.tr and copy the link": the Windows Upload image to host task, and on turning it on
    // also Copy URL to clipboard. Turning it off leaves the link copying of other uploads alone. Changed in a copy and
    // assigned once, so the file (and its backup) is written once with both changes.
    var uploadAfterCapture: Bool {
        get { taskSettings.afterCaptureJob.contains(.uploadImageToHost) }
        set {
            var task = taskSettings

            if newValue {
                task.afterCaptureJob.insert(.uploadImageToHost)
                task.afterUploadJob.insert(.copyURLToClipboard)
            } else {
                task.afterCaptureJob.remove(.uploadImageToHost)
            }

            taskSettings = task
        }
    }

    var copyImageAfterCapture: Bool {
        get { taskSettings.afterCaptureJob.contains(.copyImageToClipboard) }
        set { setAfterCapture(.copyImageToClipboard, newValue) }
    }

    var saveAfterCapture: Bool {
        get { taskSettings.afterCaptureJob.contains(.saveImageToFile) }
        set { setAfterCapture(.saveImageToFile, newValue) }
    }

    // The custom screenshots folder of Application settings › Paths; empty means the default one. Set by the 0.1
    // Settings window: a chosen folder gets the files without the month subfolder (ApplicationConfig.setLegacySaveFolder).
    // Choosing the default folder itself keeps the Windows default, month subfolder included.
    var saveFolderPath: String {
        get { config.useCustomScreenshotsPath ? config.customScreenshotsPath : "" }
        set {
            let isDefault = URL(fileURLWithPath: newValue).standardizedFileURL.path == Self.defaultSaveFolder.standardizedFileURL.path
            config.setLegacySaveFolder(isDefault ? "" : newValue)
        }
    }

    // upla.com.tr upload options (album and tags are sent only with a member key).
    var linkType: UplaLinkType {
        get { uploadersConfig.uplaSettings.linkType }
        set { uploadersConfig.uplaSettings.linkType = newValue }
    }

    var album: String {
        get { uploadersConfig.uplaSettings.album }
        set { uploadersConfig.uplaSettings.album = newValue }
    }

    var tags: String {
        get { uploadersConfig.uplaSettings.tags }
        set { uploadersConfig.uplaSettings.tags = newValue }
    }

    var categoryID: Int {
        get { max(0, uploadersConfig.uplaSettings.categoryID) }
        set { uploadersConfig.uplaSettings.categoryID = newValue }
    }

    // One of Upla.expirationPresets, empty for no automatic deletion.
    var expiration: String {
        get {
            let value = uploadersConfig.uplaSettings.expiration
            return Upla.expirationPresets.contains(value) ? value : ""
        }
        set { uploadersConfig.uplaSettings.expiration = newValue }
    }

    // Server side resize of wider images, 0 = off.
    var maxWidth: Int {
        get { max(0, uploadersConfig.uplaSettings.maxWidth) }
        set { uploadersConfig.uplaSettings.maxWidth = newValue }
    }

    // Screen recordings that will be uploaded stop a little below the upload limit, like on Windows.
    var stopRecordingAtUploadLimit: Bool {
        get { uploadersConfig.uplaSettings.stopRecordingAtUploadLimit }
        set { uploadersConfig.uplaSettings.stopRecordingAtUploadLimit = newValue }
    }

    // Screen recording: 30 or 60 frames per second, the mouse pointer, and the sound apps play (no microphone).
    var recordingFramesPerSecond: Int {
        get {
            let rate = taskSettings.captureSettings.screenRecordFPS
            return AppSettings.recordingFrameRates.contains(rate) ? rate : 30
        }
        set { taskSettings.captureSettings.screenRecordFPS = newValue }
    }

    var recordingShowsCursor: Bool {
        get { taskSettings.captureSettings.screenRecordShowCursor }
        set { taskSettings.captureSettings.screenRecordShowCursor = newValue }
    }

    var recordingCapturesAudio: Bool {
        get { taskSettings.captureSettings.ffmpegOptions.audioSource == FFmpegOptions.systemAudioSource }
        set { taskSettings.captureSettings.ffmpegOptions.audioSource = newValue ? FFmpegOptions.systemAudioSource : "" }
    }

    // The question before the first upload is still to be asked (captures are uploaded automatically by default).
    var showUploadWarning: Bool {
        get { config.showUploadWarning }
        set { config.showUploadWarning = newValue }
    }

    // The folder for this month's screenshots, e.g. ~/Documents/UpLa/Screenshots/2026-10.
    var saveFolder: URL {
        config.screenshotsFolder(defaultParent: Self.defaultSaveFolder)
    }

    // The folder without the month subfolder: where a folder chooser starts.
    var saveParentFolder: URL {
        config.screenshotsParentFolder(defaultParent: Self.defaultSaveFolder)
    }

    var uploadOptions: UplaUploadOptions {
        uploadersConfig.uplaSettings.uploadOptions
    }

    private func setAfterCapture(_ flag: AfterCaptureTasks, _ on: Bool) {
        var task = taskSettings

        if on {
            task.afterCaptureJob.insert(flag)
        } else {
            task.afterCaptureJob.remove(flag)
        }

        taskSettings = task
    }

    // MARK: Hotkeys

    // Keeps HotkeysConfig.json in step with HotKeyCenter, which still stores its four shortcuts in UserDefaults until
    // the Hotkey settings window comes (plan §5, phase 1 item 9).
    func setHotkey(_ info: HotkeyInfo, for job: HotkeyType) {
        var updated = hotkeysConfig
        updated.setHotkey(info, for: job)
        hotkeysConfig = updated
    }
}

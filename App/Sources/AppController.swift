import AppKit
import Combine
import SwiftUI
import UplaKit

// Owns the app's services and performs the menu, hot key and window actions.
@MainActor
final class AppController {
    let settings: AppSettings
    let account: AccountStore
    let history: HistoryStore
    let notifier: Notifier
    let uploads: UploadManager
    let captureService: CaptureService
    let recorder: ScreenRecorder
    let hotKeys: HotKeyCenter
    let windows: WindowManager
    let settingsNavigation: SettingsNavigation
    private var statusItem: StatusItemController?
    // Set while UpLa waits for a recording to finish before it quits.
    private var quitReply: (@MainActor () -> Void)?
    private var hotKeyMirror: AnyCancellable?

    init() {
        settings = AppSettings()
        account = AccountStore(defaults: AppEnvironment.accountDefaults)
        history = HistoryStore()
        notifier = Notifier()
        uploads = UploadManager(settings: settings, account: account, history: history, notifier: notifier,
                                confirmFirstUpload: AppController.confirmFirstUpload)
        captureService = CaptureService()
        recorder = ScreenRecorder()
        hotKeys = HotKeyCenter()
        windows = WindowManager()
        settingsNavigation = SettingsNavigation()
    }

    func start() {
        TempFiles.cleanUp()

        let statusItem = StatusItemController(app: self)
        self.statusItem = statusItem
        uploads.onChange = { [weak statusItem] in
            statusItem?.update()
        }
        recorder.onChange = { [weak statusItem] in
            statusItem?.update()
        }
        recorder.onFinish = { [weak self] outcome in
            self?.handleRecording(outcome)
        }

        hotKeys.onPress = { [weak self] action in
            self?.handleHotKey(action)
        }
        hotKeys.start()

        // HotkeysConfig.json follows HotKeyCenter's shortcuts until HotKeyCenter reads that file itself.
        hotKeyMirror = hotKeys.$hotKeys.sink { [weak self] hotKeys in
            self?.mirror(hotKeys)
        }

        // The account is checked when its settings open (like UpLa for Windows), not at every launch: a launch at login
        // then sends nothing to upla.com.tr.

        // A menu bar app shows nothing when it starts, so the first launch opens the settings once.
        let launchedKey = "HasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: launchedKey) {
            UserDefaults.standard.set(true, forKey: launchedKey)
            showSettings(tab: .general)
        }
    }

    private func mirror(_ hotKeys: [HotKeyAction: HotKey]) {
        for action in HotKeyAction.allCases {
            guard let job = SettingsMigration.legacyHotkeyJobs.first(where: { $0.action == action.rawValue })?.job else {
                continue
            }

            let info = hotKeys[action].map { HotkeyInfo(keyCode: $0.keyCode, modifiers: $0.modifiers, key: $0.key) }
            settings.setHotkey(info ?? HotkeyInfo.none, for: job)
        }
    }

    // MARK: Capture and upload

    private func handleHotKey(_ action: HotKeyAction) {
        if let mode = action.captureMode {
            capture(mode)
        } else {
            toggleRecording()
        }
    }

    func capture(_ mode: CaptureMode) {
        // The selection of a recording is on the screen.
        guard recorder.state != .choosing else {
            return
        }

        Task {
            let fileURL = await self.captureService.capture(mode, onPermissionMissing: {
                self.showPermission()
            })

            if let fileURL {
                self.handleCapture(fileURL)
            }
        }
    }

    private func handleCapture(_ fileURL: URL) {
        if settings.copyImageAfterCapture && !Pasteboard.copyImage(at: fileURL) {
            appLog.error("Copying the screenshot to the clipboard failed")
        }

        var savedURL: URL?

        if settings.saveAfterCapture {
            do {
                savedURL = try TempFiles.save(fileURL, to: settings.saveFolder)
            } catch {
                notifier.prepare()
                notifier.post(title: String(localized: "The screenshot could not be saved"), body: error.localizedDescription,
                              isError: true)
            }
        }

        if settings.uploadAfterCapture {
            uploads.enqueue(fileURL, kind: .capture(savedCopy: savedURL))
            return
        }

        TempFiles.remove(fileURL)

        guard settings.showNotifications else {
            return
        }

        if let savedURL {
            notifier.prepare()
            notifier.post(title: String(localized: "Screenshot saved"), body: savedURL.path)
        } else if settings.copyImageAfterCapture {
            notifier.prepare()
            notifier.post(title: String(localized: "Screenshot copied to the clipboard"), body: "")
        }
    }

    // MARK: Screen recording

    // The recording shortcut: starts a region recording, or stops the running one.
    func toggleRecording() {
        switch recorder.state {
        case .idle:
            startRecording(.region)
        case .recording:
            recorder.stop()
        case .choosing, .starting, .finishing:
            break
        }
    }

    func startRecording(_ target: RecordingTarget) {
        // Not while an alert or open panel of UpLa waits for an answer: the region overlay would cover it.
        guard recorder.isIdle, !captureService.isCapturing, NSApp.modalWindow == nil else {
            return
        }

        guard captureService.checkAccess(onPermissionMissing: { self.showPermission() }) else {
            return
        }

        // As on Windows, the limit is fixed when the recording starts: only a recording that will be uploaded stops at
        // it, and the member limit needs a key.
        let limit = RecordingLimit(isMember: account.hasMemberKey, willUpload: settings.uploadAfterCapture,
                                   stopAtUploadLimit: settings.stopRecordingAtUploadLimit)
        let options = RecordingOptions(framesPerSecond: settings.recordingFramesPerSecond,
                                       showsCursor: settings.recordingShowsCursor,
                                       capturesAudio: settings.recordingCapturesAudio, limit: limit)
        recorder.start(target, options: options)
    }

    private func handleRecording(_ outcome: RecordingOutcome) {
        if quitReply != nil {
            // Quitting: a finished recording is only kept in the save folder (or the default one), because the
            // temporary folder is emptied next.
            if case .finished(let fileURL, _, _) = outcome {
                do {
                    _ = try TempFiles.keep(fileURL, in: settings.saveFolder)
                } catch {
                    appLog.error("Keeping the recording at quit failed: \(error.localizedDescription, privacy: .public)")
                }
            }

            replyToQuit()
            return
        }

        switch outcome {
        case .finished(let fileURL, let stoppedAtLimit, let limit):
            deliverRecording(fileURL, stoppedAtLimit: stoppedAtLimit, limit: limit)
        case .cancelled:
            break
        case .permissionMissing:
            showPermission()
        case .failed(let message):
            notifier.prepare()
            notifier.post(title: String(localized: "Screen recording failed"), body: message, isError: true)
        }
    }

    // After a recording, the after-capture actions of screenshots: upload and save to the folder. A recording that is
    // not uploaded always goes to the folder, because it cannot be taken again, and one above the upload limit is not
    // sent.
    private func deliverRecording(_ fileURL: URL, stoppedAtLimit: Bool, limit: RecordingLimit) {
        guard settings.uploadAfterCapture else {
            keepRecording(fileURL)
            return
        }

        // The account as it is now, because the upload uses it.
        let isMember = account.hasMemberKey
        let fileSize = TempFiles.fileSize(fileURL)

        guard RecordingLimit.canUpload(fileSize: fileSize, isMember: isMember) else {
            // The text of a file that is too large to upload, with its size and, for guests, the hint to sign in.
            let tooLarge = UplaText.uploadError(.fileTooLarge(size: fileSize, limit: Upla.maxUploadSize(isMember: isMember),
                                                              isMember: isMember),
                                                keyKind: isMember ? .signIn : .guest)
            notifier.prepare()

            do {
                let keptURL = try TempFiles.keep(fileURL, in: settings.saveFolder)
                let path = UploadManager.displayPath(keptURL)
                notifier.post(title: String(localized: "The screen recording was not uploaded"),
                              body: tooLarge + " " + String(localized: "The screen recording was saved to \(path)."), isError: true)
            } catch {
                notifier.post(title: String(localized: "The screen recording could not be saved"),
                              body: tooLarge + " " + error.localizedDescription, isError: true)
            }
            return
        }

        var savedURL: URL?

        if settings.saveAfterCapture {
            do {
                savedURL = try TempFiles.save(fileURL, to: settings.saveFolder)
            } catch {
                notifier.prepare()
                notifier.post(title: String(localized: "The screen recording could not be saved"), body: error.localizedDescription,
                              isError: true)
            }
        }

        if stoppedAtLimit {
            let limitText = limit.uploadLimitText
            notifier.prepare()
            notifier.post(title: String(localized: "Recording stopped at the upload limit (\(limitText))"),
                          body: String(localized: "The recording is being uploaded."))
        }

        uploads.enqueue(fileURL, kind: .capture(savedCopy: savedURL))
    }

    private func keepRecording(_ fileURL: URL) {
        do {
            let savedURL = try TempFiles.keep(fileURL, in: settings.saveFolder)

            if settings.showNotifications {
                notifier.prepare()
                notifier.post(title: String(localized: "Screen recording saved"), body: UploadManager.displayPath(savedURL))
            }
        } catch {
            notifier.prepare()
            notifier.post(title: String(localized: "The screen recording could not be saved"), body: error.localizedDescription,
                          isError: true)
        }
    }

    // Quitting during a recording: it is finished and kept in the save folder, not uploaded. UpLa quits after at most
    // 10 seconds even if the file is not closed by then.
    func finishRecordingBeforeQuit(reply: @escaping @MainActor () -> Void) {
        quitReply = reply
        recorder.stop()

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            self?.replyToQuit()
        }
    }

    private func replyToQuit() {
        guard let reply = quitReply else {
            return
        }

        quitReply = nil

        // Later, never from inside applicationShouldTerminate itself.
        Task { @MainActor in
            reply()
        }
    }

    func uploadFiles() {
        let panel = NSOpenPanel()
        panel.title = String(localized: "Upload to upla.com.tr")
        panel.prompt = String(localized: "Upload")
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = SupportedFiles.contentTypes
        NSApp.activate()

        guard panel.runModal() == .OK else {
            return
        }

        uploads.enqueue(panel.urls)
    }

    // Files copied in Finder first, then image data (written to a temporary PNG).
    func uploadFromClipboard() {
        let files = Pasteboard.fileURLs()

        if !files.isEmpty {
            uploads.enqueue(files)
            return
        }

        if let imageURL = Pasteboard.writeImageToTemporaryFile() {
            uploads.enqueue(imageURL, kind: .clipboardImage)
            return
        }

        notifier.prepare()
        notifier.post(title: String(localized: "Nothing to upload"),
                      body: String(localized: "There is no file or image on the clipboard."), isError: true)
    }

    // Asked by UploadManager once, before the first upload: true keeps uploading screenshots automatically. Same
    // question as UpLa for Windows (UplaStrings.FirstUploadText), pointed at this app's settings.
    static func confirmFirstUpload() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = String(localized: "Automatic upload to upla.com.tr")
        alert.informativeText = String(localized: "Your screenshots and screen recordings are uploaded to upla.com.tr automatically after capture, and a link that anyone who has it can open is created.\n\nKeep automatic upload on?\n\nIf you turn it off, screenshots and recordings are not uploaded and are saved to a folder instead; you can turn automatic upload back on in Settings › Capture.")
        alert.addButton(withTitle: String(localized: "Keep Uploading"))
        alert.addButton(withTitle: String(localized: "Turn Off Automatic Upload"))
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }

    // Screenshots still waiting for their upload go to the save folder; then the temporary folder, which also holds the
    // request body with the key, is emptied.
    func prepareForQuit() {
        uploads.keepPendingCaptures()
        TempFiles.cleanUp()
    }

    // MARK: Account

    func signOut() {
        let isManualKey = account.state == .manualKey
        let alert = NSAlert()
        alert.messageText = String(localized: "upla.com.tr Account")
        alert.informativeText = isManualKey
            ? String(localized: "Remove the API key entered by hand from this Mac? Later uploads are made as a guest.")
            : String(localized: "Sign out of your upla.com.tr account? This Mac's connection is removed from the server too; later uploads are made as a guest.")
        alert.addButton(withTitle: isManualKey ? String(localized: "Remove Key") : String(localized: "Sign Out"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        NSApp.activate()

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        Task {
            if let failure = await self.account.signOut() {
                self.reportSignOutFailure(failure)
            }
        }
    }

    private func reportSignOutFailure(_ result: UplaAccountResult) {
        var reason = UplaText.accountStatus(result.status, retryAfterSeconds: result.retryAfterSeconds)

        if reason.isEmpty {
            reason = UplaText.unexpectedResponseText
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "upla.com.tr Account")
        alert.informativeText = String(localized: "You are signed out on this Mac, but its connection could not be removed from upla.com.tr (\(reason)). Until it is removed it can still upload to your account. Open the \"Connected devices\" page?")
        alert.addButton(withTitle: String(localized: "Open Connected Devices"))
        alert.addButton(withTitle: String(localized: "Close"))
        NSApp.activate()

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(result.status == .notSupported ? Upla.apiKeySettingsURL : Upla.connectedDevicesURL)
        }
    }

    // MARK: Windows

    func showSettings(tab: SettingsTab? = nil) {
        if let tab {
            settingsNavigation.tab = tab
        }

        windows.show(.settings, title: String(localized: "UpLa Settings")) {
            SettingsView(app: self, settings: settings, account: account, hotKeys: hotKeys, navigation: settingsNavigation)
        }
    }

    func showSignIn() {
        let model = SignInModel(account: account)
        model.onFinish = { [weak self] in
            self?.windows.close(.signIn)
        }

        windows.show(.signIn, title: String(localized: "Sign in to upla.com.tr"), hidesContentFromCaptures: true) {
            SignInView(model: model)
        }
    }

    func showHistory() {
        windows.show(.history, title: String(localized: "Upload History"), resizable: true) {
            HistoryView(history: history)
        }
    }

    func showAbout() {
        windows.show(.about, title: String(localized: "About UpLa")) {
            AboutView()
        }
    }

    func showPermission() {
        windows.show(.permission, title: String(localized: "Screen Recording Permission")) {
            PermissionView(onClose: { [weak self] in
                self?.windows.close(.permission)
            })
        }
    }
}

// What MenuBuilder's items do. No menu is built from MenuSpec yet (the main window and the new menus come in the next
// steps of phase 1); the commands the Mac cannot run yet are hidden by MenuSpec and only logged here.
extension AppController: MenuActionHandler {
    func perform(_ command: MenuCommand) {
        switch command {
        case .captureFullscreen:
            capture(.fullScreen)
        case .captureRegion:
            capture(.region)
        case .screenRecording:
            toggleRecording()
        case .uploadFile:
            uploadFiles()
        case .uploadFromClipboard:
            uploadFromClipboard()
        case .applicationSettings:
            showSettings(tab: .general)
        case .hotkeySettings:
            showSettings(tab: .hotKeys)
        case .destinationSettings:
            showSettings(tab: .upla)
        case .history:
            showHistory()
        case .about:
            showAbout()
        case .exit:
            NSApp.terminate(nil)
        default:
            appLog.notice("The menu command \(command.rawValue, privacy: .public) is not available yet")
        }
    }

    func toggle(_ check: MenuCheck) {
        settings.taskSettings = MenuSpec.applying(check, to: settings.taskSettings)
    }

    func items(for menu: DynamicMenu) -> [NSMenuItem]? {
        nil
    }

    func title(for menu: DynamicMenu) -> String? {
        nil
    }
}

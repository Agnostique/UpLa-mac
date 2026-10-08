import AppKit
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
    let hotKeys: HotKeyCenter
    let windows: WindowManager
    let settingsNavigation: SettingsNavigation
    private var statusItem: StatusItemController?

    init() {
        settings = AppSettings()
        account = AccountStore(defaults: AppEnvironment.accountDefaults)
        history = HistoryStore()
        notifier = Notifier()
        uploads = UploadManager(settings: settings, account: account, history: history, notifier: notifier,
                                confirmFirstUpload: AppController.confirmFirstUpload)
        captureService = CaptureService()
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

        hotKeys.onPress = { [weak self] action in
            self?.capture(action.captureMode)
        }
        hotKeys.start()

        // The account is checked when its settings open (like UpLa for Windows), not at every launch: a launch at login
        // then sends nothing to upla.com.tr.

        // A menu bar app shows nothing when it starts, so the first launch opens the settings once.
        let launchedKey = "HasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: launchedKey) {
            UserDefaults.standard.set(true, forKey: launchedKey)
            showSettings(tab: .general)
        }
    }

    // MARK: Capture and upload

    func capture(_ mode: CaptureMode) {
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
        alert.informativeText = String(localized: "Your screenshots are uploaded to upla.com.tr automatically after capture, and a link that anyone who has it can open is created.\n\nKeep automatic upload on?\n\nIf you turn it off, screenshots are not uploaded and are saved to a folder instead; you can turn automatic upload back on in Settings › Capture.")
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

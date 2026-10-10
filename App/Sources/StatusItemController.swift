import AppKit
import UplaKit

// The menu bar item: the app's menu (rebuilt each time it opens), the recording time or the upload progress as the
// button title, and files dropped onto the icon.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate, NSWindowDelegate, NSDraggingDestination {
    private static let recentCount = 10

    private let app: AppController
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private let idleImage: NSImage?
    private let recordingImage: NSImage
    // The "Recording… 0:42, 12 MB" line of the open menu, updated while the menu is open.
    private weak var recordingStatusItem: NSMenuItem?

    init(app: AppController) {
        self.app = app
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        let image = NSImage(systemSymbolName: "arrow.up.circle", accessibilityDescription: "UpLa")
        image?.isTemplate = true
        idleImage = image
        recordingImage = StatusItemController.makeRecordingImage()
        super.init()

        if let button = statusItem.button {
            button.image = idleImage
            button.imagePosition = .imageLeading
            button.toolTip = "UpLa"
            // Digits of equal width, so the time and the percentage do not move the other menu bar items.
            button.font = NSFont.monospacedDigitSystemFont(ofSize: button.font?.pointSize ?? NSFont.systemFontSize, weight: .regular)
        }

        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        update()

        // The button's window exists once the item is in the menu bar.
        Task { @MainActor in
            self.setUpDropTarget()
        }
    }

    // A red dot and the elapsed time while recording, otherwise the icon and the upload progress.
    func update() {
        guard let button = statusItem.button else {
            return
        }

        let recorder = app.recorder

        if recorder.state == .recording || recorder.state == .finishing {
            setImage(recordingImage, on: button)
            button.title = recorder.elapsedSeconds.map { " " + RecordingTime.text(seconds: $0) } ?? ""
        } else {
            setImage(idleImage, on: button)

            if let progress = app.uploads.progress {
                button.title = " \(Int(progress * 100))%"
            } else {
                button.title = ""
            }
        }

        if recorder.state == .recording {
            recordingStatusItem?.title = recordingStatusText()
        }
    }

    private func setImage(_ image: NSImage?, on button: NSStatusBarButton) {
        if button.image !== image {
            button.image = image
        }
    }

    // Not a template image, so the dot stays red in the menu bar.
    private static func makeRecordingImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 14, height: 14), flipped: false) { rect in
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2)).fill()
            return true
        }
        image.isTemplate = false
        image.accessibilityDescription = String(localized: "Recording")
        return image
    }

    private func recordingStatusText() -> String {
        let recorder = app.recorder
        let elapsed = RecordingTime.text(seconds: recorder.elapsedSeconds ?? 0)
        // Guest limits are binary megabytes, member limits decimal, like the upload errors.
        let size = UplaText.megabytes(recorder.fileSize, binary: !(recorder.limit?.isMember ?? false))
        return String(localized: "Recording… \(elapsed), \(size)")
    }

    private func setUpDropTarget() {
        guard let window = statusItem.button?.window else {
            appLog.notice("The menu bar item has no window; dropping files on it is not available")
            return
        }

        // NSWindow passes the dragging destination calls on to its delegate.
        window.registerForDraggedTypes([.fileURL])
        window.delegate = self
    }

    // MARK: Menu

    nonisolated func menuNeedsUpdate(_ menu: NSMenu) {
        MainActor.assumeIsolated {
            self.rebuild(menu)
        }
    }

    private func rebuild(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(captureItem(.region))
        menu.addItem(captureItem(.window))
        menu.addItem(captureItem(.fullScreen))
        menu.addItem(.separator())
        addRecordingItems(to: menu)
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Upload File…"), #selector(uploadFile(_:))))
        menu.addItem(item(String(localized: "Upload from Clipboard"), #selector(uploadFromClipboard(_:))))

        if let progress = app.uploads.progress {
            // The percent sign stays out of the localized format strings.
            let percent = "\(Int(progress * 100))%"
            let waiting = String(app.uploads.queuedCount)
            let title = app.uploads.queuedCount > 0 ? String(localized: "Uploading… \(percent), \(waiting) waiting")
                : String(localized: "Uploading… \(percent)")
            let status = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            status.isEnabled = false
            menu.addItem(status)
            menu.addItem(item(String(localized: "Cancel Uploads"), #selector(cancelUploads(_:))))
        }

        menu.addItem(.separator())

        let recent = NSMenuItem(title: String(localized: "Recent Uploads"), action: nil, keyEquivalent: "")
        recent.submenu = recentMenu()
        menu.addItem(recent)

        let account = NSMenuItem(title: accountTitle(), action: nil, keyEquivalent: "")
        account.submenu = accountMenu()
        menu.addItem(account)

        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Settings…"), #selector(showSettings(_:)), key: ","))
        menu.addItem(item(String(localized: "About UpLa"), #selector(showAbout(_:))))
        menu.addItem(item(String(localized: "Quit UpLa"), #selector(quit(_:)), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func captureItem(_ action: HotKeyAction) -> NSMenuItem {
        let item = self.item(action.title, #selector(capture(_:)))
        item.representedObject = action.rawValue
        showHotKey(action, on: item)
        return item
    }

    // The global shortcut is shown for reference only (the Carbon hot key does the work).
    private func showHotKey(_ action: HotKeyAction, on item: NSMenuItem) {
        if let hotKey = app.hotKeys.hotKey(for: action), let key = hotKey.menuKeyEquivalent {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = hotKey.eventModifierFlags
        }
    }

    // Record… while idle; the state, Stop and Cancel while a recording is chosen, runs or is being finished.
    private func addRecordingItems(to menu: NSMenu) {
        func info(_ text: String) -> NSMenuItem {
            let infoItem = NSMenuItem(title: text, action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            menu.addItem(infoItem)
            return infoItem
        }

        switch app.recorder.state {
        case .idle:
            for target in RecordingTarget.allCases {
                let recordItem = item(target.title, #selector(record(_:)))
                recordItem.representedObject = target.rawValue

                // The recording shortcut starts a region recording.
                if target == .region {
                    showHotKey(.recording, on: recordItem)
                }

                menu.addItem(recordItem)
            }
        case .choosing:
            _ = info(String(localized: "Choose what to record…"))
            menu.addItem(item(String(localized: "Cancel Recording"), #selector(cancelRecording(_:))))
        case .starting:
            _ = info(String(localized: "Starting the recording…"))
            menu.addItem(item(String(localized: "Cancel Recording"), #selector(cancelRecording(_:))))
        case .recording:
            recordingStatusItem = info(recordingStatusText())
            let stopItem = item(String(localized: "Stop Recording"), #selector(stopRecording(_:)))
            showHotKey(.recording, on: stopItem)
            menu.addItem(stopItem)
            menu.addItem(item(String(localized: "Cancel Recording"), #selector(cancelRecording(_:))))
        case .finishing:
            _ = info(String(localized: "Finishing the recording…"))
        }
    }

    private func recentMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        let items = app.history.items.prefix(StatusItemController.recentCount)

        if items.isEmpty {
            let empty = NSMenuItem(title: String(localized: "No uploads yet"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        }

        for entry in items {
            let title = entry.awaitingModeration ? String(localized: "\(entry.fileName) (awaiting moderation)") : entry.fileName
            let recentItem = item(title, #selector(copyRecentLink(_:)))
            recentItem.representedObject = entry.url
            recentItem.toolTip = String(localized: "Copy link: \(entry.url)")
            submenu.addItem(recentItem)
        }

        submenu.addItem(.separator())
        submenu.addItem(item(String(localized: "Show History…"), #selector(showHistory(_:))))
        return submenu
    }

    private func accountTitle() -> String {
        let title = String(localized: "upla.com.tr Account")

        switch app.account.state {
        case .expired, .lost:
            return String(localized: "\(title) (sign in again)")
        case .guest, .signedIn, .manualKey:
            return title
        }
    }

    private func accountMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        let account = app.account

        func info(_ text: String) {
            let infoItem = NSMenuItem(title: text, action: nil, keyEquivalent: "")
            infoItem.isEnabled = false
            submenu.addItem(infoItem)
        }

        switch account.state {
        case .guest:
            submenu.addItem(item(String(localized: "Sign In…"), #selector(signIn(_:))))
            submenu.addItem(item(String(localized: "Create Account"), #selector(openSignUp(_:))))
        case .signedIn:
            info(String(localized: "Signed in as \(account.displayName)"))
            if Upla.profileURL(account.profileURL, site: AppEnvironment.baseURL) != nil {
                submenu.addItem(item(String(localized: "My Profile"), #selector(openProfile(_:))))
            }
            submenu.addItem(item(String(localized: "Connected Devices"), #selector(openConnectedDevices(_:))))
            submenu.addItem(.separator())
            submenu.addItem(item(String(localized: "Sign Out"), #selector(signOut(_:))))
        case .expired:
            info(String(localized: "Signed in as \(account.displayName)"))
            submenu.addItem(item(String(localized: "Sign In Again…"), #selector(signIn(_:))))
            submenu.addItem(.separator())
            submenu.addItem(item(String(localized: "Connected Devices"), #selector(openConnectedDevices(_:))))
            submenu.addItem(item(String(localized: "Sign Out"), #selector(signOut(_:))))
        case .lost:
            submenu.addItem(item(String(localized: "Sign In Again…"), #selector(signIn(_:))))
            submenu.addItem(item(String(localized: "Continue as Guest"), #selector(continueAsGuest(_:))))
            submenu.addItem(item(String(localized: "Connected Devices"), #selector(openConnectedDevices(_:))))
        case .manualKey:
            info(String(localized: "Using an API key entered by hand"))
            submenu.addItem(item(String(localized: "Sign In…"), #selector(signIn(_:))))
            submenu.addItem(item(String(localized: "Connected Devices"), #selector(openConnectedDevices(_:))))
            submenu.addItem(.separator())
            submenu.addItem(item(String(localized: "Remove Key…"), #selector(signOut(_:))))
        }

        // Store rules for apps that share user content: a way to report content that breaks the rules, as on Windows.
        submenu.addItem(.separator())
        submenu.addItem(item(String(localized: "Report Abuse"), #selector(openReportAbuse(_:))))

        return submenu
    }

    // MARK: Actions

    @objc private func capture(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = HotKeyAction(rawValue: raw)?.captureMode else {
            return
        }

        app.capture(mode)
    }

    @objc private func record(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let target = RecordingTarget(rawValue: raw) else {
            return
        }

        app.startRecording(target)
    }

    @objc private func stopRecording(_ sender: Any?) {
        app.recorder.stop()
    }

    @objc private func cancelRecording(_ sender: Any?) {
        app.recorder.cancel()
    }

    @objc private func uploadFile(_ sender: Any?) {
        app.uploadFiles()
    }

    @objc private func uploadFromClipboard(_ sender: Any?) {
        app.uploadFromClipboard()
    }

    @objc private func cancelUploads(_ sender: Any?) {
        app.uploads.cancelAll()
    }

    @objc private func copyRecentLink(_ sender: NSMenuItem) {
        if let link = sender.representedObject as? String {
            Pasteboard.copy(link: link)
        }
    }

    @objc private func showHistory(_ sender: Any?) {
        app.showHistory()
    }

    @objc private func signIn(_ sender: Any?) {
        app.showSignIn()
    }

    @objc private func signOut(_ sender: Any?) {
        app.signOut()
    }

    @objc private func continueAsGuest(_ sender: Any?) {
        app.account.clear()
    }

    @objc private func openSignUp(_ sender: Any?) {
        NSWorkspace.shared.open(Upla.signUpURL)
    }

    @objc private func openProfile(_ sender: Any?) {
        if let url = Upla.profileURL(app.account.profileURL, site: AppEnvironment.baseURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openReportAbuse(_ sender: Any?) {
        NSWorkspace.shared.open(Upla.reportAbuseURL)
    }

    @objc private func openConnectedDevices(_ sender: Any?) {
        NSWorkspace.shared.open(Upla.connectedDevicesURL)
    }

    @objc private func showSettings(_ sender: Any?) {
        app.showSettings()
    }

    @objc private func showAbout(_ sender: Any?) {
        app.showAbout()
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    // MARK: Dropping files on the menu bar icon

    nonisolated func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let accepts = MainActor.assumeIsolated { () -> Bool in
            !StatusItemController.fileURLs(from: sender).isEmpty
        }
        return accepts ? .copy : []
    }

    nonisolated func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    nonisolated func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        MainActor.assumeIsolated { () -> Bool in
            let urls = StatusItemController.fileURLs(from: sender)

            guard !urls.isEmpty else {
                return false
            }

            app.uploads.enqueue(urls)
            return true
        }
    }

    private static func fileURLs(from info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? []
        return objects.compactMap { $0 as? URL }.filter { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
        }
    }
}

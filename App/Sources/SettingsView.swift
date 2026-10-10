import AppKit
import Combine
import ServiceManagement
import SwiftUI
import UplaKit

enum SettingsTab: String, Hashable {
    case general
    case capture
    case recording
    case upla
    case hotKeys
    case account
}

// Lets the menu open the settings on a given tab.
@MainActor
final class SettingsNavigation: ObservableObject {
    @Published var tab: SettingsTab = .general
}

// Small secondary text under a setting.
struct Hint: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@MainActor
struct SettingsView: View {
    let app: AppController
    @ObservedObject var settings: AppSettings
    @ObservedObject var account: AccountStore
    @ObservedObject var hotKeys: HotKeyCenter
    @ObservedObject var navigation: SettingsNavigation

    var body: some View {
        TabView(selection: $navigation.tab) {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)
            CaptureSettingsView(settings: settings)
                .tabItem { Label("Capture (settings tab)", systemImage: "camera.viewfinder") }
                .tag(SettingsTab.capture)
            RecordingSettingsView(settings: settings)
                .tabItem { Label("Recording", systemImage: "record.circle") }
                .tag(SettingsTab.recording)
            UplaSettingsView(settings: settings, account: account)
                .tabItem {
                    Label {
                        Text(verbatim: "upla.com.tr")
                    } icon: {
                        Image(systemName: "icloud.and.arrow.up")
                    }
                }
                .tag(SettingsTab.upla)
            HotKeySettingsView(hotKeys: hotKeys)
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
                .tag(SettingsTab.hotKeys)
            AccountSettingsView(app: app, account: account)
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(SettingsTab.account)
        }
        .frame(width: 600, height: 540)
    }
}

@MainActor
struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var launchAtLogin = false
    @State private var loginItemMessage: String? = nil

    init(settings: AppSettings) {
        _settings = ObservedObject(wrappedValue: settings)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Open UpLa at login", isOn: $launchAtLogin)

                if let loginItemMessage {
                    Text(verbatim: loginItemMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Login Items Settings") {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                }
            }

            Section {
                Toggle("Show a notification when an upload finishes", isOn: $settings.showNotifications)
                Hint("Failed uploads are always reported. Click a notification to open the link.")
            }

            Section {
                Hint("UpLa lives in the menu bar. Drop files on its icon to upload them.")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            refreshLoginItem()
        }
        .onChange(of: launchAtLogin) { _, enabled in
            // The toggle also follows the system's state; only a change by the user registers or unregisters.
            if enabled != (SMAppService.mainApp.status == .enabled) {
                setLaunchAtLogin(enabled)
            }
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemMessage = nil
        } catch {
            appLog.error("Changing the login item failed: \(error.localizedDescription, privacy: .public)")
            loginItemMessage = String(localized: "Could not change the login item: \(error.localizedDescription)")
        }

        refreshLoginItem()
    }

    private func refreshLoginItem() {
        let status = SMAppService.mainApp.status
        launchAtLogin = status == .enabled

        if status == .requiresApproval {
            loginItemMessage = String(localized: "Allow UpLa in System Settings › General › Login Items.")
        }
    }
}

@MainActor
struct CaptureSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("After capture") {
                Toggle("Upload to upla.com.tr and copy the link", isOn: $settings.uploadAfterCapture)
                Toggle("Copy the image to the clipboard", isOn: $settings.copyImageAfterCapture)
                Toggle("Save to a folder", isOn: $settings.saveAfterCapture)

                LabeledContent("Folder:") {
                    HStack {
                        Text(verbatim: settings.saveFolder.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                        Button("Choose…") {
                            chooseFolder()
                        }
                        Button("Show in Finder") {
                            showFolder()
                        }
                    }
                }
                .disabled(!settings.saveAfterCapture)
            }

            Section {
                Hint("Region and window captures use the macOS selection: drag to select a region, press Space to switch between region and window, press Esc to cancel.")
            }
        }
        .formStyle(.grouped)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Choose")
        // The folder without the month subfolder, so choosing it unchanged does not pin the files to this month's one.
        panel.directoryURL = settings.saveParentFolder

        if panel.runModal() == .OK, let url = panel.url {
            settings.saveFolderPath = url.path
        }
    }

    private func showFolder() {
        let folder = settings.saveFolder

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            NSWorkspace.shared.open(folder)
        } catch {
            Notifier.showAlert(title: String(localized: "The folder could not be created"), message: error.localizedDescription)
        }
    }
}

@MainActor
struct RecordingSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Frames per second:", selection: $settings.recordingFramesPerSecond) {
                    ForEach(AppSettings.recordingFrameRates, id: \.self) { rate in
                        Text(verbatim: String(rate)).tag(rate)
                    }
                }
                Toggle("Show the mouse pointer", isOn: $settings.recordingShowsCursor)
                Toggle("Record system audio", isOn: $settings.recordingCapturesAudio)
                Hint("Sound played by apps is recorded; the microphone is not.")
            }

            Section {
                Toggle("Stop screen recordings that will be uploaded at the upload limit", isOn: $settings.stopRecordingAtUploadLimit)
                Hint("Guests can upload 20 MB, signed in members 100 MB. The recording stops a little before the limit, so it can still be uploaded.")
            }

            Section {
                Hint("Recordings are MP4 videos. After a recording the actions in the Capture tab apply (uploading, saving to the folder); a recording that is not uploaded is always saved to the folder.")
                Hint("Record Region: drag to select the area, or click to record the whole screen; Esc cancels. Stop the recording from the menu bar icon or with the shortcut.")
            }
        }
        .formStyle(.grouped)
    }
}

@MainActor
struct UplaSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var account: AccountStore

    var body: some View {
        Form {
            Section {
                Picker("Link to copy:", selection: $settings.linkType) {
                    ForEach(UplaLinkType.allCases, id: \.self) { linkType in
                        Text(verbatim: UplaText.linkType(linkType)).tag(linkType)
                    }
                }
            }

            Section {
                TextField("Album (link or ID):", text: $settings.album)
                Hint("Example: https://upla.com.tr/album/Holiday.AbCd (the album must belong to your account)")
                TextField("Tags (comma separated):", text: $settings.tags)
                Hint("Album and tags only work when you are signed in. Auto delete is applied when it is enabled on upla.com.tr.")
            }
            .disabled(!account.hasMemberKey)

            Section {
                Picker("Auto delete:", selection: $settings.expiration) {
                    Text("Never").tag("")
                    ForEach(Upla.expirationPresets, id: \.self) { preset in
                        Text(verbatim: UplaText.duration(preset)).tag(preset)
                    }
                }
                TextField("Category ID (0 = none):", value: $settings.categoryID, format: .number)
                TextField("Max width on server (px, 0 = off):", value: $settings.maxWidth, format: .number)
            }

            Section {
                Hint("Screen recordings (MP4, WEBM) are uploaded to upla.com.tr too. The limit is 20 MB for guests and 100 MB for signed in members.")
            }
        }
        .formStyle(.grouped)
        .onChange(of: settings.categoryID) { _, value in
            if value < 0 {
                settings.categoryID = 0
            }
        }
        .onChange(of: settings.maxWidth) { _, value in
            if value < 0 {
                settings.maxWidth = 0
            }
        }
    }
}

@MainActor
struct HotKeySettingsView: View {
    @ObservedObject var hotKeys: HotKeyCenter

    var body: some View {
        Form {
            Section {
                ForEach(HotKeyAction.allCases) { action in
                    HotKeyRow(action: action, hotKeys: hotKeys)
                }
            }

            Section {
                Hint("Click a shortcut, then press the new keys. Esc cancels, Delete removes the shortcut. A shortcut needs ⌘ or ⌃ and one more modifier key, like ⌥⇧⌘4; with F1–F20 one is enough. Shortcuts like ⌘C are left to the other apps.")
                Hint("macOS's own ⇧⌘3, ⇧⌘4 and ⇧⌘5 keep working; UpLa's defaults add ⌥.")
                Hint("The recording shortcut starts a region recording and stops a running one.")
                Button("Restore Defaults") {
                    hotKeys.restoreDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .onDisappear {
            hotKeys.stopRecording()
        }
    }
}

@MainActor
struct HotKeyRow: View {
    let action: HotKeyAction
    @ObservedObject var hotKeys: HotKeyCenter

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 4) {
                Button {
                    if hotKeys.recordingAction == action {
                        hotKeys.stopRecording()
                    } else {
                        hotKeys.startRecording(action)
                    }
                } label: {
                    if hotKeys.recordingAction == action {
                        Text("Press the new shortcut…")
                    } else if let hotKey = hotKeys.hotKey(for: action) {
                        Text(verbatim: hotKey.displayString)
                            .monospacedDigit()
                    } else {
                        Text("None (no shortcut)")
                    }
                }
                .frame(minWidth: 160, alignment: .trailing)

                if let status = hotKeys.failures[action] {
                    failureText(status)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } label: {
            Text(verbatim: action.title)
        }
    }

    // Only "already taken" blames another app; other refusals (e.g. a combination macOS no longer allows) say so.
    private func failureText(_ status: OSStatus) -> Text {
        if HotKeyCenter.isTakenElsewhere(status) {
            return Text("This shortcut could not be registered; another app may be using it.")
        }

        let code = String(status)
        return Text("macOS did not accept this shortcut (error \(code)). Choose another one.")
    }
}

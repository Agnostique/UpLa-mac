import AppKit
import Carbon
import Combine

// "UpLa" as a four character code; marks this app's hot keys in Carbon events.
private let hotKeySignature: OSType = 0x5570_4C61

enum HotKeyAction: String, CaseIterable, Identifiable {
    case fullScreen
    case region
    case window

    var id: String {
        rawValue
    }

    var carbonID: UInt32 {
        switch self {
        case .fullScreen:
            return 1
        case .region:
            return 2
        case .window:
            return 3
        }
    }

    var captureMode: CaptureMode {
        switch self {
        case .fullScreen:
            return .fullScreen
        case .region:
            return .region
        case .window:
            return .window
        }
    }

    var title: String {
        switch self {
        case .fullScreen:
            return String(localized: "Capture Full Screen")
        case .region:
            return String(localized: "Capture Region")
        case .window:
            return String(localized: "Capture Window")
        }
    }

    // ⌥⇧⌘3/4/5 sit next to macOS's own ⇧⌘3/4/5 without replacing them.
    var defaultHotKey: HotKey {
        let modifiers = UInt32(optionKey | shiftKey | cmdKey)

        switch self {
        case .fullScreen:
            return HotKey(keyCode: UInt32(kVK_ANSI_3), modifiers: modifiers, key: "3")
        case .region:
            return HotKey(keyCode: UInt32(kVK_ANSI_4), modifiers: modifiers, key: "4")
        case .window:
            return HotKey(keyCode: UInt32(kVK_ANSI_5), modifiers: modifiers, key: "5")
        }
    }
}

struct HotKey: Equatable {
    // Virtual key code (kVK_*), independent of the keyboard layout.
    var keyCode: UInt32
    // Carbon modifier flags (cmdKey, optionKey, controlKey, shiftKey).
    var modifiers: UInt32
    // The key's character without modifiers, for display.
    var key: String

    static let specialKeyNames: [UInt32: String] = [
        UInt32(kVK_Return): "↩", UInt32(kVK_Tab): "⇥", UInt32(kVK_Space): "Space", UInt32(kVK_Delete): "⌫",
        UInt32(kVK_Escape): "⎋", UInt32(kVK_ForwardDelete): "⌦", UInt32(kVK_Home): "↖", UInt32(kVK_End): "↘",
        UInt32(kVK_PageUp): "⇞", UInt32(kVK_PageDown): "⇟", UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_DownArrow): "↓", UInt32(kVK_UpArrow): "↑",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3", UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6", UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9", UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12", UInt32(kVK_F13): "F13", UInt32(kVK_F14): "F14",
        UInt32(kVK_F15): "F15", UInt32(kVK_F16): "F16", UInt32(kVK_F17): "F17", UInt32(kVK_F18): "F18",
        UInt32(kVK_F19): "F19", UInt32(kVK_F20): "F20"
    ]

    var displayString: String {
        var text = ""

        if modifiers & UInt32(controlKey) != 0 {
            text += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            text += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            text += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            text += "⌘"
        }

        return text + keyName
    }

    var keyName: String {
        if let name = HotKey.specialKeyNames[keyCode] {
            return name
        }

        return key.isEmpty ? "#\(keyCode)" : key.uppercased()
    }

    static let functionKeyCodes: Set<UInt32> = [
        UInt32(kVK_F1), UInt32(kVK_F2), UInt32(kVK_F3), UInt32(kVK_F4), UInt32(kVK_F5), UInt32(kVK_F6), UInt32(kVK_F7),
        UInt32(kVK_F8), UInt32(kVK_F9), UInt32(kVK_F10), UInt32(kVK_F11), UInt32(kVK_F12), UInt32(kVK_F13), UInt32(kVK_F14),
        UInt32(kVK_F15), UInt32(kVK_F16), UInt32(kVK_F17), UInt32(kVK_F18), UInt32(kVK_F19), UInt32(kVK_F20)
    ]

    // A global hot key is taken from every app while UpLa runs. It needs ⌘ or ⌃ (macOS 15 refuses ⌥ and ⌥⇧ alone, and
    // ⇧ alone would take typing) plus a second modifier, so app and text shortcuts like ⌘C, ⌘← or ⌃A keep working;
    // a function key is enough with ⌘ or ⌃ alone.
    static func isAllowed(keyCode: UInt32, flags: NSEvent.ModifierFlags) -> Bool {
        let modifiers: [NSEvent.ModifierFlags] = [.command, .option, .control, .shift]
        let count = modifiers.filter { flags.contains($0) }.count

        guard !flags.isDisjoint(with: [.command, .control]) else {
            return false
        }

        return count >= 2 || functionKeyCodes.contains(keyCode)
    }

    // Shown next to the menu items; only plain printable keys can be a menu key equivalent.
    var menuKeyEquivalent: String? {
        guard HotKey.specialKeyNames[keyCode] == nil, key.count == 1, let scalar = key.unicodeScalars.first,
              scalar.value > 32, scalar.value < 127 else {
            return nil
        }

        return key.lowercased()
    }

    var eventModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []

        if modifiers & UInt32(controlKey) != 0 {
            flags.insert(.control)
        }
        if modifiers & UInt32(optionKey) != 0 {
            flags.insert(.option)
        }
        if modifiers & UInt32(shiftKey) != 0 {
            flags.insert(.shift)
        }
        if modifiers & UInt32(cmdKey) != 0 {
            flags.insert(.command)
        }

        return flags
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0

        if flags.contains(.control) {
            result |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            result |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            result |= UInt32(shiftKey)
        }
        if flags.contains(.command) {
            result |= UInt32(cmdKey)
        }

        return result
    }
}

// Carbon calls this on the main thread for every registered hot key of the app.
private func hotKeyEventHandler(_ nextHandler: EventHandlerCallRef?, _ event: EventRef?,
                                _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event else {
        return OSStatus(eventNotHandledErr)
    }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                                   MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

    guard status == noErr, hotKeyID.signature == hotKeySignature else {
        return OSStatus(eventNotHandledErr)
    }

    let id = hotKeyID.id

    Task { @MainActor in
        HotKeyCenter.shared?.handlePress(id: id)
    }

    return noErr
}

// Global hot keys with Carbon's RegisterEventHotKey, which needs no Accessibility permission.
@MainActor
final class HotKeyCenter: ObservableObject {
    fileprivate static var shared: HotKeyCenter?

    @Published private(set) var hotKeys: [HotKeyAction: HotKey] = [:]
    // Shortcuts that could not be registered, with RegisterEventHotKey's status.
    @Published private(set) var failures: [HotKeyAction: OSStatus] = [:]
    @Published private(set) var recordingAction: HotKeyAction?

    var onPress: (@MainActor (HotKeyAction) -> Void)?

    private let defaults: UserDefaults
    private var registered: [HotKeyAction: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var monitor: Any?
    // The window the shortcut is recorded in; key presses in other windows pass through.
    private weak var recordingWindow: NSWindow?
    private var recordingObservers: [NSObjectProtocol] = []
    private var suspendCount = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded: [HotKeyAction: HotKey] = [:]

        for action in HotKeyAction.allCases {
            if let stored = defaults.dictionary(forKey: HotKeyCenter.defaultsKey(for: action)) {
                // An empty dictionary means the user removed the shortcut.
                if let keyCode = (stored["keyCode"] as? Int).flatMap({ UInt32(exactly: $0) }),
                   let modifiers = (stored["modifiers"] as? Int).flatMap({ UInt32(exactly: $0) }) {
                    loaded[action] = HotKey(keyCode: keyCode, modifiers: modifiers, key: stored["key"] as? String ?? "")
                }
            } else {
                loaded[action] = action.defaultHotKey
            }
        }

        hotKeys = loaded
    }

    func start() {
        HotKeyCenter.shared = self

        if eventHandler == nil {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            let status = InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, &eventType, nil, &eventHandler)

            if status != noErr {
                appLog.error("Installing the hot key handler failed: \(status, privacy: .public)")
            }
        }

        registerAll()
    }

    func hotKey(for action: HotKeyAction) -> HotKey? {
        hotKeys[action]
    }

    // RegisterEventHotKey's answer when the combination is already registered elsewhere.
    nonisolated static func isTakenElsewhere(_ status: OSStatus) -> Bool {
        status == OSStatus(eventHotKeyExistsErr)
    }

    // nil removes the shortcut. A shortcut that another action used moves to this one.
    func set(_ hotKey: HotKey?, for action: HotKeyAction) {
        if let hotKey {
            for other in HotKeyAction.allCases where other != action && hotKeys[other] == hotKey {
                hotKeys[other] = nil
                save(other)
            }
        }

        hotKeys[action] = hotKey
        save(action)
        registerAll()
    }

    func restoreDefaults() {
        for action in HotKeyAction.allCases {
            hotKeys[action] = action.defaultHotKey
            save(action)
        }

        registerAll()
    }

    // Hot keys are off while a shortcut is being recorded, so pressing the current one records it. Only key presses in
    // the window the recording started in (the settings) are taken; recording stops when that window loses focus or
    // closes, or UpLa is no longer the active app, so typing elsewhere never becomes a shortcut.
    func startRecording(_ action: HotKeyAction) {
        stopRecording()
        recordingAction = action
        recordingWindow = NSApp.keyWindow
            ?? NSApp.windows.first { $0.identifier?.rawValue == WindowID.settings.rawValue }
        suspend()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = UInt32(event.keyCode)
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let characters = event.characters(byApplyingModifiers: []) ?? ""
            let window = event.window
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let self, window != nil, window === self.recordingWindow else {
                    return false
                }

                return self.record(keyCode: keyCode, flags: flags, characters: characters)
            }
            return handled ? nil : event
        }

        let center = NotificationCenter.default
        let stop: @Sendable (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated {
                self?.stopRecording()
            }
        }

        recordingObservers = [
            center.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main, using: stop),
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: recordingWindow, queue: .main, using: stop),
            center.addObserver(forName: NSWindow.willCloseNotification, object: recordingWindow, queue: .main, using: stop)
        ]
    }

    func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = nil

        for observer in recordingObservers {
            NotificationCenter.default.removeObserver(observer)
        }

        recordingObservers = []
        recordingWindow = nil

        if recordingAction != nil {
            recordingAction = nil
            resume()
        }
    }

    func suspend() {
        suspendCount += 1

        if suspendCount == 1 {
            unregisterAll()
        }
    }

    func resume() {
        guard suspendCount > 0 else {
            return
        }

        suspendCount -= 1

        if suspendCount == 0 {
            registerAll()
        }
    }

    fileprivate func handlePress(id: UInt32) {
        guard suspendCount == 0, let action = HotKeyAction.allCases.first(where: { $0.carbonID == id }) else {
            return
        }

        onPress?(action)
    }

    // Esc cancels, Delete removes the shortcut; anything else must pass HotKey.isAllowed, or it beeps and recording goes on.
    private func record(keyCode: UInt32, flags: NSEvent.ModifierFlags, characters: String) -> Bool {
        guard let action = recordingAction else {
            return false
        }

        let hasModifier = !flags.isDisjoint(with: [.command, .option, .control])

        if !hasModifier && keyCode == UInt32(kVK_Escape) {
            stopRecording()
            return true
        }

        if !hasModifier && (keyCode == UInt32(kVK_Delete) || keyCode == UInt32(kVK_ForwardDelete)) {
            stopRecording()
            set(nil, for: action)
            return true
        }

        guard HotKey.isAllowed(keyCode: keyCode, flags: flags) else {
            NSSound.beep()
            return true
        }

        let hotKey = HotKey(keyCode: keyCode, modifiers: HotKey.carbonModifiers(from: flags), key: characters)
        stopRecording()
        set(hotKey, for: action)
        return true
    }

    private func registerAll() {
        unregisterAll()

        guard suspendCount == 0 else {
            return
        }

        var failed: [HotKeyAction: OSStatus] = [:]

        for action in HotKeyAction.allCases {
            guard let hotKey = hotKeys[action] else {
                continue
            }

            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: hotKeySignature, id: action.carbonID)
            let status = RegisterEventHotKey(hotKey.keyCode, hotKey.modifiers, id, GetApplicationEventTarget(), 0, &ref)

            if status == noErr, let ref {
                registered[action] = ref
            } else {
                failed[action] = status == noErr ? OSStatus(eventInternalErr) : status
                appLog.error("Registering the \(action.rawValue, privacy: .public) hot key failed: \(status, privacy: .public)")
            }
        }

        failures = failed
    }

    private func unregisterAll() {
        for ref in registered.values {
            UnregisterEventHotKey(ref)
        }

        registered.removeAll()
    }

    private func save(_ action: HotKeyAction) {
        let value: [String: Any]

        if let hotKey = hotKeys[action] {
            value = ["keyCode": Int(hotKey.keyCode), "modifiers": Int(hotKey.modifiers), "key": hotKey.key]
        } else {
            value = [:]
        }

        defaults.set(value, forKey: HotKeyCenter.defaultsKey(for: action))
    }

    private static func defaultsKey(for action: HotKeyAction) -> String {
        "HotKey." + action.rawValue
    }
}

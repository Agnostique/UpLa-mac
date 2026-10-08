import AppKit

// AppKit entry point (no SwiftUI App lifecycle): a menu bar app whose windows host SwiftUI views.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    // NSApplication keeps only a weak reference to its delegate.
    withExtendedLifetime(delegate) {
        app.run()
    }
}

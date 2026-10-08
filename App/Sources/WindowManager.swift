import AppKit
import SwiftUI

enum WindowID: String {
    case settings
    case signIn
    case history
    case about
    case permission
}

// Keeps the app's windows (SwiftUI views in NSWindows) alive while they are open and brings them to the front;
// a menu bar app has to activate itself first.
@MainActor
final class WindowManager: NSObject, NSWindowDelegate {
    private var windows: [WindowID: NSWindow] = [:]

    func isOpen(_ id: WindowID) -> Bool {
        windows[id] != nil
    }

    func show<Content: View>(_ id: WindowID, title: String, resizable: Bool = false, hidesContentFromCaptures: Bool = false,
                             content: () -> Content) {
        if let window = windows[id] {
            bringToFront(window)
            return
        }

        let controller = NSHostingController(rootView: content())
        controller.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: controller)
        window.title = title
        window.styleMask = resizable ? [.titled, .closable, .miniaturizable, .resizable] : [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.identifier = NSUserInterfaceItemIdentifier(id.rawValue)

        if hidesContentFromCaptures {
            // Screenshots taken while this window is open (by this app or another) do not show its content.
            window.sharingType = .none
        }

        windows[id] = window
        window.center()
        bringToFront(window)
    }

    func close(_ id: WindowID) {
        windows[id]?.close()
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        MainActor.assumeIsolated {
            guard let window = notification.object as? NSWindow else {
                return
            }

            for (id, open) in windows where open === window {
                windows[id] = nil
            }
        }
    }
}

import AppKit
import Combine
import CoreGraphics
import SwiftUI

// Shown instead of capturing while the Screen Recording permission is missing.
@MainActor
struct PermissionView: View {
    let onClose: @MainActor () -> Void
    @State private var granted = CGPreflightScreenCaptureAccess()

    init(onClose: @escaping @MainActor () -> Void) {
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 8) {
                    Text("UpLa needs the Screen Recording permission")
                        .font(.headline)
                    Text("Screenshots are taken with the macOS screencapture tool, which needs this permission. UpLa does not record anything until you capture.")
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Turn on UpLa in System Settings › Privacy & Security › Screen & System Audio Recording (Screen Recording on macOS 14), then quit and reopen UpLa.")
                        .fixedSize(horizontal: false, vertical: true)

                    if granted {
                        Text("The permission is on. If capturing still fails, quit and reopen UpLa.")
                            .foregroundStyle(.green)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack {
                Button("Quit UpLa") {
                    NSApp.terminate(nil)
                }

                Spacer()

                Button("Close") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)

                Button("Open System Settings") {
                    NSWorkspace.shared.open(AppEnvironment.screenRecordingSettingsURL)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            granted = CGPreflightScreenCaptureAccess()
        }
    }
}

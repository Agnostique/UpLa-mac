import AppKit
import CoreGraphics
import Foundation

enum CaptureMode {
    case region
    case window
    case fullScreen

    // Options of /usr/sbin/screencapture: -i interactive, -W start in window mode, -o no window shadow,
    // -x no sound, -m main display only, -t file type.
    var arguments: [String] {
        switch self {
        case .region:
            return ["-i", "-x", "-t", "png"]
        case .window:
            return ["-i", "-W", "-o", "-x", "-t", "png"]
        case .fullScreen:
            return ["-x", "-m", "-t", "png"]
        }
    }
}

// Screenshots through the system's screencapture tool, which gives the native selection UI on every display.
@MainActor
final class CaptureService {
    private static let toolURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

    private(set) var isCapturing = false
    private var requestedAccess = false

    var hasScreenCaptureAccess: Bool {
        CGPreflightScreenCaptureAccess()
    }

    // The Screen Recording permission, which screenshots and screen recordings both need. Without it macOS is asked
    // once and onPermissionMissing is called (it shows the permission window).
    func checkAccess(onPermissionMissing: @MainActor () -> Void) -> Bool {
        guard CGPreflightScreenCaptureAccess() else {
            if !requestedAccess {
                requestedAccess = true
                // Adds UpLa to the Screen Recording list in System Settings (macOS asks only once).
                _ = CGRequestScreenCaptureAccess()
            }
            onPermissionMissing()
            return false
        }

        return true
    }

    // Returns the PNG file, or nil when the user cancelled (Esc writes no file), the permission is missing
    // (onPermissionMissing is called instead) or another capture is still running.
    func capture(_ mode: CaptureMode, onPermissionMissing: @MainActor () -> Void) async -> URL? {
        guard !isCapturing else {
            return nil
        }

        guard checkAccess(onPermissionMissing: onPermissionMissing) else {
            return nil
        }

        let fileURL: URL

        do {
            fileURL = try TempFiles.newFileURL(extension: "png")
        } catch {
            appLog.error("Creating the temporary folder failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        isCapturing = true
        defer { isCapturing = false }

        let status = await Self.run(arguments: mode.arguments + [fileURL.path])
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let size = (attributes?[.size] as? NSNumber)?.int64Value ?? 0

        guard size > 0 else {
            // No file or an empty one: the user cancelled. Nothing to report.
            TempFiles.remove(fileURL)
            if status != 0 {
                appLog.notice("screencapture ended with status \(status, privacy: .public)")
            }
            return nil
        }

        return fileURL
    }

    // Runs the tool without blocking the main thread.
    private static func run(arguments: [String]) async -> Int32 {
        let process = Process()
        process.executableURL = toolURL
        process.arguments = arguments

        return await withCheckedContinuation { (continuation: CheckedContinuation<Int32, Never>) in
            process.terminationHandler = { finished in
                continuation.resume(returning: finished.terminationStatus)
            }

            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                appLog.error("Starting screencapture failed: \(error.localizedDescription, privacy: .public)")
                continuation.resume(returning: -1)
            }
        }
    }
}

import AppKit
import Foundation
import UniformTypeIdentifiers
import UplaKit

// Temporary capture files ("UpLa_yyyy-MM-dd_HH-mm-ss.png", recordings as .mp4) and copies into the save folder.
enum TempFiles {
    static var directory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("UpLa", isDirectory: true)
    }

    static func timestampName(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return "UpLa_" + formatter.string(from: date)
    }

    // A new, not yet existing file in the temporary folder.
    static func newFileURL(extension ext: String) throws -> URL {
        let folder = directory
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return uniqueURL(in: folder, baseName: timestampName(), extension: ext)
    }

    static func uniqueURL(in folder: URL, baseName: String, extension ext: String) -> URL {
        var url = folder.appendingPathComponent(baseName).appendingPathExtension(ext)
        var number = 2

        while FileManager.default.fileExists(atPath: url.path) {
            url = folder.appendingPathComponent("\(baseName)_\(number)").appendingPathExtension(ext)
            number += 1
        }

        return url
    }

    static func isTemporary(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path + "/")
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // 0 when the file is missing.
    static func fileSize(_ url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.int64Value ?? 0
    }

    // Captures and upload request bodies (which hold the key); emptied at launch, for leftovers of a crash, and at quit.
    static func cleanUp() {
        try? FileManager.default.removeItem(at: directory)
    }

    // Copies a capture into the chosen folder (created when needed) and returns the copy.
    static func save(_ fileURL: URL, to folder: URL) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = uniqueURL(in: folder, baseName: fileURL.deletingPathExtension().lastPathComponent,
                                    extension: fileURL.pathExtension)
        try FileManager.default.copyItem(at: fileURL, to: destination)
        return destination
    }

    // Moves a capture that was not uploaded into the chosen folder and returns its new place.
    static func move(_ fileURL: URL, to folder: URL) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = uniqueURL(in: folder, baseName: fileURL.deletingPathExtension().lastPathComponent,
                                    extension: fileURL.pathExtension)
        try FileManager.default.moveItem(at: fileURL, to: destination)
        return destination
    }

    // Like move, for a capture that is not uploaded and would otherwise be lost when the temporary folder is emptied:
    // when the chosen folder fails (e.g. its volume is not mounted), the default save folder is used.
    @MainActor
    static func keep(_ fileURL: URL, in folder: URL) throws -> URL {
        do {
            return try move(fileURL, to: folder)
        } catch {
            let fallback = AppSettings.defaultSaveFolder

            guard fallback.standardizedFileURL.path != folder.standardizedFileURL.path else {
                throw error
            }

            appLog.error("Saving to the chosen folder failed, using the default one: \(error.localizedDescription, privacy: .public)")
            return try move(fileURL, to: fallback)
        }
    }
}

enum Pasteboard {
    static func copy(link: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(link, forType: .string)
    }

    @discardableResult
    static func copyImage(at fileURL: URL) -> Bool {
        guard let image = NSImage(contentsOf: fileURL) else {
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    // Files on the clipboard (copied in Finder).
    static func fileURLs() -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: options) ?? []
        return objects.compactMap { ($0 as? URL) ?? ($0 as? NSURL)?.absoluteURL }.filter { $0.isFileURL }
    }

    // An image on the clipboard (e.g. copied from a browser), written as a PNG to the temporary folder.
    static func writeImageToTemporaryFile() -> URL? {
        let pasteboard = NSPasteboard.general
        var pngData = pasteboard.data(forType: .png)

        if pngData == nil, let image = NSImage(pasteboard: pasteboard), let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff) {
            pngData = bitmap.representation(using: .png, properties: [:])
        }

        guard let data = pngData, !data.isEmpty, let url = try? TempFiles.newFileURL(extension: "png") else {
            return nil
        }

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            appLog.error("Writing the clipboard image failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

enum SupportedFiles {
    // The file types upla.com.tr accepts, for open panels.
    static var contentTypes: [UTType] {
        (Upla.imageExtensions + Upla.videoExtensions).compactMap { UTType(filenameExtension: $0) }
    }

    static func isSupported(_ url: URL) -> Bool {
        Upla.isSupportedExtension(url.pathExtension)
    }
}

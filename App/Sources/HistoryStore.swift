import Combine
import Foundation

struct HistoryItem: Codable, Identifiable, Equatable {
    var id: UUID
    var date: Date
    var fileName: String
    var url: String
    var thumbnailURL: String?
    // Lets anyone delete the file: kept only in this file, never logged or put into notifications.
    var deletionURL: String?
    var isVideo: Bool
    var awaitingModeration: Bool

    init(id: UUID = UUID(), date: Date = Date(), fileName: String, url: String, thumbnailURL: String?,
         deletionURL: String?, isVideo: Bool, awaitingModeration: Bool) {
        self.id = id
        self.date = date
        self.fileName = fileName
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.deletionURL = deletionURL
        self.isVideo = isVideo
        self.awaitingModeration = awaitingModeration
    }
}

// Upload history in ~/Library/Application Support/UpLa/history.json, newest first.
@MainActor
final class HistoryStore: ObservableObject {
    static let maxItems = 500

    @Published private(set) var items: [HistoryItem] = []

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        fileURL = support.appendingPathComponent("UpLa", isDirectory: true).appendingPathComponent("history.json")
        load()
    }

    func add(_ item: HistoryItem) {
        items.insert(item, at: 0)

        if items.count > Self.maxItems {
            items.removeLast(items.count - Self.maxItems)
        }

        save()
    }

    func remove(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func removeAll() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let loaded = try decoder.decode([HistoryItem].self, from: data)
            items = Array(loaded.sorted { $0.date > $1.date }.prefix(Self.maxItems))
        } catch {
            // A damaged file is kept aside instead of being overwritten by the next upload.
            appLog.error("The history could not be read: \(error.localizedDescription, privacy: .public)")
            let backup = fileURL.deletingPathExtension().appendingPathExtension("damaged.json")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
            // The deletion links let anyone delete the files, so only this user may read the history.
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            appLog.error("The history could not be saved: \(error.localizedDescription, privacy: .public)")
        }
    }
}

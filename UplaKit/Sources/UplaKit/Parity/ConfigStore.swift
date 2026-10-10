import Foundation

/// What reading one settings file found.
public enum ConfigLoadResult<Value> {
    case loaded(Value)
    case missing
    /// The file could not be read as settings. It was moved aside to `preservedAt` (nil when even that failed), and
    /// `backup` is the previous version from the ".bak" file, when that one is readable.
    case damaged(preservedAt: URL?, backup: Value?)
}

/// Reads and writes the settings files in one folder (the app passes ~/Library/Application Support/UpLa). Like
/// SettingsBase on Windows, each save keeps the previous file as "<name>.bak", and a file that cannot be read is
/// kept for the user instead of being overwritten.
public struct ConfigStore: Sendable {
    public static let applicationConfigFileName = "ApplicationConfig.json"
    public static let hotkeysConfigFileName = "HotkeysConfig.json"
    public static let uploadersConfigFileName = "UploadersConfig.json"

    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func fileURL(_ fileName: String) -> URL {
        directory.appendingPathComponent(fileName, isDirectory: false)
    }

    public func load<Value: Decodable>(_ type: Value.Type, from fileName: String) -> ConfigLoadResult<Value> {
        let url = fileURL(fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return .missing
        }

        if let value = read(type, at: url) {
            return .loaded(value)
        }

        let preserved = preserveUnreadable(url)
        return .damaged(preservedAt: preserved, backup: read(type, at: backupURL(fileName)))
    }

    /// Writes the file atomically, readable by the user only (recent tasks contain delete links), after keeping the
    /// current file as the backup.
    public func save<Value: Encodable>(_ value: Value, to fileName: String) throws {
        let url = fileURL(fileName)
        let data = try ConfigJSON.encoder().encode(value)
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)

        if manager.fileExists(atPath: url.path) {
            let backup = backupURL(fileName)
            try? manager.removeItem(at: backup)
            try? manager.copyItem(at: url, to: backup)
            try? manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backup.path)
        }

        // The temporary file is created empty with 0600 before the data goes in (Data.write(.atomic) would create it
        // with the umask's permissions first), then renamed over the file in one step.
        let temporary = directory.appendingPathComponent(".\(fileName).\(UUID().uuidString).tmp", isDirectory: false)

        guard manager.createFile(atPath: temporary.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: temporary.path])
        }

        do {
            let handle = try FileHandle(forWritingTo: temporary)
            defer { try? handle.close() }
            try handle.write(contentsOf: data)
            try handle.synchronize()

            guard rename(temporary.path, url.path) == 0 else {
                throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
            }
        } catch {
            try? manager.removeItem(at: temporary)
            throw error
        }
    }

    /// Loads the three files. A missing file, or a damaged one without a readable backup, is made from the 0.1
    /// settings (on the first launch of this version that is all of them) and saved, so the next launch reads it.
    /// `legacy` is only called when something has to be migrated.
    public func loadAll(legacy: () -> [String: Any], legacyDefaultSaveFolder: String) -> (configs: ConfigSet, migrated: Bool) {
        var migration: ConfigSet?
        var migrated = false

        func migrate() -> ConfigSet {
            if let migration {
                return migration
            }

            let result = SettingsMigration.migrate(legacy: legacy(), legacyDefaultSaveFolder: legacyDefaultSaveFolder)
            migration = result
            return result
        }

        func resolve<Value: Codable>(_ type: Value.Type, _ fileName: String, _ fromMigration: (ConfigSet) -> Value) -> Value {
            let value: Value

            switch load(type, from: fileName) {
            case .loaded(let loaded):
                return loaded
            case .missing:
                value = fromMigration(migrate())
                migrated = true
            case .damaged(_, let backup):
                if let backup {
                    value = backup
                } else {
                    value = fromMigration(migrate())
                    migrated = true
                }
            }

            try? save(value, to: fileName)
            return value
        }

        let application = resolve(ApplicationConfig.self, Self.applicationConfigFileName) { $0.application }
        let hotkeys = resolve(HotkeysConfig.self, Self.hotkeysConfigFileName) { $0.hotkeys }
        let uploaders = resolve(UploadersConfig.self, Self.uploadersConfigFileName) { $0.uploaders }
        return (ConfigSet(application: application, hotkeys: hotkeys, uploaders: uploaders), migrated)
    }

    func backupURL(_ fileName: String) -> URL {
        fileURL(fileName + ".bak")
    }

    private func read<Value: Decodable>(_ type: Value.Type, at url: URL) -> Value? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? ConfigJSON.decoder().decode(type, from: data)
    }

    // "ApplicationConfig.json" → "ApplicationConfig-unreadable-1760097600.json", next to it.
    private func preserveUnreadable(_ url: URL) -> URL? {
        let stamp = Int(Date().timeIntervalSince1970)
        let name = url.deletingPathExtension().lastPathComponent + "-unreadable-\(stamp)"
        let destination = url.deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(url.pathExtension)

        do {
            try FileManager.default.moveItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}

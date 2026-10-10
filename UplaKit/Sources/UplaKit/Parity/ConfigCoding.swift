import Foundation

// Shared pieces of the settings files (ApplicationConfig.json, HotkeysConfig.json, UploadersConfig.json). They use the
// field names and value spellings of UpLa for Windows (Newtonsoft with StringEnumConverter), so the two apps' files
// read alike and a setting is found under the same name in both.

extension KeyedDecodingContainer {
    // A missing, null or unreadable value falls back to the default, like SettingsBase on Windows, so one bad or
    // renamed field never resets the whole file.
    func value<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }
}

/// An enum stored by its Windows name ("ThumbnailView"); read without regard to case, like Newtonsoft.
public protocol WindowsNamedEnum: RawRepresentable, CaseIterable, Codable, Sendable where RawValue == String {
    /// A requirement, so a type can also accept older names (HotkeyType reads "ExitUpLa").
    init?(windowsName name: String)
}

extension WindowsNamedEnum {
    public init?(windowsName name: String) {
        let wanted = name.trimmingCharacters(in: .whitespaces).lowercased()

        guard let match = Self.allCases.first(where: { $0.rawValue.lowercased() == wanted }) else {
            return nil
        }

        self = match
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)

        guard let value = Self(windowsName: name) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown \(Self.self) value \(name)")
        }

        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// A [Flags] enum of Windows: an OptionSet with the same bits, stored as the names Newtonsoft writes
/// ("CopyImageToClipboard, SaveImageToFile, UploadImageToHost"; "None" for no flag).
public protocol WindowsFlags: OptionSet, Sendable where RawValue == Int, Element == Self {
    /// Every flag with its Windows name, in the order of the Windows enum (ascending bits).
    static var windowsNames: [(name: String, flag: Self)] { get }
}

extension WindowsFlags {
    /// The flags one by one, in Windows order.
    public var flags: [Self] {
        Self.windowsNames.map(\.flag).filter { contains($0) }
    }

    public var windowsString: String {
        let names = Self.windowsNames.filter { contains($0.flag) }.map(\.name)
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    /// Unknown names are ignored, like UplaLegacyEnumConverter on Windows, which reads flags that a newer or older
    /// version removed without dropping the rest. Returns nil only when nothing in the text is a known name.
    public init?(windowsString text: String) {
        var value = Self()
        var known = 0

        for part in text.split(separator: ",") {
            let name = part.trimmingCharacters(in: .whitespaces).lowercased()

            if name == "none" {
                known += 1
            } else if let match = Self.windowsNames.first(where: { $0.name.lowercased() == name }) {
                value.insert(match.flag)
                known += 1
            }
        }

        guard known > 0 else {
            return nil
        }

        self = value
    }

    // Newtonsoft also reads a plain number; bits that are not a known flag are dropped.
    static func decodeWindowsFlags(from decoder: Decoder) throws -> Self {
        let container = try decoder.singleValueContainer()

        if let number = try? container.decode(Int.self) {
            let known = windowsNames.reduce(Self()) { $0.union($1.flag) }
            return Self(rawValue: number).intersection(known)
        }

        let text = try container.decode(String.self)

        guard let value = Self(windowsString: text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "No known \(Self.self) in \(text)")
        }

        return value
    }

    func encodeWindowsFlags(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(windowsString)
    }
}

enum ConfigJSON {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFormatter(fractional: true).string(from: date))
        }
        return encoder
    }

    // Newtonsoft writes dates as ISO 8601 with up to seven fractional digits and an offset
    // ("2026-10-10T14:03:12.1234567+03:00"); seconds without a fraction are read too.
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)

            if let date = parseDate(text) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unreadable date \(text)")
        }
        return decoder
    }

    static func parseDate(_ text: String) -> Date? {
        if let date = isoFormatter(fractional: false).date(from: text) ?? isoFormatter(fractional: true).date(from: text) {
            return date
        }

        // ISO8601DateFormatter takes at most three fractional digits; .NET writes seven.
        guard let dot = text.firstIndex(of: "."), text[text.index(after: dot)...].first?.isNumber == true else {
            return nil
        }

        let digitsEnd = text[text.index(after: dot)...].firstIndex { !$0.isNumber } ?? text.endIndex
        let digits = text[text.index(after: dot)..<digitsEnd].prefix(3)
        return isoFormatter(fractional: true).date(from: String(text[..<dot]) + "." + digits + text[digitsEnd...])
    }

    // A new formatter each time: ISO8601DateFormatter is not Sendable, and settings are read rarely.
    private static func isoFormatter(fractional: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractional ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return formatter
    }
}

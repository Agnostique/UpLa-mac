import Foundation
import IOKit

// A name for this Mac that says nothing about its owner ("MacBook Pro"), for the website's "Connected devices" page.
// The Computer Name in System Settings is not used: macOS builds it from the owner's name.
enum MacModel {
    static var name: String {
        productName() ?? familyName(hardwareModel())
    }

    // Apple silicon Macs keep their marketing name in the device tree, e.g. "MacBook Pro (14-inch, 2021)"; only the part
    // before " (" is used.
    private static func productName() -> String? {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product")

        guard entry != 0 else {
            return nil
        }

        defer { IOObjectRelease(entry) }

        guard let property = IORegistryEntryCreateCFProperty(entry, "product-name" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue(), let data = property as? Data else {
            return nil
        }

        let text = String(decoding: data.prefix { $0 != 0 }, as: UTF8.self)
        let name = (text.components(separatedBy: " (").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    // The model identifier, e.g. "MacBookPro16,1" on Intel or "Mac14,2" on Apple silicon.
    private static func hardwareModel() -> String {
        var size = 0

        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else {
            return ""
        }

        var bytes = [CChar](repeating: 0, count: size)

        guard sysctlbyname("hw.model", &bytes, &size, nil, 0) == 0 else {
            return ""
        }

        return String(decoding: bytes.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    // Intel identifiers start with the family; newer ones ("Mac14,2") do not, so they become "Mac".
    static func familyName(_ model: String) -> String {
        let families: [(prefix: String, name: String)] = [
            ("MacBookPro", "MacBook Pro"), ("MacBookAir", "MacBook Air"), ("MacBook", "MacBook"), ("iMacPro", "iMac Pro"),
            ("iMac", "iMac"), ("Macmini", "Mac mini"), ("MacPro", "Mac Pro")
        ]

        return families.first { model.hasPrefix($0.prefix) }?.name ?? "Mac"
    }
}

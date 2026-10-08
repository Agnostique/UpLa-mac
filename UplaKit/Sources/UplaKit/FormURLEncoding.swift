import Foundation

/// application/x-www-form-urlencoded bodies, encoded like the Windows app's .NET classes so PHP reads the same values.
enum FormURLEncoding {
    /// Like .NET's Uri.EscapeDataString: everything except A-Z a-z 0-9 - _ . ~ is percent-encoded as UTF-8.
    static func escapeDataString(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)

        for byte in text.utf8 {
            switch byte {
            case UInt8(ascii: "A")...UInt8(ascii: "Z"), UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "0")...UInt8(ascii: "9"),
                 UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "."), UInt8(ascii: "~"):
                result.unicodeScalars.append(Unicode.Scalar(byte))
            default:
                result += "%" + hexDigits[Int(byte >> 4)] + hexDigits[Int(byte & 0x0F)]
            }
        }

        return result
    }

    /// Like .NET's FormUrlEncodedContent: name=value pairs joined with '&', spaces sent as '+'.
    static func encode(_ fields: [(name: String, value: String)]) -> String {
        fields.map { field in
            formEscape(field.name) + "=" + formEscape(field.value)
        }.joined(separator: "&")
    }

    private static func formEscape(_ text: String) -> String {
        escapeDataString(text).replacingOccurrences(of: "%20", with: "+")
    }

    private static let hexDigits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
}

import Foundation

/// Reads values from JSONSerialization output the way the Windows app reads them with Newtonsoft.Json:
/// numbers and booleans can stand in for text, and the boolean `is_approved` may come as true, 1 or "1".
enum JSONFields {
    /// The top-level object, or nil when the text is no JSON object (HTML pages, empty bodies, arrays).
    static func object(from data: Data?) -> [String: Any]? {
        guard let data, !data.isEmpty else {
            return nil
        }

        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// The value at a path of object keys, or nil when a step is missing or not an object.
    static func value(_ object: [String: Any]?, _ path: String...) -> Any? {
        var current: Any? = object

        for name in path {
            guard let dictionary = current as? [String: Any] else {
                return nil
            }

            current = dictionary[name]
        }

        return current
    }

    /// Text of a JSON string, number or boolean; nil for missing values, null, objects and arrays.
    static func text(_ value: Any?) -> String? {
        if let string = value as? String {
            return string
        }

        guard let number = value as? NSNumber else {
            return nil
        }

        if isBoolean(number) {
            return number.boolValue ? "True" : "False"
        }

        if isFloatingPoint(number) {
            let double = number.doubleValue
            // .NET prints whole doubles without a fraction ("100"), which then still parse as integers.
            if double.rounded() == double, abs(double) < 1e15 {
                return String(Int64(double))
            }

            return String(double)
        }

        return number.stringValue
    }

    /// Integer value of a JSON number or numeric text, like .NET's int.TryParse (surrounding spaces and a sign allowed).
    static func int(_ value: Any?) -> Int? {
        guard let text = text(value) else {
            return nil
        }

        return Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)).map(Int.init)
    }

    /// true/false, 1/0 or "1"/"0"/"true"/"false"; nil for anything else (the Windows app's GetBool).
    static func bool(_ value: Any?) -> Bool? {
        if let number = value as? NSNumber {
            if isBoolean(number) {
                return number.boolValue
            }

            return isFloatingPoint(number) ? nil : number.int64Value != 0
        }

        guard let text = value as? String else {
            return nil
        }

        if text == "1" || text.caseInsensitiveCompare("true") == .orderedSame {
            return true
        }

        if text == "0" || text.caseInsensitiveCompare("false") == .orderedSame {
            return false
        }

        return nil
    }

    // JSONSerialization returns booleans as NSNumbers of type "c" (CFBoolean) on macOS and Linux.
    private static func isBoolean(_ number: NSNumber) -> Bool {
        String(cString: number.objCType) == "c"
    }

    private static func isFloatingPoint(_ number: NSNumber) -> Bool {
        let type = String(cString: number.objCType)
        return type == "d" || type == "f"
    }
}

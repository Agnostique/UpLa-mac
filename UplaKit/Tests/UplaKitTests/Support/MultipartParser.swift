import Foundation

/// Reads a multipart/form-data body back into its parts, as a server would.
struct MultipartPart {
    /// Raw header lines of the part.
    let headers: [String]
    let name: String?
    let fileName: String?
    let contentType: String?
    let body: Data

    var text: String {
        String(decoding: body, as: UTF8.self)
    }
}

enum MultipartParser {
    /// The boundary of a "multipart/form-data; boundary=..." content type.
    static func boundary(fromContentType contentType: String?) -> String? {
        guard let contentType, let range = contentType.range(of: "boundary=") else {
            return nil
        }

        return String(contentType[range.upperBound...]).trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
    }

    /// nil when the body does not start with the boundary or does not end with the closing boundary.
    static func parse(_ body: Data, boundary: String) -> [MultipartPart]? {
        let delimiter = Data("--\(boundary)".utf8)
        let separator = Data("\r\n--\(boundary)".utf8)
        let crlf = Data("\r\n".utf8)
        let headerEnd = Data("\r\n\r\n".utf8)

        guard body.starts(with: delimiter), body.suffix(delimiter.count + 4) == delimiter + Data("--\r\n".utf8) else {
            return nil
        }

        var parts: [MultipartPart] = []
        var index = body.index(body.startIndex, offsetBy: delimiter.count)

        while true {
            // After a delimiter: "--" ends the body, CRLF starts a part.
            if body[index...].starts(with: Data("--".utf8)) {
                return parts
            }

            guard body[index...].starts(with: crlf) else {
                return nil
            }

            index = body.index(index, offsetBy: 2)

            guard let headersRange = body.range(of: headerEnd, in: index..<body.endIndex),
                  let next = body.range(of: separator, in: headersRange.upperBound..<body.endIndex) else {
                return nil
            }

            let headerLines = String(decoding: body[index..<headersRange.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
            let disposition = headerLines.first { $0.lowercased().hasPrefix("content-disposition:") } ?? ""
            let contentType = headerLines.first { $0.lowercased().hasPrefix("content-type:") }
                .map { String($0.dropFirst("content-type:".count)).trimmingCharacters(in: .whitespaces) }

            parts.append(MultipartPart(
                headers: headerLines,
                name: parameter("name", in: disposition),
                fileName: parameter("filename", in: disposition),
                contentType: contentType,
                body: Data(body[headersRange.upperBound..<next.lowerBound])))

            index = next.upperBound
        }
    }

    /// The quoted value of `name="..."` in a Content-Disposition line.
    static func parameter(_ name: String, in line: String) -> String? {
        guard let start = line.range(of: "; \(name)=\"") else {
            return nil
        }

        let rest = line[start.upperBound...]

        guard let end = rest.firstIndex(of: "\"") else {
            return nil
        }

        return String(rest[..<end])
    }
}

import Foundation

/// Writes a multipart/form-data request body to a file, laid out like ShareX's RequestHelpers: the text fields first,
/// then the file part. The file is copied in chunks, so a 100 MB video never sits in memory.
public enum MultipartBody {
    public static func makeBoundary() -> String {
        String(repeating: "-", count: 20) + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    public static func contentType(boundary: String) -> String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// Writes the whole body to `outputURL` (replaced if it exists; readable only by the user, as it holds the key).
    /// A field value is written as is; quotes and line breaks in names and the file name are percent-encoded like
    /// browsers do. On failure the output file is removed.
    public static func write(fields: [(name: String, value: String)], fileFieldName: String, fileURL: URL, fileName: String, mimeType: String, boundary: String, to outputURL: URL) throws {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: outputURL)

        guard fileManager.createFile(atPath: outputURL.path, contents: nil, attributes: [.posixPermissions: 0o600]),
              let output = OutputStream(url: outputURL, append: false) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: outputURL.path])
        }

        var completed = false

        defer {
            if !completed {
                try? fileManager.removeItem(at: outputURL)
            }
        }

        output.open()
        defer { output.close() }

        if output.streamStatus == .error {
            throw output.streamError ?? CocoaError(.fileWriteUnknown)
        }

        var head = ""

        for field in fields {
            head += "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(escape(field.name))\"\r\n\r\n\(field.value)\r\n"
        }

        head += "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(escape(fileFieldName))\"; filename=\"\(escape(fileName))\"\r\n"
        head += "Content-Type: \(mimeType)\r\n\r\n"
        try writeAll(Array(head.utf8), count: head.utf8.count, to: output)
        try copyFile(fileURL, to: output)
        let tail = "\r\n--\(boundary)--\r\n"
        try writeAll(Array(tail.utf8), count: tail.utf8.count, to: output)
        completed = true
    }

    /// Percent-encodes '"', CR and LF, which would end the quoted name or the header line (the HTML form encoding).
    static func escape(_ name: String) -> String {
        name.replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
    }

    private static func copyFile(_ fileURL: URL, to output: OutputStream) throws {
        guard let input = InputStream(url: fileURL) else {
            throw UplaUploadError.fileUnreadable
        }

        input.open()
        defer { input.close() }

        if input.streamStatus == .error {
            throw UplaUploadError.fileUnreadable
        }

        var buffer = [UInt8](repeating: 0, count: 256 * 1024)

        while true {
            let count = input.read(&buffer, maxLength: buffer.count)

            if count < 0 {
                throw UplaUploadError.fileUnreadable
            }

            if count == 0 {
                return
            }

            try writeAll(buffer, count: count, to: output)
        }
    }

    private static func writeAll(_ bytes: [UInt8], count: Int, to output: OutputStream) throws {
        var offset = 0

        while offset < count {
            let written = bytes.withUnsafeBufferPointer { buffer in
                output.write(buffer.baseAddress! + offset, maxLength: count - offset)
            }

            if written <= 0 {
                throw output.streamError ?? CocoaError(.fileWriteUnknown)
            }

            offset += written
        }
    }
}

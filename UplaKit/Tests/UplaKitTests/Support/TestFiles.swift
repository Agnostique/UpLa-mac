import Foundation
import XCTest

/// Temporary files for one test; removed in tearDown.
final class TestDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("UplaKitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }

    func file(_ name: String, _ data: Data) throws -> URL {
        let fileURL = url.appendingPathComponent(name)
        try data.write(to: fileURL)
        return fileURL
    }

    /// A file of the given size without writing its bytes (sparse where the file system allows it).
    func file(_ name: String, size: Int64) throws -> URL {
        let fileURL = url.appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.createFile(atPath: fileURL.path, contents: nil))
        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.truncate(atOffset: UInt64(size))
        try handle.close()
        return fileURL
    }

    var contents: [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: url.path)) ?? []).sorted()
    }
}

/// Image files built in code, so the tests need no fixtures.
enum TestImages {
    /// A valid uncompressed RGB PNG. `seed` changes the pixels, so two uploads are never duplicates.
    static func png(width: Int, height: Int, seed: UInt64 = 1) -> Data {
        var raw = [UInt8]()
        raw.reserveCapacity((width * 3 + 1) * height)
        var state = seed &* 0x9E37_79B9_7F4A_7C15 &+ 1

        for _ in 0..<height {
            raw.append(0)

            for _ in 0..<width {
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                raw.append(UInt8(truncatingIfNeeded: state >> 24))
                raw.append(UInt8(truncatingIfNeeded: state >> 32))
                raw.append(UInt8(truncatingIfNeeded: state >> 40))
            }
        }

        var header = Data()
        header.append(bigEndian32(UInt32(width)))
        header.append(bigEndian32(UInt32(height)))
        header.append(contentsOf: [8, 2, 0, 0, 0])

        var png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        png.append(chunk("IHDR", header))
        png.append(chunk("IDAT", zlibStored(raw)))
        png.append(chunk("IEND", Data()))
        return png
    }

    /// JPEG header up to the frame: SOI, APP0, a large APP1 (EXIF-like) segment, then SOF (baseline or progressive).
    static func jpegHeader(width: Int, height: Int, progressive: Bool = false, exifSize: Int = 70_000) -> Data {
        var data = Data([0xFF, 0xD8])
        data.append(segment(0xE0, Data("JFIF\0".utf8) + Data([1, 1, 0, 0, 1, 0, 1, 0, 0])))
        // Segments are at most 65,535 bytes; a big EXIF block is split like real files with several APP segments.
        var remaining = exifSize

        while remaining > 0 {
            let size = min(remaining, 65_000)
            data.append(segment(0xE1, Data(repeating: 0x45, count: size)))
            remaining -= size
        }

        data.append(Data([0xFF, 0xFF]))
        data.append(segment(0xDB, Data(repeating: 1, count: 65)))
        let frame = Data([8, UInt8(height >> 8), UInt8(height & 0xFF), UInt8(width >> 8), UInt8(width & 0xFF), 3, 1, 0x22, 0, 2, 0x11, 1, 3, 0x11, 1])
        data.append(segment(progressive ? 0xC2 : 0xC0, frame))
        data.append(Data([0xFF, 0xDA, 0x00, 0x08, 1, 1, 0, 0, 0x3F, 0]))
        return data
    }

    static func gifHeader(width: Int, height: Int) -> Data {
        Data("GIF89a".utf8) + Data([UInt8(width & 0xFF), UInt8(width >> 8), UInt8(height & 0xFF), UInt8(height >> 8), 0, 0, 0])
    }

    static func bmpHeader(width: Int32, height: Int32, coreHeader: Bool = false) -> Data {
        var data = Data("BM".utf8)
        data.append(littleEndian32(UInt32(70)))
        data.append(Data([0, 0, 0, 0]))
        data.append(littleEndian32(UInt32(54)))

        if coreHeader {
            data.append(littleEndian32(12))
            data.append(Data([UInt8(width & 0xFF), UInt8((width >> 8) & 0xFF), UInt8(height & 0xFF), UInt8((height >> 8) & 0xFF), 1, 0, 24, 0]))
        } else {
            data.append(littleEndian32(40))
            data.append(littleEndian32(UInt32(bitPattern: width)))
            data.append(littleEndian32(UInt32(bitPattern: height)))
            data.append(Data([1, 0, 24, 0]))
            data.append(Data(repeating: 0, count: 24))
        }

        return data
    }

    static func webpLossy(width: Int, height: Int) -> Data {
        var payload = Data([0x50, 0x01, 0x00, 0x9D, 0x01, 0x2A])
        payload.append(Data([UInt8(width & 0xFF), UInt8((width >> 8) & 0x3F), UInt8(height & 0xFF), UInt8((height >> 8) & 0x3F)]))
        payload.append(Data(repeating: 0, count: 8))
        return riff("VP8 ", payload)
    }

    static func webpLossless(width: Int, height: Int) -> Data {
        let w = UInt32(width - 1)
        let h = UInt32(height - 1)
        let bits = w | (h << 14)
        var payload = Data([0x2F])
        payload.append(littleEndian32(bits))
        payload.append(Data(repeating: 0, count: 8))
        return riff("VP8L", payload)
    }

    static func webpExtended(width: Int, height: Int) -> Data {
        let w = UInt32(width - 1)
        let h = UInt32(height - 1)
        var payload = Data([0x10, 0, 0, 0])
        payload.append(Data([UInt8(w & 0xFF), UInt8((w >> 8) & 0xFF), UInt8((w >> 16) & 0xFF)]))
        payload.append(Data([UInt8(h & 0xFF), UInt8((h >> 8) & 0xFF), UInt8((h >> 16) & 0xFF)]))
        return riff("VP8X", payload)
    }

    private static func riff(_ chunkType: String, _ payload: Data) -> Data {
        var data = Data("RIFF".utf8)
        data.append(littleEndian32(UInt32(4 + 8 + payload.count)))
        data.append(Data("WEBP".utf8))
        data.append(Data(chunkType.utf8))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(payload)
        return data
    }

    private static func segment(_ marker: UInt8, _ payload: Data) -> Data {
        let length = payload.count + 2
        return Data([0xFF, marker, UInt8(length >> 8), UInt8(length & 0xFF)]) + payload
    }

    private static func chunk(_ type: String, _ payload: Data) -> Data {
        var data = bigEndian32(UInt32(payload.count))
        let typeAndPayload = Data(type.utf8) + payload
        data.append(typeAndPayload)
        data.append(bigEndian32(crc32(typeAndPayload)))
        return data
    }

    /// zlib stream with stored (uncompressed) deflate blocks.
    private static func zlibStored(_ bytes: [UInt8]) -> Data {
        var data = Data([0x78, 0x01])
        var offset = 0

        repeat {
            let count = min(65_535, bytes.count - offset)
            let isFinal = offset + count >= bytes.count
            data.append(isFinal ? 1 : 0)
            data.append(UInt8(count & 0xFF))
            data.append(UInt8(count >> 8))
            let inverted = ~UInt16(count)
            data.append(UInt8(inverted & 0xFF))
            data.append(UInt8(inverted >> 8))
            data.append(contentsOf: bytes[offset..<(offset + count)])
            offset += count
        } while offset < bytes.count

        data.append(bigEndian32(adler32(bytes)))
        return data
    }

    private static func adler32(_ bytes: [UInt8]) -> UInt32 {
        var a: UInt32 = 1
        var b: UInt32 = 0

        for byte in bytes {
            a = (a + UInt32(byte)) % 65_521
            b = (b + a) % 65_521
        }

        return b << 16 | a
    }

    private static let crcTable: [UInt32] = (0..<256).map { index -> UInt32 in
        var value = UInt32(index)

        for _ in 0..<8 {
            value = value & 1 == 1 ? 0xEDB8_8320 ^ (value >> 1) : value >> 1
        }

        return value
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF

        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }

        return crc ^ 0xFFFF_FFFF
    }

    private static func bigEndian32(_ value: UInt32) -> Data {
        Data([UInt8(value >> 24), UInt8((value >> 16) & 0xFF), UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
    }

    private static func littleEndian32(_ value: UInt32) -> Data {
        Data([UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF), UInt8((value >> 16) & 0xFF), UInt8(value >> 24)])
    }
}

/// Values a @Sendable callback reports from another queue.
final class Recorder<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [Value] = []

    var values: [Value] {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func append(_ value: Value) {
        lock.lock()
        stored.append(value)
        lock.unlock()
    }
}

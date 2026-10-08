import Foundation

/// Reads the pixel width of an image from its header (PNG, JPEG, GIF, BMP, WebP) without decoding it, so the
/// resize width is only sent for images that are wider (Chevereto fails the upload with error 610 otherwise).
/// Pure Swift: no ImageIO, so it works the same on macOS and in the Linux tests.
enum ImageWidth {
    static func read(from fileURL: URL) -> Int? {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return nil
        }

        defer { try? handle.close() }

        guard let header = try? handle.read(upToCount: 32), header.count >= 10 else {
            return nil
        }

        let bytes = [UInt8](header)

        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            // The IHDR chunk comes first: width is the big-endian UInt32 at offset 16.
            guard bytes.count >= 24, bytes[12...15].elementsEqual("IHDR".utf8) else {
                return nil
            }

            return positive(Int(bigEndian32(bytes, 16)))
        }

        if bytes.starts(with: "GIF87a".utf8) || bytes.starts(with: "GIF89a".utf8) {
            // Logical screen width, little-endian.
            return positive(Int(bytes[6]) | Int(bytes[7]) << 8)
        }

        if bytes.starts(with: "BM".utf8) {
            return bmpWidth(bytes)
        }

        if bytes.starts(with: "RIFF".utf8), bytes.count >= 30, bytes[8...11].elementsEqual("WEBP".utf8) {
            return webpWidth(bytes)
        }

        if bytes.starts(with: [0xFF, 0xD8]) {
            return jpegWidth(handle)
        }

        return nil
    }

    private static func bmpWidth(_ bytes: [UInt8]) -> Int? {
        guard bytes.count >= 26 else {
            return nil
        }

        let headerSize = littleEndian32(bytes, 14)

        if headerSize == 12 {
            // BITMAPCOREHEADER: 16-bit width.
            return positive(Int(bytes[18]) | Int(bytes[19]) << 8)
        }

        // BITMAPINFOHEADER and later: signed 32-bit width.
        return positive(Int(Int32(bitPattern: littleEndian32(bytes, 18))))
    }

    private static func webpWidth(_ bytes: [UInt8]) -> Int? {
        let chunk = String(decoding: bytes[12...15], as: UTF8.self)

        switch chunk {
        case "VP8 ":
            // Lossy: frame tag (3 bytes), start code 9D 01 2A, then the 14-bit width.
            guard bytes[23] == 0x9D, bytes[24] == 0x01, bytes[25] == 0x2A else {
                return nil
            }

            return positive((Int(bytes[26]) | Int(bytes[27]) << 8) & 0x3FFF)
        case "VP8L":
            // Lossless: signature 0x2F, then width - 1 in the low 14 bits.
            guard bytes[20] == 0x2F else {
                return nil
            }

            return 1 + (Int(bytes[21]) | (Int(bytes[22]) & 0x3F) << 8)
        case "VP8X":
            // Extended: canvas width - 1, 24-bit little-endian.
            return 1 + (Int(bytes[24]) | Int(bytes[25]) << 8 | Int(bytes[26]) << 16)
        default:
            return nil
        }
    }

    /// Walks the JPEG segments up to the frame header; large EXIF or ICC segments are skipped, not read.
    private static func jpegWidth(_ handle: FileHandle) -> Int? {
        var offset: UInt64 = 2

        // A real JPEG reaches its frame header after a few segments; the limit only stops endless loops on bad files.
        for _ in 0..<1000 {
            guard (try? handle.seek(toOffset: offset)) != nil,
                  let data = try? handle.read(upToCount: 4), data.count == 4 else {
                return nil
            }

            let marker = [UInt8](data)

            guard marker[0] == 0xFF else {
                return nil
            }

            let type = marker[1]

            // Fill bytes before a marker.
            if type == 0xFF {
                offset += 1
                continue
            }

            // Markers without a length: TEM, RST0-7.
            if type == 0x01 || (0xD0...0xD7).contains(type) {
                offset += 2
                continue
            }

            // Start of scan or end of image before any frame header.
            if type == 0xDA || type == 0xD9 {
                return nil
            }

            let length = UInt64(marker[2]) << 8 | UInt64(marker[3])

            guard length >= 2 else {
                return nil
            }

            // SOF0-SOF15 except DHT (C4), JPG (C8) and DAC (CC): precision (1), height (2), width (2).
            if (0xC0...0xCF).contains(type), type != 0xC4, type != 0xC8, type != 0xCC {
                guard let frame = try? handle.read(upToCount: 5), frame.count == 5 else {
                    return nil
                }

                let bytes = [UInt8](frame)
                return positive(Int(bytes[3]) << 8 | Int(bytes[4]))
            }

            offset += 2 + length
        }

        return nil
    }

    private static func bigEndian32(_ bytes: [UInt8], _ index: Int) -> UInt32 {
        UInt32(bytes[index]) << 24 | UInt32(bytes[index + 1]) << 16 | UInt32(bytes[index + 2]) << 8 | UInt32(bytes[index + 3])
    }

    private static func littleEndian32(_ bytes: [UInt8], _ index: Int) -> UInt32 {
        UInt32(bytes[index]) | UInt32(bytes[index + 1]) << 8 | UInt32(bytes[index + 2]) << 16 | UInt32(bytes[index + 3]) << 24
    }

    private static func positive(_ value: Int) -> Int? {
        value > 0 ? value : nil
    }
}

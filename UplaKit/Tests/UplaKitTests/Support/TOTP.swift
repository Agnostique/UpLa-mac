import Foundation

/// RFC 6238 TOTP (SHA-1, 30 s, 6 digits) for the two-step sign-in test, in pure Swift: CryptoKit is not on Linux
/// and the package has no dependencies.
enum TOTP {
    static func code(base32Secret: String, time: Date = Date(), digits: Int = 6, period: TimeInterval = 30) -> String? {
        guard let key = base32Decode(base32Secret) else {
            return nil
        }

        let counter = UInt64(max(0, time.timeIntervalSince1970) / period)
        let message = (0..<8).map { UInt8(truncatingIfNeeded: counter >> (56 - 8 * $0)) }
        let hash = hmacSHA1(key: key, message: message)
        let offset = Int(hash[19] & 0x0F)
        let binary = UInt32(hash[offset] & 0x7F) << 24 | UInt32(hash[offset + 1]) << 16 | UInt32(hash[offset + 2]) << 8 | UInt32(hash[offset + 3])
        var modulus: UInt32 = 1

        for _ in 0..<digits {
            modulus *= 10
        }

        let value = String(binary % modulus)
        return String(repeating: "0", count: max(0, digits - value.count)) + value
    }

    /// RFC 4648 base32; spaces and padding are ignored, other characters fail.
    static func base32Decode(_ text: String) -> [UInt8]? {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8)
        var bytes: [UInt8] = []
        var buffer: UInt32 = 0
        var bits = 0

        for character in text.uppercased().utf8 where character != UInt8(ascii: "=") && character != UInt8(ascii: " ") {
            guard let value = alphabet.firstIndex(of: character) else {
                return nil
            }

            buffer = (buffer << 5) | UInt32(value)
            bits += 5

            if bits >= 8 {
                bytes.append(UInt8(truncatingIfNeeded: buffer >> UInt32(bits - 8)))
                bits -= 8
            }
        }

        return bytes
    }

    static func hmacSHA1(key: [UInt8], message: [UInt8]) -> [UInt8] {
        let blockSize = 64
        var blockKey = key.count > blockSize ? sha1(key) : key
        blockKey += [UInt8](repeating: 0, count: blockSize - blockKey.count)
        let inner = sha1(blockKey.map { $0 ^ 0x36 } + message)
        return sha1(blockKey.map { $0 ^ 0x5C } + inner)
    }

    static func sha1(_ message: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476, 0xC3D2_E1F0]
        var data = message
        let bitLength = UInt64(message.count) * 8
        data.append(0x80)

        while data.count % 64 != 56 {
            data.append(0)
        }

        data += (0..<8).map { UInt8(truncatingIfNeeded: bitLength >> (56 - 8 * UInt64($0))) }

        for chunk in stride(from: 0, to: data.count, by: 64) {
            var w = [UInt32](repeating: 0, count: 80)

            for i in 0..<16 {
                let j = chunk + i * 4
                w[i] = UInt32(data[j]) << 24 | UInt32(data[j + 1]) << 16 | UInt32(data[j + 2]) << 8 | UInt32(data[j + 3])
            }

            for i in 16..<80 {
                w[i] = rotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)
            }

            var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4]

            for i in 0..<80 {
                let f: UInt32
                let k: UInt32

                switch i {
                case 0..<20:
                    f = (b & c) | (~b & d)
                    k = 0x5A82_7999
                case 20..<40:
                    f = b ^ c ^ d
                    k = 0x6ED9_EBA1
                case 40..<60:
                    f = (b & c) | (b & d) | (c & d)
                    k = 0x8F1B_BCDC
                default:
                    f = b ^ c ^ d
                    k = 0xCA62_C1D6
                }

                let temp = rotateLeft(a, 5) &+ f &+ e &+ k &+ w[i]
                e = d
                d = c
                c = rotateLeft(b, 30)
                b = a
                a = temp
            }

            h[0] = h[0] &+ a
            h[1] = h[1] &+ b
            h[2] = h[2] &+ c
            h[3] = h[3] &+ d
            h[4] = h[4] &+ e
        }

        return h.flatMap { value in (0..<4).map { UInt8(truncatingIfNeeded: value >> (24 - 8 * UInt32($0))) } }
    }

    private static func rotateLeft(_ value: UInt32, _ count: UInt32) -> UInt32 {
        (value << count) | (value >> (32 - count))
    }
}

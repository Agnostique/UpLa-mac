import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

#if canImport(Glibc)
private let streamSocketType = Int32(SOCK_STREAM.rawValue)
private let sendFlags = Int32(MSG_NOSIGNAL)
#else
private let streamSocketType = SOCK_STREAM
private let sendFlags: Int32 = 0
#endif

/// A small HTTP/1.1 server on 127.0.0.1 for tests that need a real connection: upload progress, the bytes on the
/// wire, and a server that never answers. One request per connection; every answer closes the connection.
final class LoopbackServer: @unchecked Sendable {
    struct Request: Sendable {
        let method: String
        let path: String
        /// Header names in lower case.
        let headers: [String: String]
        let body: Data
    }

    struct Response: Sendable {
        var status: Int
        var headers: [String: String] = [:]
        var body = Data()
    }

    let port: UInt16
    private let listener: Int32
    private let handler: @Sendable (Request) -> Response?
    private let lock = NSLock()
    private var requests: [Request] = []
    private var connections = Set<Int32>()
    private var stopped = false

    var baseURL: URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }

    var receivedRequests: [Request] {
        lock.lock()
        defer { lock.unlock() }
        return requests
    }

    private var isStopped: Bool {
        lock.lock()
        defer { lock.unlock() }
        return stopped
    }

    /// - Parameter handler: The answer to a request, or nil to never answer (the connection stays open until the
    ///   client closes it or the server stops).
    init(handler: @escaping @Sendable (Request) -> Response?) throws {
        self.handler = handler
        let socketFD = socket(AF_INET, streamSocketType, 0)

        guard socketFD >= 0 else {
            throw POSIXError(.EIO)
        }

        var address = Self.loopbackAddress(port: 0)
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)

        let bound = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(socketFD, $0, length) }
        }

        guard bound == 0, listen(socketFD, 16) == 0 else {
            close(socketFD)
            throw POSIXError(.EADDRINUSE)
        }

        _ = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(socketFD, $0, &length) }
        }

        port = UInt16(bigEndian: address.sin_port)
        listener = socketFD
        Thread { [self] in acceptLoop() }.start()
    }

    deinit {
        stop()
    }

    /// A port on 127.0.0.1 where nothing listens: connections are refused.
    static func unusedPort() -> UInt16 {
        let socketFD = socket(AF_INET, streamSocketType, 0)
        defer { close(socketFD) }
        var address = loopbackAddress(port: 0)
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(socketFD, $0, length) }
        }
        _ = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(socketFD, $0, &length) }
        }
        return UInt16(bigEndian: address.sin_port)
    }

    /// Stops accepting and ends open connections; the threads close their own sockets.
    func stop() {
        lock.lock()

        if stopped {
            lock.unlock()
            return
        }

        stopped = true
        let open = connections
        lock.unlock()

        shutdown(listener, Int32(SHUT_RDWR))

        for connection in open {
            shutdown(connection, Int32(SHUT_RDWR))
        }
    }

    func waitForRequests(_ count: Int, timeout: TimeInterval = 10) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if receivedRequests.count >= count {
                return true
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        return false
    }

    private static func loopbackAddress(port: UInt16) -> sockaddr_in {
        var address = sockaddr_in()
        #if canImport(Darwin)
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = UInt32(0x7F00_0001).bigEndian
        return address
    }

    private func acceptLoop() {
        defer { close(listener) }

        while !isStopped {
            guard waitReadable(listener) else {
                continue
            }

            let connection = accept(listener, nil, nil)

            if connection < 0 {
                continue
            }

            #if canImport(Darwin)
            var yes: Int32 = 1
            setsockopt(connection, SOL_SOCKET, SO_NOSIGPIPE, &yes, socklen_t(MemoryLayout<Int32>.size))
            #endif

            lock.lock()
            let accepted = !stopped

            if accepted {
                connections.insert(connection)
            }

            lock.unlock()

            if accepted {
                Thread { [self] in serve(connection) }.start()
            } else {
                close(connection)
            }
        }
    }

    private func serve(_ connection: Int32) {
        defer {
            lock.lock()
            connections.remove(connection)
            lock.unlock()
            close(connection)
        }

        guard let request = readRequest(connection) else {
            return
        }

        lock.lock()
        requests.append(request)
        lock.unlock()

        guard let response = handler(request) else {
            // Never answer: keep the connection until the client closes it or the server stops.
            while receive(connection) != nil {}
            return
        }

        var head = "HTTP/1.1 \(response.status) \(Self.reason(response.status))\r\n"

        for (name, value) in response.headers {
            head += "\(name): \(value)\r\n"
        }

        head += "Content-Length: \(response.body.count)\r\nConnection: close\r\n\r\n"
        sendAll(Data(head.utf8) + response.body, to: connection)
    }

    private func readRequest(_ connection: Int32) -> Request? {
        var buffer = Data()
        var headerEnd: Range<Data.Index>?

        while headerEnd == nil {
            guard let chunk = receive(connection), buffer.count < 1_000_000 else {
                return nil
            }

            buffer.append(chunk)
            headerEnd = buffer.range(of: Data("\r\n\r\n".utf8))
        }

        guard let end = headerEnd else {
            return nil
        }

        var lines = String(decoding: buffer[buffer.startIndex..<end.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
        let requestLine = lines.removeFirst().split(separator: " ")

        guard requestLine.count >= 2 else {
            return nil
        }

        var headers: [String: String] = [:]

        for line in lines {
            if let colon = line.firstIndex(of: ":") {
                headers[line[..<colon].lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            }
        }

        var body = Data(buffer[end.upperBound...])

        if let length = headers["content-length"].flatMap({ Int($0) }) {
            while body.count < length {
                guard let chunk = receive(connection) else {
                    return nil
                }

                body.append(chunk)
            }

            body = Data(body.prefix(length))
        } else if headers["transfer-encoding"]?.lowercased().contains("chunked") == true {
            while Self.decodeChunked(body) == nil {
                guard let chunk = receive(connection) else {
                    return nil
                }

                body.append(chunk)
            }

            body = Self.decodeChunked(body) ?? Data()
        }

        return Request(method: String(requestLine[0]), path: String(requestLine[1]), headers: headers, body: body)
    }

    /// Next bytes from the connection; nil when it closed, failed or the server stopped.
    private func receive(_ connection: Int32) -> Data? {
        while true {
            if isStopped {
                return nil
            }

            if waitReadable(connection) {
                break
            }
        }

        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        let count = recv(connection, &buffer, buffer.count, 0)
        return count > 0 ? Data(buffer[0..<count]) : nil
    }

    /// Waits up to 100 ms, so a stopped server is noticed on every platform.
    private func waitReadable(_ socketFD: Int32) -> Bool {
        var descriptor = pollfd(fd: socketFD, events: Int16(POLLIN), revents: 0)
        return poll(&descriptor, 1, 100) > 0
    }

    private func sendAll(_ data: Data, to connection: Int32) {
        let bytes = [UInt8](data)
        var offset = 0

        while offset < bytes.count {
            let sent = bytes.withUnsafeBufferPointer { buffer in
                send(connection, buffer.baseAddress! + offset, bytes.count - offset, sendFlags)
            }

            if sent <= 0 {
                return
            }

            offset += sent
        }
    }

    /// The decoded body, or nil while the terminating chunk has not arrived.
    private static func decodeChunked(_ data: Data) -> Data? {
        let crlf = Data("\r\n".utf8)
        var result = Data()
        var index = data.startIndex

        while true {
            guard let lineEnd = data.range(of: crlf, in: index..<data.endIndex) else {
                return nil
            }

            let sizeText = String(decoding: data[index..<lineEnd.lowerBound], as: UTF8.self).split(separator: ";").first.map(String.init) ?? ""

            guard let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16) else {
                return nil
            }

            index = lineEnd.upperBound

            if size == 0 {
                return result
            }

            guard data.distance(from: index, to: data.endIndex) >= size + 2 else {
                return nil
            }

            let chunkEnd = data.index(index, offsetBy: size)
            result.append(data[index..<chunkEnd])
            index = data.index(chunkEnd, offsetBy: 2)
        }
    }

    private static func reason(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 413: return "Payload Too Large"
        case 429: return "Too Many Requests"
        case 500: return "Internal Server Error"
        default: return "Status"
        }
    }
}

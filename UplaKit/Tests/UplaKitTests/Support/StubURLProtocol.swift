import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Answers every request of a session made with `StubURLProtocol.configuration()` without any network access, and
/// records what was sent. Tests run one at a time, so the shared state is reset in each test's setUp.
final class StubURLProtocol: URLProtocol {
    struct Captured: Sendable {
        let method: String
        let url: URL
        /// Header names in lower case.
        let headers: [String: String]
        let body: Data
    }

    struct Reply: Sendable {
        var status: Int
        var headers: [String: String] = [:]
        var body = Data()

        static func json(_ status: Int, _ text: String, headers: [String: String] = [:]) -> Reply {
            Reply(status: status, headers: headers.merging(["Content-Type": "application/json; charset=UTF-8"]) { current, _ in current }, body: Data(text.utf8))
        }

        static func html(_ status: Int, _ text: String = "<html><body>page</body></html>", headers: [String: String] = [:]) -> Reply {
            Reply(status: status, headers: headers.merging(["Content-Type": "text/html; charset=UTF-8"]) { current, _ in current }, body: Data(text.utf8))
        }
    }

    enum Behavior: Sendable {
        case reply(Reply)
        /// Never answers; the request ends only when it is cancelled.
        case hang
    }

    static let state = StubState()

    static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        // macOS hands a custom protocol the body as a stream; on Linux an upload task's file body is not passed on at
        // all, so it is read from the client's temporary folder, where it exists while the request runs.
        let body = request.httpBody ?? Self.read(request.httpBodyStream) ?? Self.state.bodyFromDirectory() ?? Data()
        var headers: [String: String] = [:]

        for (name, value) in request.allHTTPHeaderFields ?? [:] {
            headers[name.lowercased()] = value
        }

        let url = request.url ?? URL(string: "about:blank")!
        let behavior = Self.state.record(Captured(method: request.httpMethod ?? "GET", url: url, headers: headers, body: body))

        guard case .reply(let reply) = behavior else {
            return
        }

        let response = HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if !reply.body.isEmpty {
            client?.urlProtocol(self, didLoad: reply.body)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }

    private static func read(_ stream: InputStream?) -> Data? {
        guard let stream else {
            return nil
        }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        stream.open()
        defer { stream.close() }

        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)

            if count <= 0 {
                break
            }

            data.append(buffer, count: count)
        }

        return data
    }
}

final class StubState: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: @Sendable (StubURLProtocol.Captured) -> StubURLProtocol.Behavior = { _ in .reply(.html(500)) }
    private var captured: [StubURLProtocol.Captured] = []
    private var directory: URL?

    var requests: [StubURLProtocol.Captured] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    func reset(bodyDirectory: URL? = nil, handler: @escaping @Sendable (StubURLProtocol.Captured) -> StubURLProtocol.Behavior) {
        lock.lock()
        defer { lock.unlock() }
        self.handler = handler
        captured = []
        directory = bodyDirectory
    }

    func reply(_ reply: StubURLProtocol.Reply, bodyDirectory: URL? = nil) {
        reset(bodyDirectory: bodyDirectory) { _ in .reply(reply) }
    }

    func record(_ request: StubURLProtocol.Captured) -> StubURLProtocol.Behavior {
        lock.lock()
        captured.append(request)
        let handler = self.handler
        lock.unlock()
        return handler(request)
    }

    func bodyFromDirectory() -> Data? {
        lock.lock()
        let directory = self.directory
        lock.unlock()

        guard let directory,
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil),
              let file = files.first(where: { $0.pathExtension == "upload" }) else {
            return nil
        }

        return try? Data(contentsOf: file)
    }

    /// Waits until `count` requests arrived (for tests that cancel a request the stub holds open).
    func waitForRequests(_ count: Int, timeout: TimeInterval = 10) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if requests.count >= count {
                return true
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        return false
    }
}

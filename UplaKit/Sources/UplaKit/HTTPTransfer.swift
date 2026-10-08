import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// What one request came back with.
struct TransferOutcome: Sendable {
    var data = Data()
    /// nil when no HTTP answer arrived.
    var statusCode: Int?
    var retryAfter: String?
    /// The request ended with a network error (the answer, if any, may be incomplete).
    var failed = false
    /// The Swift task was cancelled while the request ran.
    var cancelled = false
    /// The caller's time limit ran out.
    var timedOut = false
}

/// Runs one request in its own URLSession, whose delegate reports upload progress (didSendBodyData), and maps Swift
/// task cancellation to URLSessionTask.cancel(). Built on delegate callbacks only, so it behaves the same on macOS
/// and on Linux, where completion-handler tasks get no progress callbacks.
enum HTTPTransfer {
    /// - Parameters:
    ///   - bodyFile: Sent with uploadTask(with:fromFile:); otherwise the request's httpBody is sent.
    ///   - bodySize: Size of the body, for the progress fraction.
    ///   - timeLimit: Total time for the whole exchange (URLSession's own timeouts only measure idle time).
    static func run(_ request: URLRequest, bodyFile: URL? = nil, bodySize: Int64 = 0, configuration: URLSessionConfiguration, timeLimit: TimeInterval? = nil, progress: (@Sendable (Double) -> Void)? = nil) async -> TransferOutcome {
        let delegate = TransferDelegate(bodySize: bodySize, progress: progress)
        let control = TransferControl()
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        let timer = timeLimit.map { limit in
            Task {
                try? await Task.sleep(nanoseconds: UInt64(max(0, limit) * 1_000_000_000))

                if !Task.isCancelled {
                    control.timeOut()
                }
            }
        }

        var outcome = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<TransferOutcome, Never>) in
                delegate.wait(with: continuation)
                let task: URLSessionTask

                if let bodyFile {
                    task = session.uploadTask(with: request, fromFile: bodyFile)
                } else {
                    task = session.dataTask(with: request)
                }

                if control.start(task) {
                    // The session lets the task finish, then releases the delegate.
                    session.finishTasksAndInvalidate()
                } else {
                    session.invalidateAndCancel()
                    delegate.finish(TransferOutcome(failed: true))
                }
            }
        } onCancel: {
            control.cancel()
        }

        timer?.cancel()
        let state = control.state
        outcome.cancelled = state.cancelled
        outcome.timedOut = state.timedOut
        return outcome
    }
}

/// Starts and stops the task; cancellation can arrive before the task exists.
private final class TransferControl: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionTask?
    private var cancelled = false
    private var timedOut = false

    var state: (cancelled: Bool, timedOut: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return (cancelled, timedOut)
    }

    /// Resumes the task, or returns false when the request was already stopped.
    func start(_ task: URLSessionTask) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if cancelled || timedOut {
            return false
        }

        self.task = task
        task.resume()
        return true
    }

    func cancel() {
        stop(timedOut: false)
    }

    func timeOut() {
        stop(timedOut: true)
    }

    private func stop(timedOut isTimeout: Bool) {
        lock.lock()

        if !cancelled && !timedOut {
            if isTimeout {
                timedOut = true
            } else {
                cancelled = true
            }
        }

        let task = self.task
        lock.unlock()
        task?.cancel()
    }
}

/// Collects the answer; the session calls it on its own serial queue, the continuation is resumed exactly once.
private final class TransferDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private let bodySize: Int64
    private let progress: (@Sendable (Double) -> Void)?
    private var received = Data()
    private var continuation: CheckedContinuation<TransferOutcome, Never>?
    private var finished = false

    init(bodySize: Int64, progress: (@Sendable (Double) -> Void)?) {
        self.bodySize = bodySize
        self.progress = progress
    }

    func wait(with continuation: CheckedContinuation<TransferOutcome, Never>) {
        lock.lock()
        self.continuation = continuation
        lock.unlock()
    }

    func finish(_ outcome: TransferOutcome) {
        lock.lock()

        if finished {
            lock.unlock()
            return
        }

        finished = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: outcome)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        received.append(data)
        lock.unlock()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let progress else {
            return
        }

        let total = bodySize > 0 ? bodySize : totalBytesExpectedToSend

        if total > 0 {
            progress(min(1, max(0, Double(totalBytesSent) / Double(total))))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let response = task.response as? HTTPURLResponse
        lock.lock()
        let data = received
        lock.unlock()
        finish(TransferOutcome(data: data, statusCode: response?.statusCode, retryAfter: response?.value(forHTTPHeaderField: "Retry-After"), failed: error != nil))
    }
}

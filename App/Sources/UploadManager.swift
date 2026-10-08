import AppKit
import Combine
import Foundation
import UplaKit

// Uploads files one after another, with progress for the menu bar item.
@MainActor
final class UploadManager: ObservableObject {
    private struct Job {
        let id = UUID()
        let fileURL: URL
        let fileName: String
        // Captures and clipboard images live in the temporary folder and are removed after the upload.
        let isTemporary: Bool
    }

    // Fraction of the current upload that was sent, nil when idle.
    @Published private(set) var progress: Double?
    // Uploads waiting behind the current one.
    @Published private(set) var queuedCount = 0

    // Called when the menu bar item should redraw (progress or queue changed).
    var onChange: (@MainActor () -> Void)?

    private let settings: AppSettings
    private let account: AccountStore
    private let history: HistoryStore
    private let notifier: Notifier
    private var queue: [Job] = []
    private var current: Job?
    private var currentTask: Task<Void, Never>?

    init(settings: AppSettings, account: AccountStore, history: HistoryStore, notifier: Notifier) {
        self.settings = settings
        self.account = account
        self.history = history
        self.notifier = notifier
    }

    var isBusy: Bool {
        current != nil
    }

    func enqueue(_ fileURL: URL, isTemporary: Bool) {
        queue.append(Job(fileURL: fileURL, fileName: fileURL.lastPathComponent, isTemporary: isTemporary))
        queuedCount = queue.count
        startNext()
        onChange?()
    }

    func enqueue(_ fileURLs: [URL]) {
        for url in fileURLs {
            enqueue(url, isTemporary: false)
        }
    }

    // Cancels the current upload and drops the waiting ones.
    func cancelAll() {
        for job in queue where job.isTemporary {
            TempFiles.remove(job.fileURL)
        }

        queue.removeAll()
        queuedCount = 0
        currentTask?.cancel()
        onChange?()
    }

    private func startNext() {
        guard current == nil, !queue.isEmpty else {
            return
        }

        let job = queue.removeFirst()
        queuedCount = queue.count
        current = job
        progress = 0

        currentTask = Task {
            await self.run(job)
            self.finish(job)
        }
    }

    private func finish(_ job: Job) {
        if job.isTemporary {
            TempFiles.remove(job.fileURL)
        }

        current = nil
        currentTask = nil
        progress = nil
        onChange?()
        startNext()
    }

    private func updateProgress(_ fraction: Double, jobID: UUID) {
        guard current?.id == jobID else {
            return
        }

        let value = min(max(fraction, 0), 1)

        // Redraw only when the shown percentage changes.
        if Int((progress ?? 0) * 100) != Int(value * 100) {
            progress = value
            onChange?()
        }
    }

    private func run(_ job: Job) async {
        // Never fall back to a guest upload when an account is remembered but cannot be used.
        let keyKind: UploadKeyKind
        let apiKey: String

        switch account.state {
        case .lost:
            reportFailure(UplaText.signInLostText, job: job)
            return
        case .expired:
            reportFailure(UplaText.invalidSignInText, job: job)
            return
        case .signedIn, .manualKey:
            guard let key = account.memberKey else {
                reportFailure(UplaText.signInLostText, job: job)
                return
            }
            apiKey = key
            keyKind = account.state == .manualKey ? .manual : .signIn
        case .guest:
            let guestKey = AppEnvironment.guestAPIKey
            guard !guestKey.isEmpty else {
                reportFailure(UplaText.noGuestKeyText, job: job)
                return
            }
            apiKey = guestKey
            keyKind = .guest
        }

        notifier.prepare()

        let isMember = keyKind != .guest
        let client = UplaClient(apiKey: apiKey, isMember: isMember, baseURL: AppEnvironment.baseURL)
        let options = settings.uploadOptions
        let jobID = job.id
        let manager = self

        uploadLog.info("Uploading \(job.fileName, privacy: .public) as \(isMember ? "member" : "guest", privacy: .public)")

        do {
            let result = try await client.upload(fileURL: job.fileURL, fileName: job.fileName, options: options,
                                                 progress: { fraction in
                Task { @MainActor in
                    manager.updateProgress(fraction, jobID: jobID)
                }
            })
            reportSuccess(result, job: job)
        } catch let error as UplaUploadError {
            handle(error, job: job, keyKind: keyKind)
        } catch {
            handle(Task.isCancelled ? .cancelled : .unexpectedResponse, job: job, keyKind: keyKind)
        }
    }

    private func handle(_ error: UplaUploadError, job: Job, keyKind: UploadKeyKind) {
        if error == .cancelled {
            uploadLog.info("Upload cancelled")
            return
        }

        uploadLog.error("Upload failed: \(String(describing: error), privacy: .public)")

        if case .invalidKey(let isMember) = error, isMember, keyKind == .signIn {
            // Lets the account menu offer "Sign In Again".
            account.markExpired()
        }

        reportFailure(UplaText.uploadError(error, keyKind: keyKind), job: job)
    }

    private func reportSuccess(_ result: UplaUploadResult, job: Job) {
        Pasteboard.copy(link: result.url)

        history.add(HistoryItem(fileName: job.fileName, url: result.url, thumbnailURL: result.thumbnailURL,
                                deletionURL: result.deletionURL, isVideo: Upla.isVideoExtension(job.fileURL.pathExtension),
                                awaitingModeration: result.awaitingModeration))

        uploadLog.info("Upload finished")

        guard settings.showNotifications else {
            return
        }

        var body = String(localized: "The link was copied to the clipboard.")

        if result.awaitingModeration {
            body += " " + String(localized: "The file is waiting for moderation; until it is approved only the page link works.")
        }

        notifier.post(title: String(localized: "Uploaded to upla.com.tr"), body: body, link: result.url)
    }

    private func reportFailure(_ message: String, job: Job) {
        notifier.post(title: String(localized: "Upload failed: \(job.fileName)"), body: message, isError: true)
    }
}

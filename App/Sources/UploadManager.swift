import AppKit
import Combine
import Foundation
import UplaKit

// Uploads files one after another, with progress for the menu bar item.
@MainActor
final class UploadManager: ObservableObject {
    enum Kind {
        // A file the user chose (open panel, drop, files copied in Finder); left alone.
        case file
        // An image from the clipboard written to the temporary folder; removed afterwards (the clipboard still has it).
        case clipboardImage
        // A screenshot in the temporary folder, with the copy "Save to a folder" made, if any.
        case capture(savedCopy: URL?)
    }

    private struct Job {
        let id = UUID()
        let fileURL: URL
        let fileName: String
        let kind: Kind

        var isCapture: Bool {
            if case .capture = kind {
                return true
            }
            return false
        }
    }

    private enum Outcome {
        case uploaded
        case cancelled
        // Refused before sending or failed; the text says why.
        case failed(String)
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
    // Asks whether captures should keep being uploaded automatically; true keeps uploading.
    private let confirmFirstUpload: @MainActor () -> Bool
    private var queue: [Job] = []
    private var current: Job?
    private var currentTask: Task<Void, Never>?
    private var isAskingFirstUpload = false

    init(settings: AppSettings, account: AccountStore, history: HistoryStore, notifier: Notifier,
         confirmFirstUpload: @escaping @MainActor () -> Bool) {
        self.settings = settings
        self.account = account
        self.history = history
        self.notifier = notifier
        self.confirmFirstUpload = confirmFirstUpload
    }

    var isBusy: Bool {
        current != nil
    }

    func enqueue(_ fileURL: URL, kind: Kind) {
        queue.append(Job(fileURL: fileURL, fileName: fileURL.lastPathComponent, kind: kind))
        queuedCount = queue.count
        startNext()
        onChange?()
    }

    func enqueue(_ fileURLs: [URL]) {
        for url in fileURLs {
            enqueue(url, kind: .file)
        }
    }

    // Cancels the current upload and drops the waiting ones; cancelled screenshots are not kept.
    func cancelAll() {
        for job in queue {
            _ = dispose(job, keepCapture: false)
        }

        queue.removeAll()
        queuedCount = 0
        currentTask?.cancel()
        onChange?()
    }

    // When the app quits: screenshots not uploaded yet are moved to the save folder, because the temporary folder is
    // emptied right after (it also holds the request body with the key).
    func keepPendingCaptures() {
        let pending = (current.map { [$0] } ?? []) + queue
        queue.removeAll()
        queuedCount = 0
        currentTask?.cancel()

        for job in pending {
            _ = dispose(job, keepCapture: true)
        }
    }

    private func startNext() {
        guard current == nil, !isAskingFirstUpload, let job = queue.first else {
            return
        }

        if settings.showUploadWarning && settings.uploadAfterCapture {
            askFirstUpload()
            return
        }

        queue.removeFirst()
        queuedCount = queue.count
        current = job
        progress = 0

        currentTask = Task {
            let outcome = await self.run(job)
            self.finish(job, outcome)
        }
    }

    // Asked once before the first upload, like UpLa for Windows: screenshots are uploaded automatically and anyone with
    // the link can open them. Turning it off uploads no screenshot now and saves them to a folder instead; files the
    // user chose are still uploaded.
    private func askFirstUpload() {
        isAskingFirstUpload = true

        // On a later pass of the run loop, so the alert never runs inside a drop or a menu action.
        Task {
            let keepUploading = self.confirmFirstUpload()
            self.settings.showUploadWarning = false
            self.isAskingFirstUpload = false

            if !keepUploading {
                self.settings.uploadAfterCapture = false

                if !self.settings.copyImageAfterCapture {
                    self.settings.saveAfterCapture = true
                }

                let captures = self.queue.filter { $0.isCapture }
                self.queue.removeAll { $0.isCapture }
                self.queuedCount = self.queue.count

                for job in captures {
                    if let keptURL = self.dispose(job, keepCapture: true), self.settings.showNotifications {
                        self.notifier.prepare()
                        self.notifier.post(title: String(localized: "Screenshot saved"), body: UploadManager.displayPath(keptURL))
                    }
                }
            }

            self.onChange?()
            self.startNext()
        }
    }

    private func finish(_ job: Job, _ outcome: Outcome) {
        switch outcome {
        case .uploaded, .cancelled:
            _ = dispose(job, keepCapture: false)
        case .failed(let message):
            let keptURL = dispose(job, keepCapture: true)
            reportFailure(message, job: job, keptURL: keptURL)
        }

        current = nil
        currentTask = nil
        progress = nil
        onChange?()
        startNext()
    }

    // Removes a temporary file once its upload ended. With keepCapture a screenshot stays in the save folder instead
    // (moved there unless "Save to a folder" already made a copy), so a failed upload never loses the only copy.
    // Returns where the screenshot is kept.
    private func dispose(_ job: Job, keepCapture: Bool) -> URL? {
        switch job.kind {
        case .file:
            return nil
        case .clipboardImage:
            TempFiles.remove(job.fileURL)
            return nil
        case .capture(let savedCopy):
            if let savedCopy {
                TempFiles.remove(job.fileURL)
                return keepCapture ? savedCopy : nil
            }

            guard keepCapture else {
                TempFiles.remove(job.fileURL)
                return nil
            }

            do {
                return try TempFiles.move(job.fileURL, to: settings.saveFolder)
            } catch {
                // Stays in the temporary folder until the app quits.
                appLog.error("Keeping the screenshot failed: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
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

    private func run(_ job: Job) async -> Outcome {
        // Never fall back to a guest upload when an account is remembered but cannot be used.
        let keyKind: UploadKeyKind
        let apiKey: String

        switch account.state {
        case .lost:
            return .failed(UplaText.signInLostText)
        case .signedIn, .expired, .manualKey:
            // An expired sign-in still uploads with its key and lets the server decide, like UpLa for Windows.
            guard let key = account.memberKey else {
                return .failed(UplaText.signInLostText)
            }
            apiKey = key
            keyKind = account.state == .manualKey ? .manual : .signIn
        case .guest:
            let guestKey = AppEnvironment.guestAPIKey
            guard !guestKey.isEmpty else {
                return .failed(UplaText.noGuestKeyText)
            }
            apiKey = guestKey
            keyKind = .guest
        }

        notifier.prepare()

        let isMember = keyKind != .guest
        // The request body (with the key) goes to the app's temporary folder, which is emptied at launch and at quit.
        let client = UplaClient(apiKey: apiKey, isMember: isMember, baseURL: AppEnvironment.baseURL, configuration: .default,
                                temporaryDirectory: TempFiles.directory)
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
            return .uploaded
        } catch let error as UplaUploadError {
            return handle(error, apiKey: apiKey, keyKind: keyKind)
        } catch {
            return handle(Task.isCancelled ? .cancelled : .unexpectedResponse, apiKey: apiKey, keyKind: keyKind)
        }
    }

    private func handle(_ error: UplaUploadError, apiKey: String, keyKind: UploadKeyKind) -> Outcome {
        if error == .cancelled {
            uploadLog.info("Upload cancelled")
            return .cancelled
        }

        uploadLog.error("Upload failed: \(String(describing: error), privacy: .public)")

        if case .invalidKey(let isMember) = error, isMember, keyKind == .signIn {
            // Lets the account menu offer "Sign In Again"; a key that was replaced during the upload is left alone.
            account.markExpired(ifKeyIs: apiKey)
        }

        return .failed(UplaText.uploadError(error, keyKind: keyKind))
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

    private func reportFailure(_ message: String, job: Job, keptURL: URL?) {
        var body = message

        if let keptURL {
            let path = UploadManager.displayPath(keptURL)
            body += " " + String(localized: "The screenshot was saved to \(path).")
        }

        notifier.prepare()
        notifier.post(title: String(localized: "Upload failed: \(job.fileName)"), body: body, isError: true)
    }

    // "~/Pictures/UpLa/UpLa_2026-10-08_12-00-00.png"
    static func displayPath(_ url: URL) -> String {
        let path = url.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}

import AppKit
@preconcurrency import AVFoundation
import CoreMedia
import CoreVideo
@preconcurrency import ScreenCaptureKit
import UplaKit

enum RecordingTarget: String, CaseIterable {
    case region
    case window
    case fullScreen

    var title: String {
        switch self {
        case .region:
            return String(localized: "Record Region…")
        case .window:
            return String(localized: "Record Window…")
        case .fullScreen:
            return String(localized: "Record Full Screen")
        }
    }
}

struct RecordingOptions {
    var framesPerSecond: Int
    var showsCursor: Bool
    var capturesAudio: Bool
    var limit: RecordingLimit
}

enum RecordingOutcome {
    // The MP4 in the temporary folder. stoppedAtLimit: the upload limit ended it, not the user.
    case finished(URL, stoppedAtLimit: Bool, limit: RecordingLimit)
    case cancelled
    case permissionMissing
    case failed(String)
}

enum RecordingError: LocalizedError {
    case displayNotFound
    case nothingRecorded
    case writerFailed

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return String(localized: "The screen to record was not found.")
        case .nothingRecorded:
            return String(localized: "Nothing was recorded.")
        case .writerFailed:
            return String(localized: "The video file could not be written.")
        }
    }
}

// Screen recording with ScreenCaptureKit: chooses what to record (the region overlay, the system's window picker or
// the screen under the mouse), writes it to an MP4 in the temporary folder and stops at the upload limit. Every start
// ends with exactly one onFinish call.
@MainActor
final class ScreenRecorder {
    enum State: Equatable {
        case idle
        // The region overlay or the window picker is open.
        case choosing
        case starting
        case recording
        case finishing
    }

    private(set) var state: State = .idle
    // Size of the MP4 so far, read twice a second while recording.
    private(set) var fileSize: Int64 = 0

    var onChange: (@MainActor () -> Void)?
    var onFinish: (@MainActor (RecordingOutcome) -> Void)?

    private var options: RecordingOptions?
    private var session: RecordingSession?
    private var startDate: Date?
    private var timer: Timer?
    // Cancel was chosen while the stream was starting; the start ends as cancelled.
    private var cancelWhenStarted = false
    // The stream stopped (or writing failed) while it was starting; the recording ends as soon as it runs.
    private var stoppedWhileStarting = false
    // Held from the start of the stream to its end, against App Nap and idle sleep.
    private var activity: NSObjectProtocol?
    private let regionSelector = RegionSelector()
    private var pickerObserver: PickerObserver?

    var isIdle: Bool {
        state == .idle
    }

    // The limit of the running recording (decides how its size is shown).
    var limit: RecordingLimit? {
        options?.limit
    }

    // Whole seconds since the recording started; nil unless recording.
    var elapsedSeconds: Int? {
        guard state == .recording, let startDate else {
            return nil
        }

        return max(0, Int(Date().timeIntervalSince(startDate)))
    }

    func start(_ target: RecordingTarget, options: RecordingOptions) {
        guard state == .idle else {
            return
        }

        self.options = options
        cancelWhenStarted = false
        stoppedWhileStarting = false
        fileSize = 0
        setState(.choosing)

        switch target {
        case .region:
            guard let screen = Self.screenUnderMouse() else {
                end(.failed(RecordingError.displayNotFound.localizedDescription))
                return
            }

            regionSelector.select(on: screen) { [weak self] selection in
                guard let self, self.state == .choosing else {
                    return
                }

                if let selection {
                    self.recordDisplay(screen, selection: selection)
                } else {
                    self.end(.cancelled)
                }
            }
        case .fullScreen:
            guard let screen = Self.screenUnderMouse() else {
                end(.failed(RecordingError.displayNotFound.localizedDescription))
                return
            }

            recordDisplay(screen, selection: screen.frame)
        case .window:
            presentWindowPicker()
        }
    }

    // Stops and keeps the recording. Before it runs there is nothing to keep, so it cancels.
    func stop() {
        switch state {
        case .recording:
            finish(stoppedAtLimit: false)
        case .choosing, .starting:
            cancel()
        case .idle, .finishing:
            break
        }
    }

    // Stops without keeping anything; the file is deleted.
    func cancel() {
        switch state {
        case .choosing:
            regionSelector.dismiss()
            end(.cancelled)
        case .starting:
            cancelWhenStarted = true
        case .recording:
            guard let session else {
                return
            }

            stopTimer()
            setState(.finishing)

            Task {
                await session.cancel()
                self.end(.cancelled)
            }
        case .idle, .finishing:
            break
        }
    }

    // MARK: Choosing what to record

    private func recordDisplay(_ screen: NSScreen, selection: CGRect) {
        guard state == .choosing, let options else {
            return
        }

        guard let area = RecordingVideo.area(selection: selection, screenFrame: screen.frame, scale: screen.backingScaleFactor),
              let displayID = Self.displayID(of: screen) else {
            end(.failed(RecordingError.displayNotFound.localizedDescription))
            return
        }

        setState(.starting)

        Task {
            do {
                // All windows, not only those on screen, so UpLa is listed even while its menu bar item is off screen
                // (a full screen app hides the menu bar).
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

                guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                    throw RecordingError.displayNotFound
                }

                // UpLa's own windows (the overlay while it fades, menus, settings) stay out of the video.
                let ownProcess = ProcessInfo.processInfo.processIdentifier
                let ownApps = content.applications.filter { $0.processID == ownProcess }

                if ownApps.isEmpty {
                    appLog.notice("UpLa is not in the shareable content; its windows may be recorded")
                }

                let filter = SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: [])
                let configuration = Self.configuration(options, width: area.width, height: area.height)
                configuration.sourceRect = area.sourceRect
                try await self.begin(filter: filter, configuration: configuration, width: area.width, height: area.height,
                                     options: options)
            } catch {
                self.fail(error)
            }
        }
    }

    // The system's window picker (macOS 14): the user clicks the window to record. It stays active while recording,
    // because the stream was started from its choice.
    private func presentWindowPicker() {
        let observer = PickerObserver(recorder: self)
        pickerObserver = observer

        let picker = SCContentSharingPicker.shared
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowedPickerModes = .singleWindow
        // The video size is fixed from the first choice, so another window cannot be chosen during the recording.
        configuration.allowsChangingSelectedContent = false

        if let bundleID = Bundle.main.bundleIdentifier {
            configuration.excludedBundleIDs = [bundleID]
        }

        picker.defaultConfiguration = configuration
        picker.add(observer)
        picker.isActive = true
        picker.present(using: .window)
    }

    private func closeWindowPicker() {
        guard let pickerObserver else {
            return
        }

        let picker = SCContentSharingPicker.shared
        picker.remove(pickerObserver)
        picker.isActive = false
        self.pickerObserver = nil
    }

    fileprivate func pickerDidSelect(_ filter: SCContentFilter) {
        guard state == .choosing, let options else {
            return
        }

        let rect = filter.contentRect
        let scale = CGFloat(max(filter.pointPixelScale, 1))
        let size: (width: Int, height: Int)

        if rect.width >= 1 && rect.height >= 1 {
            size = RecordingVideo.size(pixelWidth: Int((rect.width * scale).rounded()),
                                       pixelHeight: Int((rect.height * scale).rounded()))
        } else {
            // No size known: the window is scaled into a 720p frame.
            appLog.notice("The chosen window has no size; recording at 1280×720")
            size = (1280, 720)
        }

        let configuration = Self.configuration(options, width: size.width, height: size.height)

        // From macOS 14.2 on, a window's child windows (sheets, popovers) are only recorded when asked for.
        if #available(macOS 14.2, *) {
            configuration.includeChildWindows = true
        }

        setState(.starting)

        Task {
            do {
                try await self.begin(filter: filter, configuration: configuration, width: size.width, height: size.height,
                                     options: options)
            } catch {
                self.fail(error)
            }
        }
    }

    fileprivate func pickerDidCancel() {
        if state == .choosing {
            end(.cancelled)
        }
    }

    fileprivate func pickerDidFail(_ error: Error) {
        if state == .choosing {
            fail(error)
        }
    }

    // MARK: Recording

    private func begin(filter: SCContentFilter, configuration: SCStreamConfiguration, width: Int, height: Int,
                       options: RecordingOptions) async throws {
        let fileURL = try TempFiles.newFileURL(extension: "mp4")
        let session: RecordingSession

        do {
            session = try RecordingSession(fileURL: fileURL, filter: filter, configuration: configuration, width: width,
                                           height: height, framesPerSecond: options.framesPerSecond,
                                           capturesAudio: options.capturesAudio) { [weak self] error in
                Task { @MainActor in
                    self?.streamDidStop(error)
                }
            }
        } catch {
            TempFiles.remove(fileURL)
            throw error
        }

        // UpLa is never in front and its menu bar item is hidden over a full screen app, so App Nap could slow the limit
        // timer and the encoder. A long recording without input must not let the Mac or the display sleep either.
        if activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .idleDisplaySleepDisabled],
                                                             reason: "Screen recording")
        }

        do {
            try await session.start()
        } catch {
            await session.cancel()
            throw error
        }

        guard state == .starting, !cancelWhenStarted else {
            await session.cancel()
            end(.cancelled)
            return
        }

        self.session = session
        startDate = Date()
        setState(.recording)
        startTimer()
        appLog.info("Recording \(width, privacy: .public)×\(height, privacy: .public) at \(options.framesPerSecond, privacy: .public) fps")

        // The stream ended before the start was through: the recording ends now and keeps what was written.
        if stoppedWhileStarting {
            finish(stoppedAtLimit: false)
        }
    }

    // The system ended the stream (the window closed, the display went away, the user stopped sharing in the menu bar,
    // or writing failed): what was recorded is kept when it can be.
    private func streamDidStop(_ error: Error) {
        appLog.notice("The recording stream stopped: \(error.localizedDescription, privacy: .public)")

        if state == .recording {
            finish(stoppedAtLimit: false)
        } else if state == .starting {
            // The stream can stop before the start resumes on the main actor.
            stoppedWhileStarting = true
        }
    }

    private func finish(stoppedAtLimit: Bool) {
        guard state == .recording, let session, let options else {
            return
        }

        stopTimer()
        setState(.finishing)

        Task {
            if let error = await session.finish() {
                appLog.error("Finishing the recording failed: \(error.localizedDescription, privacy: .public)")
                self.end(.failed(error.localizedDescription))
            } else {
                self.end(.finished(session.fileURL, stoppedAtLimit: stoppedAtLimit, limit: options.limit))
            }
        }
    }

    private func fail(_ error: Error) {
        guard !cancelWhenStarted else {
            end(.cancelled)
            return
        }

        appLog.error("Recording failed: \(error.localizedDescription, privacy: .public)")

        if let streamError = error as? SCStreamError, streamError.code == .userDeclined {
            end(.permissionMissing)
        } else {
            end(.failed(error.localizedDescription))
        }
    }

    private func end(_ outcome: RecordingOutcome) {
        guard state != .idle else {
            return
        }

        stopTimer()
        closeWindowPicker()

        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }

        session = nil
        options = nil
        startDate = nil
        cancelWhenStarted = false
        stoppedWhileStarting = false
        setState(.idle)
        onFinish?(outcome)
    }

    private func setState(_ newState: State) {
        state = newState
        onChange?()
    }

    // In the common run loop modes, so the limit is checked while the menu is open too.
    private func startTimer() {
        stopTimer()

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Twice a second: the file size for the upload limit, and the elapsed time on the menu bar button.
    private func tick() {
        guard state == .recording, let session, let options else {
            return
        }

        fileSize = TempFiles.fileSize(session.fileURL)

        if options.limit.shouldStop(fileSize: fileSize) {
            appLog.notice("The recording reached the upload limit stop size")
            finish(stoppedAtLimit: true)
            return
        }

        onChange?()
    }

    private static func configuration(_ options: RecordingOptions, width: Int, height: Int) -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.width = width
        configuration.height = height
        configuration.scalesToFit = true
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(options.framesPerSecond))
        configuration.showsCursor = options.showsCursor
        // 4:2:0 frames in BT.709 with sRGB colours: what the H.264 encoder takes without converting them again.
        configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        configuration.colorMatrix = kCVImageBufferYCbCrMatrix_ITU_R_709_2
        configuration.colorSpaceName = CGColorSpace.sRGB
        // A few more frames in flight than the default 3, for the encoder.
        configuration.queueDepth = 6

        if options.capturesAudio {
            configuration.capturesAudio = true
            configuration.sampleRate = RecordingSession.audioSampleRate
            configuration.channelCount = RecordingSession.audioChannelCount
            configuration.excludesCurrentProcessAudio = true
        }

        return configuration
    }

    private static func screenUnderMouse() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }

    private static func displayID(of screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}

// Receives the answers of the system's window picker, which can come on any queue.
private final class PickerObserver: NSObject, SCContentSharingPickerObserver {
    private weak var recorder: ScreenRecorder?

    init(recorder: ScreenRecorder) {
        self.recorder = recorder
    }

    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        Task { @MainActor [weak recorder] in
            recorder?.pickerDidCancel()
        }
    }

    func contentSharingPicker(_ picker: SCContentSharingPicker, didUpdateWith filter: SCContentFilter, for stream: SCStream?) {
        Task { @MainActor [weak recorder] in
            recorder?.pickerDidSelect(filter)
        }
    }

    func contentSharingPickerStartDidFailWithError(_ error: Error) {
        Task { @MainActor [weak recorder] in
            recorder?.pickerDidFail(error)
        }
    }
}

// One recording: the stream's frames (and system audio) go into an AVAssetWriter on one serial queue. The mutable
// state below is used only on that queue.
final class RecordingSession: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    static let audioSampleRate = 48_000
    static let audioChannelCount = 2

    let fileURL: URL

    private let queue = DispatchQueue(label: "tr.com.upla.UpLa.recording", qos: .userInitiated)
    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput?
    private let frameDuration: CMTime
    private let onStop: @Sendable (Error) -> Void
    // Set once in init (it needs self as its delegate).
    private var captureStream: SCStream?

    private var sessionStartTime: CMTime?
    private var lastVideoSample: CMSampleBuffer?
    private var lastVideoTime = CMTime.invalid
    // The newest frame the encoder had no room for; it is written before anything newer.
    private var pendingVideoSample: CMSampleBuffer?
    private var stopTime: CMTime?
    private var isClosed = false
    private var reportedFailure = false

    init(fileURL: URL, filter: SCContentFilter, configuration: SCStreamConfiguration, width: Int, height: Int,
         framesPerSecond: Int, capturesAudio: Bool, onStop: @escaping @Sendable (Error) -> Void) throws {
        let writer = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
        // The media must reach fileURL while recording, because the upload limit stop reads its size. Optimized for
        // network use, the writer keeps the media in a hidden temporary file and creates fileURL only when finishing,
        // copying everything once more. The movie header goes to the end instead; browsers fetch it with a range request.
        writer.shouldOptimizeForNetworkUse = false

        let compression: [String: Any] = [
            AVVideoAverageBitRateKey: RecordingVideo.bitRate(width: width, height: height, framesPerSecond: framesPerSecond),
            AVVideoExpectedSourceFrameRateKey: framesPerSecond,
            AVVideoMaxKeyFrameIntervalKey: framesPerSecond * 2,
            AVVideoAllowFrameReorderingKey: false,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
        ]
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: compression,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        guard writer.canAdd(videoInput) else {
            throw RecordingError.writerFailed
        }

        writer.add(videoInput)
        var audioInput: AVAssetWriterInput?

        if capturesAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: RecordingSession.audioSampleRate,
                AVNumberOfChannelsKey: RecordingSession.audioChannelCount,
                AVEncoderBitRateKey: 128_000
            ]
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            input.expectsMediaDataInRealTime = true

            guard writer.canAdd(input) else {
                throw RecordingError.writerFailed
            }

            writer.add(input)
            audioInput = input
        }

        self.fileURL = fileURL
        self.onStop = onStop
        self.writer = writer
        self.videoInput = videoInput
        self.audioInput = audioInput
        frameDuration = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
        super.init()

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)

        if audioInput != nil {
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
        }

        captureStream = stream
    }

    // Creates the file and starts the stream; frames are written from the first complete one on.
    func start() async throws {
        guard let stream = captureStream else {
            throw RecordingError.writerFailed
        }

        guard writer.startWriting() else {
            throw writer.error ?? RecordingError.writerFailed
        }

        try await stream.startCapture()
    }

    // Stops the stream and closes the file. Returns nil when the MP4 is complete; otherwise the file is deleted and
    // the error returned.
    func finish() async -> Error? {
        let requested = CMClockGetTime(CMClockGetHostTimeClock())

        queue.async {
            self.stopTime = requested
        }

        await stopStream()

        let error = await withCheckedContinuation { (continuation: CheckedContinuation<Error?, Never>) in
            queue.async {
                self.closeFile(stoppedAt: requested) { error in
                    continuation.resume(returning: error)
                }
            }
        }

        if error != nil {
            try? FileManager.default.removeItem(at: fileURL)
        }

        return error
    }

    // Stops the stream and deletes the file.
    func cancel() async {
        await stopStream()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                self.isClosed = true
                self.lastVideoSample = nil
                self.pendingVideoSample = nil

                if self.writer.status == .writing {
                    self.writer.cancelWriting()
                }

                continuation.resume()
            }
        }

        try? FileManager.default.removeItem(at: fileURL)
    }

    private func stopStream() async {
        guard let stream = captureStream else {
            return
        }

        do {
            try await stream.stopCapture()
        } catch {
            // Already stopped by the system, or never started.
        }

        // The stream holds its outputs; removing them lets this session go.
        try? stream.removeStreamOutput(self, type: .screen)

        if audioInput != nil {
            try? stream.removeStreamOutput(self, type: .audio)
        }
    }

    // MARK: On the queue

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard !isClosed, CMSampleBufferIsValid(sampleBuffer), writer.status == .writing else {
            return
        }

        switch type {
        case .screen:
            appendVideo(sampleBuffer)
        case .audio:
            appendAudio(sampleBuffer)
        default:
            break
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onStop(error)
    }

    private func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        // A frame that waited for the encoder goes first, also on a callback without a new picture, so the last change
        // before a still screen is not lost.
        appendPendingVideo()

        // Only complete frames carry a new picture; idle, blank and suspended ones say that nothing changed. The SDK
        // calls the first new frame after the start "started", and on a still screen it may be the only one.
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
                as? [[SCStreamFrameInfo: Any]],
              let rawStatus = attachments.first?[.status] as? Int,
              let status = SCFrameStatus(rawValue: rawStatus),
              status == .complete || status == .started,
              CMSampleBufferGetImageBuffer(sampleBuffer) != nil else {
            return
        }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if let stopTime, time > stopTime {
            return
        }

        if sessionStartTime == nil {
            // The video starts with the first frame, not when the stream was asked to start.
            writer.startSession(atSourceTime: time)
            sessionStartTime = time
        }

        // Real-time input: when the encoder is behind, the stream is not held up. The newest frame waits for the next
        // callback, and an older waiting one is dropped.
        guard pendingVideoSample == nil, videoInput.isReadyForMoreMediaData else {
            pendingVideoSample = sampleBuffer
            return
        }

        appendVideoSample(sampleBuffer)
    }

    private func appendPendingVideo() {
        guard let pending = pendingVideoSample, videoInput.isReadyForMoreMediaData else {
            return
        }

        pendingVideoSample = nil
        appendVideoSample(pending)
    }

    private func appendVideoSample(_ sampleBuffer: CMSampleBuffer) {
        if videoInput.append(sampleBuffer) {
            lastVideoSample = sampleBuffer
            lastVideoTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        } else {
            reportWriterFailure()
        }
    }

    // At the end no more frames come, so the last ones may wait briefly (at most half a second) for the encoder.
    private func waitForVideoInput() -> Bool {
        var attempts = 0

        while !videoInput.isReadyForMoreMediaData && attempts < 50 {
            Thread.sleep(forTimeInterval: 0.01)
            attempts += 1
        }

        return videoInput.isReadyForMoreMediaData
    }

    private func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput, let sessionStartTime else {
            return
        }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        // Sound from before the first frame or after the stop is left out.
        guard time >= sessionStartTime, stopTime.map({ time <= $0 }) ?? true, audioInput.isReadyForMoreMediaData else {
            return
        }

        if !audioInput.append(sampleBuffer) {
            reportWriterFailure()
        }
    }

    // The writer failed (e.g. the disk is full): the recording ends like a stream the system stopped, and closing the
    // file reports the error.
    private func reportWriterFailure() {
        guard !reportedFailure else {
            return
        }

        reportedFailure = true
        let error = writer.error ?? RecordingError.writerFailed
        appLog.error("Writing the recording failed: \(error.localizedDescription, privacy: .public)")
        onStop(error)
    }

    private func closeFile(stoppedAt requested: CMTime, completion: @escaping @Sendable (Error?) -> Void) {
        isClosed = true
        let pending = pendingVideoSample
        pendingVideoSample = nil

        // The newest picture, if the encoder had no room for it yet.
        if writer.status == .writing, let pending, waitForVideoInput() {
            appendVideoSample(pending)
        }

        guard writer.status == .writing else {
            lastVideoSample = nil
            completion(writer.error ?? RecordingError.writerFailed)
            return
        }

        guard sessionStartTime != nil, let lastSample = lastVideoSample else {
            writer.cancelWriting()
            completion(RecordingError.nothingRecorded)
            return
        }

        // A still screen sends no new frames, so the last frame is repeated at the moment the recording stopped (at
        // least one frame later) and the video lasts until then.
        let end = max(requested, CMTimeAdd(lastVideoTime, frameDuration))

        if waitForVideoInput(), let copy = Self.retimed(lastSample, to: end) {
            _ = videoInput.append(copy)
        }

        lastVideoSample = nil

        // A failed append leaves the writer failed, with nothing left to finish.
        guard writer.status == .writing else {
            completion(writer.error ?? RecordingError.writerFailed)
            return
        }

        videoInput.markAsFinished()
        audioInput?.markAsFinished()
        writer.endSession(atSourceTime: end)

        writer.finishWriting {
            completion(self.writer.status == .completed ? nil : (self.writer.error ?? RecordingError.writerFailed))
        }
    }

    private static func retimed(_ sampleBuffer: CMSampleBuffer, to time: CMTime) -> CMSampleBuffer? {
        var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: time, decodeTimeStamp: .invalid)
        var copy: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(allocator: kCFAllocatorDefault, sampleBuffer: sampleBuffer,
                                                           sampleTimingEntryCount: 1, sampleTimingArray: &timing,
                                                           sampleBufferOut: &copy)
        return status == noErr ? copy : nil
    }
}

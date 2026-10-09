import Combine
import Foundation
import UplaKit

// User settings, kept in UserDefaults. The account and its key live in AccountStore (key in the keychain).
@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let showNotifications = "ShowNotifications"
        static let uploadAfterCapture = "UploadAfterCapture"
        static let copyImageAfterCapture = "CopyImageAfterCapture"
        static let saveAfterCapture = "SaveAfterCapture"
        static let saveFolderPath = "SaveFolderPath"
        static let linkType = "LinkType"
        static let album = "Album"
        static let tags = "Tags"
        static let categoryID = "CategoryID"
        static let expiration = "Expiration"
        static let maxWidth = "MaxWidth"
        static let stopRecordingAtUploadLimit = "StopRecordingAtUploadLimit"
        static let recordingFramesPerSecond = "RecordingFramesPerSecond"
        static let recordingShowsCursor = "RecordingShowsCursor"
        static let recordingCapturesAudio = "RecordingCapturesAudio"
        // Same name as the setting of UpLa for Windows.
        static let showUploadWarning = "ShowUploadWarning"
    }

    // The frame rates a recording can use.
    static let recordingFrameRates = [30, 60]

    private let defaults: UserDefaults

    // Notifications about finished uploads; failures are always reported.
    @Published var showNotifications: Bool { didSet { defaults.set(showNotifications, forKey: Key.showNotifications) } }

    // After-capture actions.
    @Published var uploadAfterCapture: Bool { didSet { defaults.set(uploadAfterCapture, forKey: Key.uploadAfterCapture) } }
    @Published var copyImageAfterCapture: Bool { didSet { defaults.set(copyImageAfterCapture, forKey: Key.copyImageAfterCapture) } }
    @Published var saveAfterCapture: Bool { didSet { defaults.set(saveAfterCapture, forKey: Key.saveAfterCapture) } }
    @Published var saveFolderPath: String { didSet { defaults.set(saveFolderPath, forKey: Key.saveFolderPath) } }

    // upla.com.tr upload options (album and tags are sent only with a member key).
    @Published var linkType: UplaLinkType { didSet { defaults.set(linkType.rawValue, forKey: Key.linkType) } }
    @Published var album: String { didSet { defaults.set(album, forKey: Key.album) } }
    @Published var tags: String { didSet { defaults.set(tags, forKey: Key.tags) } }
    @Published var categoryID: Int { didSet { defaults.set(categoryID, forKey: Key.categoryID) } }
    // One of Upla.expirationPresets, empty for no automatic deletion.
    @Published var expiration: String { didSet { defaults.set(expiration, forKey: Key.expiration) } }
    // Server side resize of wider images, 0 = off.
    @Published var maxWidth: Int { didSet { defaults.set(maxWidth, forKey: Key.maxWidth) } }
    // Screen recordings that will be uploaded stop a little below the upload limit, like on Windows.
    @Published var stopRecordingAtUploadLimit: Bool {
        didSet { defaults.set(stopRecordingAtUploadLimit, forKey: Key.stopRecordingAtUploadLimit) }
    }
    // Screen recording: 30 or 60 frames per second, the mouse pointer, and the sound apps play (no microphone).
    @Published var recordingFramesPerSecond: Int {
        didSet { defaults.set(recordingFramesPerSecond, forKey: Key.recordingFramesPerSecond) }
    }
    @Published var recordingShowsCursor: Bool { didSet { defaults.set(recordingShowsCursor, forKey: Key.recordingShowsCursor) } }
    @Published var recordingCapturesAudio: Bool {
        didSet { defaults.set(recordingCapturesAudio, forKey: Key.recordingCapturesAudio) }
    }
    // The question before the first upload is still to be asked (captures are uploaded automatically by default).
    var showUploadWarning: Bool { didSet { defaults.set(showUploadWarning, forKey: Key.showUploadWarning) } }

    static var defaultSaveFolder: URL {
        let pictures = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures", isDirectory: true)
        return pictures.appendingPathComponent("UpLa", isDirectory: true)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.showNotifications: true,
            Key.uploadAfterCapture: true,
            Key.copyImageAfterCapture: false,
            Key.saveAfterCapture: false,
            Key.stopRecordingAtUploadLimit: true,
            Key.recordingFramesPerSecond: 30,
            Key.recordingShowsCursor: true,
            Key.recordingCapturesAudio: false,
            Key.showUploadWarning: true
        ])

        showNotifications = defaults.bool(forKey: Key.showNotifications)
        uploadAfterCapture = defaults.bool(forKey: Key.uploadAfterCapture)
        copyImageAfterCapture = defaults.bool(forKey: Key.copyImageAfterCapture)
        saveAfterCapture = defaults.bool(forKey: Key.saveAfterCapture)
        saveFolderPath = defaults.string(forKey: Key.saveFolderPath) ?? ""
        linkType = UplaLinkType(rawValue: defaults.string(forKey: Key.linkType) ?? "") ?? .viewerPage
        album = defaults.string(forKey: Key.album) ?? ""
        tags = defaults.string(forKey: Key.tags) ?? ""
        categoryID = max(0, defaults.integer(forKey: Key.categoryID))
        let storedExpiration = defaults.string(forKey: Key.expiration) ?? ""
        expiration = Upla.expirationPresets.contains(storedExpiration) ? storedExpiration : ""
        maxWidth = max(0, defaults.integer(forKey: Key.maxWidth))
        stopRecordingAtUploadLimit = defaults.bool(forKey: Key.stopRecordingAtUploadLimit)
        let storedFrameRate = defaults.integer(forKey: Key.recordingFramesPerSecond)
        recordingFramesPerSecond = AppSettings.recordingFrameRates.contains(storedFrameRate) ? storedFrameRate : 30
        recordingShowsCursor = defaults.bool(forKey: Key.recordingShowsCursor)
        recordingCapturesAudio = defaults.bool(forKey: Key.recordingCapturesAudio)
        showUploadWarning = defaults.bool(forKey: Key.showUploadWarning)
    }

    var saveFolder: URL {
        saveFolderPath.isEmpty ? Self.defaultSaveFolder : URL(fileURLWithPath: saveFolderPath, isDirectory: true)
    }

    var uploadOptions: UplaUploadOptions {
        UplaUploadOptions(linkType: linkType, album: album, tags: tags, categoryID: max(0, categoryID),
                          expiration: expiration, maxWidth: max(0, maxWidth))
    }
}

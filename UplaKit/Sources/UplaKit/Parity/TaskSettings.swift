import Foundation

// The task settings of UpLa for Windows (ShareX/TaskSettings.cs) with the parts the Mac app uses or shows in phase 1.
// Field names and defaults are the Windows ones; fields marked "Mac" have no Windows counterpart. Further fields come
// with the features that use them.

public enum ImageDestination: String, WindowsNamedEnum {
    case chevereto = "Chevereto"
    case fileUploader = "FileUploader"
}

public enum FileDestination: String, WindowsNamedEnum {
    case chevereto = "Chevereto"
}

public enum TextDestination: String, WindowsNamedEnum {
    case fileUploader = "FileUploader"
}

/// The URL sharing services UpLa for Windows kept, in its order.
public enum URLSharingService: String, WindowsNamedEnum {
    case facebook = "Facebook"
    case reddit = "Reddit"
    case pinterest = "Pinterest"
    case tumblr = "Tumblr"
    case linkedIn = "LinkedIn"
    case vk = "VK"
}

public enum ImageFormat: String, WindowsNamedEnum {
    case png = "PNG"
    case jpeg = "JPEG"
    case gif = "GIF"
    case bmp = "BMP"
    case tiff = "TIFF"
}

public enum FileExistAction: String, WindowsNamedEnum {
    case ask = "Ask"
    case overwrite = "Overwrite"
    case uniqueName = "UniqueName"
    case cancel = "Cancel"
}

public struct TaskSettings: Codable, Equatable, Sendable {
    public var description = ""
    public var job: HotkeyType = .none

    public var useDefaultAfterCaptureJob = true
    public var afterCaptureJob: AfterCaptureTasks = .windowsDefault
    public var useDefaultAfterUploadJob = true
    public var afterUploadJob: AfterUploadTasks = .windowsDefault

    public var useDefaultDestinations = true
    public var imageDestination: ImageDestination = .chevereto
    public var imageFileDestination: FileDestination = .chevereto
    public var textDestination: TextDestination = .fileUploader
    public var textFileDestination: FileDestination = .chevereto
    public var fileDestination: FileDestination = .chevereto
    public var urlSharingServiceDestination: URLSharingService = .facebook

    public var overrideScreenshotsFolder = false
    public var screenshotsFolder = ""

    public var useDefaultGeneralSettings = true
    public var generalSettings = TaskSettingsGeneral()
    public var useDefaultImageSettings = true
    public var imageSettings = TaskSettingsImage()
    public var useDefaultCaptureSettings = true
    public var captureSettings = TaskSettingsCapture()
    public var useDefaultUploadSettings = true
    public var uploadSettings = TaskSettingsUpload()

    public init() {}

    /// The settings of a task, like a hotkey's: each part marked "use default" comes from the default task settings
    /// (TaskSettings.SetDefaultSettings on Windows).
    public func resolved(with defaults: TaskSettings) -> TaskSettings {
        var settings = self

        if useDefaultAfterCaptureJob {
            settings.afterCaptureJob = defaults.afterCaptureJob
        }
        if useDefaultAfterUploadJob {
            settings.afterUploadJob = defaults.afterUploadJob
        }
        if useDefaultDestinations {
            settings.imageDestination = defaults.imageDestination
            settings.imageFileDestination = defaults.imageFileDestination
            settings.textDestination = defaults.textDestination
            settings.textFileDestination = defaults.textFileDestination
            settings.fileDestination = defaults.fileDestination
            settings.urlSharingServiceDestination = defaults.urlSharingServiceDestination
        }
        if useDefaultGeneralSettings {
            settings.generalSettings = defaults.generalSettings
        }
        if useDefaultImageSettings {
            settings.imageSettings = defaults.imageSettings
        }
        if useDefaultCaptureSettings {
            settings.captureSettings = defaults.captureSettings
        }
        if useDefaultUploadSettings {
            settings.uploadSettings = defaults.uploadSettings
        }

        return settings
    }

    /// Whether every part follows the default task settings (a hotkey without "*" in the Workflows menu).
    public var isUsingDefaultSettings: Bool {
        useDefaultAfterCaptureJob && useDefaultAfterUploadJob && useDefaultDestinations && !overrideScreenshotsFolder
            && useDefaultGeneralSettings && useDefaultImageSettings && useDefaultCaptureSettings && useDefaultUploadSettings
    }

    enum CodingKeys: String, CodingKey {
        case description = "Description"
        case job = "Job"
        case useDefaultAfterCaptureJob = "UseDefaultAfterCaptureJob"
        case afterCaptureJob = "AfterCaptureJob"
        case useDefaultAfterUploadJob = "UseDefaultAfterUploadJob"
        case afterUploadJob = "AfterUploadJob"
        case useDefaultDestinations = "UseDefaultDestinations"
        case imageDestination = "ImageDestination"
        case imageFileDestination = "ImageFileDestination"
        case textDestination = "TextDestination"
        case textFileDestination = "TextFileDestination"
        case fileDestination = "FileDestination"
        case urlSharingServiceDestination = "URLSharingServiceDestination"
        case overrideScreenshotsFolder = "OverrideScreenshotsFolder"
        case screenshotsFolder = "ScreenshotsFolder"
        case useDefaultGeneralSettings = "UseDefaultGeneralSettings"
        case generalSettings = "GeneralSettings"
        case useDefaultImageSettings = "UseDefaultImageSettings"
        case imageSettings = "ImageSettings"
        case useDefaultCaptureSettings = "UseDefaultCaptureSettings"
        case captureSettings = "CaptureSettings"
        case useDefaultUploadSettings = "UseDefaultUploadSettings"
        case uploadSettings = "UploadSettings"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TaskSettings()
        description = container.value(.description, defaults.description)
        job = container.value(.job, defaults.job)
        useDefaultAfterCaptureJob = container.value(.useDefaultAfterCaptureJob, defaults.useDefaultAfterCaptureJob)
        afterCaptureJob = container.value(.afterCaptureJob, defaults.afterCaptureJob)
        useDefaultAfterUploadJob = container.value(.useDefaultAfterUploadJob, defaults.useDefaultAfterUploadJob)
        afterUploadJob = container.value(.afterUploadJob, defaults.afterUploadJob)
        useDefaultDestinations = container.value(.useDefaultDestinations, defaults.useDefaultDestinations)
        imageDestination = container.value(.imageDestination, defaults.imageDestination)
        imageFileDestination = container.value(.imageFileDestination, defaults.imageFileDestination)
        textDestination = container.value(.textDestination, defaults.textDestination)
        textFileDestination = container.value(.textFileDestination, defaults.textFileDestination)
        fileDestination = container.value(.fileDestination, defaults.fileDestination)
        urlSharingServiceDestination = container.value(.urlSharingServiceDestination, defaults.urlSharingServiceDestination)
        overrideScreenshotsFolder = container.value(.overrideScreenshotsFolder, defaults.overrideScreenshotsFolder)
        screenshotsFolder = container.value(.screenshotsFolder, defaults.screenshotsFolder)
        useDefaultGeneralSettings = container.value(.useDefaultGeneralSettings, defaults.useDefaultGeneralSettings)
        generalSettings = container.value(.generalSettings, defaults.generalSettings)
        useDefaultImageSettings = container.value(.useDefaultImageSettings, defaults.useDefaultImageSettings)
        imageSettings = container.value(.imageSettings, defaults.imageSettings)
        useDefaultCaptureSettings = container.value(.useDefaultCaptureSettings, defaults.useDefaultCaptureSettings)
        captureSettings = container.value(.captureSettings, defaults.captureSettings)
        useDefaultUploadSettings = container.value(.useDefaultUploadSettings, defaults.useDefaultUploadSettings)
        uploadSettings = container.value(.uploadSettings, defaults.uploadSettings)
    }
}

/// Task settings › General › Notifications.
public struct TaskSettingsGeneral: Codable, Equatable, Sendable {
    public var playSoundAfterCapture = true
    public var playSoundAfterUpload = true
    public var playSoundAfterAction = true
    public var showToastNotificationAfterTaskCompleted = true
    public var toastWindowDuration = 3.0
    public var toastWindowFadeDuration = 1.0
    public var toastWindowAutoHide = true
    public var disableNotificationsOnFullscreen = false
    /// Mac (decision 12): a macOS notification instead of UpLa's toast window. Off, as the toast is the Windows way.
    public var useMacOSNotifications = false

    public init() {}

    enum CodingKeys: String, CodingKey {
        case playSoundAfterCapture = "PlaySoundAfterCapture"
        case playSoundAfterUpload = "PlaySoundAfterUpload"
        case playSoundAfterAction = "PlaySoundAfterAction"
        case showToastNotificationAfterTaskCompleted = "ShowToastNotificationAfterTaskCompleted"
        case toastWindowDuration = "ToastWindowDuration"
        case toastWindowFadeDuration = "ToastWindowFadeDuration"
        case toastWindowAutoHide = "ToastWindowAutoHide"
        case disableNotificationsOnFullscreen = "DisableNotificationsOnFullscreen"
        case useMacOSNotifications = "UseMacOSNotifications"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TaskSettingsGeneral()
        playSoundAfterCapture = container.value(.playSoundAfterCapture, defaults.playSoundAfterCapture)
        playSoundAfterUpload = container.value(.playSoundAfterUpload, defaults.playSoundAfterUpload)
        playSoundAfterAction = container.value(.playSoundAfterAction, defaults.playSoundAfterAction)
        showToastNotificationAfterTaskCompleted = container.value(.showToastNotificationAfterTaskCompleted,
                                                                  defaults.showToastNotificationAfterTaskCompleted)
        toastWindowDuration = container.value(.toastWindowDuration, defaults.toastWindowDuration)
        toastWindowFadeDuration = container.value(.toastWindowFadeDuration, defaults.toastWindowFadeDuration)
        toastWindowAutoHide = container.value(.toastWindowAutoHide, defaults.toastWindowAutoHide)
        disableNotificationsOnFullscreen = container.value(.disableNotificationsOnFullscreen,
                                                           defaults.disableNotificationsOnFullscreen)
        useMacOSNotifications = container.value(.useMacOSNotifications, defaults.useMacOSNotifications)
    }
}

/// Task settings › Image.
public struct TaskSettingsImage: Codable, Equatable, Sendable {
    public var imageFormat: ImageFormat = .png
    public var imageJPEGQuality = 90
    // Windows saves a PNG larger than this many kilobytes as JPEG.
    public var imageAutoUseJPEG = true
    public var imageAutoUseJPEGSize = 2048
    public var fileExistAction: FileExistAction = .ask

    public init() {}

    enum CodingKeys: String, CodingKey {
        case imageFormat = "ImageFormat"
        case imageJPEGQuality = "ImageJPEGQuality"
        case imageAutoUseJPEG = "ImageAutoUseJPEG"
        case imageAutoUseJPEGSize = "ImageAutoUseJPEGSize"
        case fileExistAction = "FileExistAction"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TaskSettingsImage()
        imageFormat = container.value(.imageFormat, defaults.imageFormat)
        imageJPEGQuality = container.value(.imageJPEGQuality, defaults.imageJPEGQuality)
        imageAutoUseJPEG = container.value(.imageAutoUseJPEG, defaults.imageAutoUseJPEG)
        imageAutoUseJPEGSize = container.value(.imageAutoUseJPEGSize, defaults.imageAutoUseJPEGSize)
        fileExistAction = container.value(.fileExistAction, defaults.fileExistAction)
    }
}

/// The "Screen recording settings..." window (FFmpegOptions on Windows). Only the audio source exists on the Mac.
public struct FFmpegOptions: Codable, Equatable, Sendable {
    /// Mac: the sound apps play (ScreenCaptureKit). Windows stores a DirectShow device name here.
    public static let systemAudioSource = "system-audio"

    /// Empty: no audio ("None" on Windows).
    public var audioSource = ""

    public init() {}

    enum CodingKeys: String, CodingKey {
        case audioSource = "AudioSource"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        audioSource = container.value(.audioSource, "")
    }
}

/// Task settings › Capture, with the Screen recorder page.
public struct TaskSettingsCapture: Codable, Equatable, Sendable {
    public var showCursor = true
    /// Seconds before a screenshot; the Capture menu offers 0–5.
    public var screenshotDelay = 0.0
    public var captureTransparent = false
    public var captureShadow = true
    public var captureClientArea = false

    public var ffmpegOptions = FFmpegOptions()
    public var screenRecordFPS = 30
    public var gifFPS = 15
    public var screenRecordShowCursor = true
    public var screenRecordAutoStart = true
    public var screenRecordStartDelay = 0.0
    public var screenRecordFixedDuration = false
    public var screenRecordDuration = 3.0
    public var screenRecordAskConfirmationOnAbort = false

    public init() {}

    enum CodingKeys: String, CodingKey {
        case showCursor = "ShowCursor"
        case screenshotDelay = "ScreenshotDelay"
        case captureTransparent = "CaptureTransparent"
        case captureShadow = "CaptureShadow"
        case captureClientArea = "CaptureClientArea"
        case ffmpegOptions = "FFmpegOptions"
        case screenRecordFPS = "ScreenRecordFPS"
        case gifFPS = "GIFFPS"
        case screenRecordShowCursor = "ScreenRecordShowCursor"
        case screenRecordAutoStart = "ScreenRecordAutoStart"
        case screenRecordStartDelay = "ScreenRecordStartDelay"
        case screenRecordFixedDuration = "ScreenRecordFixedDuration"
        case screenRecordDuration = "ScreenRecordDuration"
        case screenRecordAskConfirmationOnAbort = "ScreenRecordAskConfirmationOnAbort"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TaskSettingsCapture()
        showCursor = container.value(.showCursor, defaults.showCursor)
        screenshotDelay = container.value(.screenshotDelay, defaults.screenshotDelay)
        captureTransparent = container.value(.captureTransparent, defaults.captureTransparent)
        captureShadow = container.value(.captureShadow, defaults.captureShadow)
        captureClientArea = container.value(.captureClientArea, defaults.captureClientArea)
        ffmpegOptions = container.value(.ffmpegOptions, defaults.ffmpegOptions)
        screenRecordFPS = container.value(.screenRecordFPS, defaults.screenRecordFPS)
        gifFPS = container.value(.gifFPS, defaults.gifFPS)
        screenRecordShowCursor = container.value(.screenRecordShowCursor, defaults.screenRecordShowCursor)
        screenRecordAutoStart = container.value(.screenRecordAutoStart, defaults.screenRecordAutoStart)
        screenRecordStartDelay = container.value(.screenRecordStartDelay, defaults.screenRecordStartDelay)
        screenRecordFixedDuration = container.value(.screenRecordFixedDuration, defaults.screenRecordFixedDuration)
        screenRecordDuration = container.value(.screenRecordDuration, defaults.screenRecordDuration)
        screenRecordAskConfirmationOnAbort = container.value(.screenRecordAskConfirmationOnAbort,
                                                             defaults.screenRecordAskConfirmationOnAbort)
    }
}

/// Task settings › Upload › File naming.
public struct TaskSettingsUpload: Codable, Equatable, Sendable {
    public var nameFormatPattern = "%ra{10}"
    public var nameFormatPatternActiveWindow = "%pn_%ra{10}"
    public var fileUploadUseNamePattern = false
    public var fileUploadReplaceProblematicCharacters = false

    public init() {}

    enum CodingKeys: String, CodingKey {
        case nameFormatPattern = "NameFormatPattern"
        case nameFormatPatternActiveWindow = "NameFormatPatternActiveWindow"
        case fileUploadUseNamePattern = "FileUploadUseNamePattern"
        case fileUploadReplaceProblematicCharacters = "FileUploadReplaceProblematicCharacters"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TaskSettingsUpload()
        nameFormatPattern = container.value(.nameFormatPattern, defaults.nameFormatPattern)
        nameFormatPatternActiveWindow = container.value(.nameFormatPatternActiveWindow, defaults.nameFormatPatternActiveWindow)
        fileUploadUseNamePattern = container.value(.fileUploadUseNamePattern, defaults.fileUploadUseNamePattern)
        fileUploadReplaceProblematicCharacters = container.value(.fileUploadReplaceProblematicCharacters,
                                                                 defaults.fileUploadReplaceProblematicCharacters)
    }
}

# UpLa for Mac – plan

UpLa for Mac is a native macOS menu bar app. For Mac users it does what [UpLa for Windows](https://github.com/Agnostique/UpLa) does: take a screenshot or a screen recording, upload it to [upla.com.tr](https://upla.com.tr) and put the link on the clipboard.

It is **not a port**. UpLa for Windows is built on ShareX (WinForms and Win32 capture, hotkey and GDI+ code), which cannot run on macOS. This app is written from scratch in Swift. It copies the upla.com.tr behaviour of the Windows app, not its code structure.

This file is the shared memory between the Windows and the Mac Claude Code sessions. Update it whenever a decision is made.

## Status

*Updated 2026-10-09.* Version 0.1 is on `main` (merged from `dev` in pull request #1). It was written and tested on the Windows PC only (WSL and GitHub Actions). **It has not run on a Mac yet.** Milestones M0–M3 are done but still have to be tested on a Mac; M4 and M5 are open (see [Milestones](#milestones)).

### Implemented in 0.1

- **UplaKit** (local Swift package, no UI, also builds on Linux):
  - Upload client: extension and size checks, a multipart body streamed from a temporary file, progress and cancelling.
  - Key check, and the mapping of answers and errors to results.
  - Account client (`login`, `me`, `logout`).
  - Album, tag and key rules, limits, device name.
  - The behaviour follows `UplaUploader.cs` and `UplaAccount.cs` of UpLa for Windows.
- **Menu bar app** (AppKit `NSStatusItem` with SwiftUI windows):
  - Region, window and full-screen capture through `screencapture`, and a window that explains the Screen Recording permission.
  - Global hotkeys ⌥⇧⌘3/4/5 (Carbon, no Accessibility permission), with a shortcut recorder in Settings.
  - After-capture actions: upload, copy the image, save to a folder (`~/Pictures/UpLa`).
  - Upload a file, upload from the clipboard, and drop files on the menu bar icon.
  - Uploads one at a time, with the percentage on the menu bar button and Cancel Uploads. The link goes to the clipboard, and a notification opens it.
  - History window: 500 items in `~/Library/Application Support/UpLa/history.json` (0600), with the delete page behind a confirmation.
  - Settings tabs: General, Capture, upla.com.tr, Hotkeys, Account.
  - In-app sign-in with the two-step code; the key in the Keychain; `me` and `logout`; the expired and lost sign-in states; a key entered by hand.
  - Launch at login (`SMAppService`), the About window, and all texts in English and Turkish (String Catalog, 215 texts).
- **From the review of 0.1:**
  - The app asks once before the first upload, like `ShowUploadWarning` on Windows. Turning automatic upload off saves screenshots to the folder instead of uploading them.
  - A screenshot whose upload fails is moved to the save folder instead of being deleted.
  - Request bodies, which contain the key, are written to the app's own temporary folder. It is emptied at launch and at quit.
  - An expired sign-in still uploads, and the server decides, as on Windows. The account is checked when the Account settings open, not at launch.
  - The device name is the Mac model, not the Computer Name.
  - History thumbnails are kept in memory only.
  - The shortcut recorder only reads keys in its own window.
  - Signing is set in `Config/Signing.xcconfig`.
- **After 0.1 (2026-10-09), matching UpLa for Windows 2.0.1/2.0.2:**
  - "Report Abuse" at the end of the account menu opens the contact page.
  - `Upla.profileURL` turns a profile link sent as a path ("/name") into a full URL. The server sent paths until October 2026 (Chevereto's `get_base_url()`), and on Windows "My profile" did nothing because of it.
- **Not done yet:** screen recording (M4); Sparkle updates, the final icon, Developer ID signing, notarization and the DMG (M5).

### Verified on the Windows PC

| Check | Result |
| --- | --- |
| UplaKit unit tests in WSL Ubuntu 24.04 (Swift 6.4, `-strict-concurrency=complete`) | 81 tests, 0 failures, no warnings |
| UplaKit E2E tests against the local Chevereto 4.5.7 test site in WSL (`http://localhost:8090`, with the `upla-app` route) | 5 of 5 passed: sign-in, `me`, key check, member upload (also with tags and a resize width), sign-out, deleted key refused, two-step sign-in, banned account, wrong password, site without the route |
| E2E guard | the tests skip any host other than localhost, 127.0.0.1 and ::1 (allowlist) |
| App sources on Linux | all files parse; the logic that does not need AppKit (account, settings, history, uploads, capture, texts) type-checks against UplaKit with stand-ins for AppKit, Security and similar frameworks |
| String Catalog | 215 keys, each with a Turkish text and the same format specifiers |
| GitHub Actions (`macos-15`, Xcode 16.4, Swift 6.1.2), run [37844671941](https://github.com/Agnostique/UpLa-mac/actions/runs/37844671941) | UplaKit tests passed (86 tests, 5 E2E skipped); the Release build of the app compiles; the app is universal (arm64 x86_64), ad-hoc signed, has `tr.lproj` and `LSUIElement`; the zipped app is the `UpLa-mac` artifact |

### To verify on a real Mac

Use the CI artifact, or a local build, which can be signed with a team.

- [x] **First CI build (done in CI):** XcodeGen treats `Localizable.xcstrings` as a String Catalog, the Release build compiles all the AppKit and SwiftUI files, and "Check the app" lists arm64 x86_64 and a `tr.lproj` folder. This proves only that it compiles. Everything below must be checked by hand.
- [ ] **Start:** the menu bar icon appears and there is no Dock icon (`LSUIElement`). The first launch opens Settings once.
- [ ] **Drop on the icon:** files dropped on the menu bar icon are uploaded. The status bar window is registered for `.fileURL`, and the NSWindow must pass the dragging calls on to its delegate.
- [ ] **Capture:** region, window and full screen work through `screencapture`. Esc writes no file and nothing is reported. Space switches between region and window.
- [ ] **Screen Recording permission:**
  - `CGPreflightScreenCaptureAccess` is false before it is granted.
  - `CGRequestScreenCaptureAccess` adds UpLa to the list.
  - The System Settings link in the permission window opens the right page.
  - Find out whether UpLa must be relaunched after granting.
- [ ] **Hotkeys:**
  - ⌥⇧⌘3/4/5 register and fire without the Accessibility permission.
  - A shortcut taken by another app shows the error in Settings; any other refusal shows macOS's error code.
  - The recorder: Esc cancels, Delete removes, and hotkeys are paused while recording.
  - ⌘C, ⌥X and plain letters are refused with a beep. ⌥⇧⌘ or ⌃⌥ combinations and ⌘F5 are accepted.
  - Typing in the sign-in window or an open panel while a recording is pending is not taken.
  - Recording stops when the Settings window loses focus or UpLa is deactivated.
- [ ] **One capture at a time:** pressing a capture shortcut while the menu is open starts only one capture. The menu key equivalent and the Carbon hotkey can both fire, and the `isCapturing` guard should drop the second.
- [ ] **First upload question:**
  - It appears once, at the first upload, while "Upload to upla.com.tr" is on.
  - "Turn Off Automatic Upload" uploads no screenshot, saves it to `~/Pictures/UpLa`, turns "Save to a folder" on and shows "Screenshot saved". Files chosen by hand are still uploaded.
  - It is never asked again.
- [ ] **Failed uploads:** with Wi-Fi off, a capture upload fails and the screenshot is moved to the save folder; the failure notification names the path. "Cancel Uploads" deletes captures that were not uploaded.
- [ ] **Quitting during an upload:** waiting captures end up in the save folder, and `$TMPDIR/UpLa` (with the request body) is gone.
- [ ] **Notifications:**
  - The permission prompt appears at the first upload.
  - The first "Uploaded" notification is shown after you choose Allow (it waits up to 15 s).
  - Clicking a notification opens the link.
  - When notifications are denied, failures fall back to an alert.
- [ ] **Keychain with an ad-hoc signature:**
  - Saving, reading and deleting the upload key work (`kSecAttrAccessibleAfterFirstUnlock` on the login keychain, retried without it on `errSecParam`).
  - Check the access prompt after each new build.
  - Denying access must show the "lost" state, never a guest upload.
- [ ] **Sign-in against a test site** (Debug build; in the scheme, tick `UPLA_DEBUG_BASE_URL`; only a localhost, LAN or `.local` address is accepted):
  - The two-step code flow works, the password is cleared, and Cancel works.
  - The window's content is hidden from screenshots (`sharingType = .none`).
  - The device name on the Connected devices page is the model, e.g. "MacBook Pro (5f3e9a1c)". On Apple silicon it comes from `IODeviceTree:/product`; on Intel from the `hw.model` family.
  - The test site's sign-in uses its own keychain item (`upload-key-test-site`) and settings, and the real sign-in is untouched afterwards.
  - The WSL test site on the Windows PC is reachable from the Mac only through a port forward (or an SSH tunnel to localhost).
- [ ] **Account check:**
  - Opening Settings › Account sends one `me` request.
  - A Mac removed on the website then shows "This Mac's connection was removed…".
  - Uploads with that key fail with the server's invalid-key message.
- [ ] **Check Key:** with a key entered by hand and an empty field, the saved key is checked, not the guest key.
- [ ] **Launch at login:** works through `SMAppService.mainApp` from `/Applications` with an ad-hoc signed build, including the `requiresApproval` message.
- [ ] **Turkish:** with Turkish as the preferred language every text appears in Turkish (String Catalog compiled with tr; `CFBundleLocalizations` en, tr).
- [ ] **Edit shortcuts:** ⌘V, ⌘C, ⌘A and ⌘W work in the windows through the hidden main menu.
- [ ] **Upload progress:** the percentage on the menu bar button, Cancel Uploads, the serial queue, and the link on the clipboard afterwards.
- [ ] **Upload from Clipboard:** files copied in Finder, image data copied from a browser or Preview, and the "nothing to upload" notice.
- [ ] **Save to a folder:** `~/Pictures/UpLa` is created, and Choose… and Show in Finder work.
- [ ] **History window:**
  - Thumbnails load (https only, in memory; nothing new in `~/Library/Caches/tr.com.upla.UpLa`).
  - Copy Link, Open, the delete page confirmation, Remove and Clear work.
  - `history.json` is written with 0600 permissions.
- [ ] **Settings window:** the fixed 600×540 size (`TabView` in `NSHostingController`), the form layouts, the album and tag fields disabled for guests, and the number fields.
- [ ] **Signing:** with `Config/Signing.xcconfig` (team ID), the Screen Recording permission and the keychain access survive a rebuild and `xcodegen generate`.
- [ ] **App icon:** it looks acceptable. The 512 and 1024 px images are upscaled from the 256 px `.ico` frame (placeholders).
- [ ] **CI zip:** it opens on Apple silicon and on Intel. On macOS 15 and later use Open Anyway in System Settings › Privacy & Security; on 14, right-click › Open. `xattr -dr com.apple.quarantine` also works.

### Decisions so far

- **Language mode:** Swift 5 (`SWIFT_VERSION` 5.0). The app uses minimal concurrency checking; UplaKit is also tested with complete checking.
- **Hotkeys:** the defaults are ⌥⇧⌘3/4/5. A recorded shortcut needs ⌘ or ⌃ plus another modifier (a function key needs only one).
- **Expired sign-in:** uploads still try the key and the server decides (Windows parity). Only a missing keychain key ("lost") stops uploads locally.
- **Account check:** `me` runs only when Settings › Account opens, not at launch (Windows parity, less traffic).
- **CI:** two parallel `macos-15` jobs ("Test UplaKit", "Build the app"), `actions/checkout` and `upload-artifact` v7. Xcode is not pinned: today it is 16.4 with Swift 6.1.2, and it changes when the image default changes. The output is an ad-hoc signed universal app.
- **Guest key:** the CI artifact has the guest key in plain text in `Info.plist`. This is the known exposure, the same as the released Windows binary. Built apps and archives are gitignored.
- **No third-party dependencies in 0.1:** the hotkey recorder is UpLa's own.

## Platform

| Item | Plan |
| --- | --- |
| Minimum macOS | 14 Sonoma (ScreenCaptureKit screenshots, SMAppService); check the user's MacBook first |
| Language | Swift 6 toolchain in Swift 5 language mode, SwiftUI for windows, AppKit where SwiftUI is not enough |
| Architectures | Universal (Apple Silicon + Intel) |
| Project | XcodeGen: `project.yml` is in git, `UpLa.xcodeproj` is generated and not kept in git |
| Bundle ID | `tr.com.upla.UpLa` |
| Localization | Turkish and English in a String Catalog. Port the texts from `ShareX.HelpersLib/Upla/UplaStrings.cs` (112 TR/EN pairs) |
| Dependencies | None in 0.1. [Sparkle 2](https://sparkle-project.org) for updates in M5 |

## Features

### Version 1.0

**1. Menu bar item** (AppKit `NSStatusItem`, not `MenuBarExtra`, because the icon must accept dropped files and show upload progress):

- Capture region, Capture window, Capture full screen
- Start/stop screen recording
- Upload file…, Upload from clipboard
- Recent uploads ▸
- upla.com.tr account ▸
- Settings…, Check for updates…, Quit

**2. Global hotkeys:**

- Configurable.
- Registered with Carbon `RegisterEventHotKey`, which needs no Accessibility permission.
- The defaults must not clash with macOS's ⌘⇧3/4/5. A suggestion to verify is ⌥⇧⌘3 / ⌥⇧⌘4 / ⌥⇧⌘5.

**3. Screenshots:**

- Region and window capture can first use the system tool: `/usr/sbin/screencapture -i -x -o <file>.png`. Space toggles window mode, Esc cancels and then no file is written. It gives the native selection UI on every display.
- Full screen uses `screencapture -x` or `SCScreenshotManager`.
- An own overlay (magnifier, colour picker) can come later.
- Screen Recording permission: check with `CGPreflightScreenCaptureAccess()`, request with `CGRequestScreenCaptureAccess()`. A first-run window explains the permission and opens System Settings.

**4. Screen recording:**

- ScreenCaptureKit (`SCStream`) feeds `AVAssetWriter`, which writes MP4 (H.264, HEVC as an option). System audio is optional.
- Region, window or full screen; a stop button and elapsed time/size are shown in the menu bar.
- **Stop at the upload limit**, as on Windows (the setting is on by default):
  - Count the bytes written and stop at the recording limit, then upload. A notification says that the recording was stopped at the limit.
  - Guests stop at 18 MiB (18,874,368 bytes), members at 95,000,000 bytes.
  - Formula: `limit - max(2 MiB, 5% of limit)`.

**5. Upload** (see [upla.com.tr API](#uplacomtr-api)):

- Works as a guest or with the member's key.
- Checks extension and size before sending.
- Shows progress and can be cancelled.

**6. After upload:**

- Copy the link to the clipboard.
- Show a notification (`UNUserNotificationCenter`); clicking it opens the link.
- Add an entry to the history.

**7. After-capture actions** (settings):

- Upload (default)
- Save to a folder
- Copy the image to the clipboard
- Later: open in the editor

**8. Account:**

- In-app sign-in: username or e-mail, password, and a two-step code when asked.
- Shows the signed-in name; sign out; link to "Connected devices".
- An expired key leads to "Sign in again".
- Advanced: a key entered by hand from https://upla.com.tr/settings/api.

**9. History window:**

- Thumbnail, link, date and the delete link.
- Copy, open, and remove from the history.
- Stored in Application Support.
- The delete link lets anyone delete the file: keep it local and never log it.

**10. Settings window:**

| Tab | Contents |
| --- | --- |
| General | launch at login via `SMAppService.mainApp` |
| Hotkeys | |
| Capture | format, Retina 1x downscale |
| Recording | stop at the upload limit |
| upla.com.tr | link type, album, tags, expiration, category ID, max width |
| Account | |
| Updates | |

**11. Updates:** Sparkle 2 (EdDSA-signed appcast) from GitHub Releases. Check once a day (`SUScheduledCheckInterval` 86400), like the Windows app.

**12. Privacy:** no telemetry. The app talks only to upla.com.tr and the update feed.

### Later (1.1+)

- Annotation editor: arrow, rectangle, text, highlight, blur/pixelate, crop.
- Text recognition with Vision (`VNRecognizeTextRequest`), copied to the clipboard.
- GIF export of recordings, and a microphone track.
- Own capture overlay.
- Finder Services / Share extension ("Upload to upla.com.tr").

### Not planned

- ShareX's other destinations, custom uploaders, workflows and tools.
- The NSFW flag: since 2026-10-08 the terms of use prohibit adult content.

## upla.com.tr API

upla.com.tr runs Chevereto 4.5.7. The reference implementation is in the Windows repo, under `ShareX.UploadersLib/Upla/`:

| File | Contents |
| --- | --- |
| `Upla.cs` | constants, limits, album/tag rules |
| `UplaUploader.cs` | upload and response/error parsing |
| `UplaAccount.cs` | sign-in client |
| `Server/chevereto/app/legacy/routes/overrides/upla-app.php` | the server side of the sign-in |

### Upload

`POST https://upla.com.tr/api/1/upload`, `multipart/form-data`, header `X-API-Key: <key>`.

| Field | Value |
| --- | --- |
| `source` | the file |
| `key` | the same key again (for proxies that drop custom headers) |
| `format` | `json` |
| `album_id` | members only; accepts an album link (`https://upla.com.tr/album/Name.AbCd`) or the ID. Parse: drop `?…`/`#…` and a trailing `/`, take the last path segment, then the part after its last `.` |
| `tags` | members only; comma separated; remove `/` and `#`, trim, at most 32 characters each, no duplicates (case-insensitive) |
| `category_id` | only when > 0 |
| `expiration` | only one of `PT5M PT15M PT30M PT1H PT3H PT6H PT12H P1D P2D P3D P4D P5D P6D P1W P2W P3W P1M P2M P3M P4M P5M P6M P1Y` |
| `width` | server-side resize, images only, and **only when the image is wider**, otherwise Chevereto fails with error 610 |

**Success (HTTP 200)** returns `image` with these fields:

- `url_viewer`
- `url` (the direct link)
- `url_short`
- `thumb.url`
- `delete_url`
- `is_approved`

The link type setting picks the preferred link. If it is empty, try `url_viewer`, `url_short`, then `url`. When `is_approved` is false the upload waits for moderation and has only the viewer page link.

**Errors** come as `error.code` and `error.message`. Messages can be translated, so decide by the code:

| Code / case | Meaning |
| --- | --- |
| 100 (or 0 with "API key prefix") | invalid key: for a member the sign-in expired, for a guest uploads are unavailable |
| message contains "no longer supported" | old key format, the member must create a new key |
| 101 | duplicate |
| 130 | empty source, or "flood" (too many uploads) |
| 403 | forbidden |
| 600 | video processing failed |
| 610 | width larger than the image |
| 614 | file type rejected |
| HTTP 413 or "too big" | file too large |
| HTTP 404 | API disabled |
| HTTP ≥ 500 | server error |

**Key check:** a POST with only `format=json&key=…` and no file. 130 means the key is accepted, 100 invalid, 403 cannot upload.

**Limits:**

- Guests: 20 MiB (20,971,520 bytes).
- Members: 100,000,000 bytes (Cloudflare's request body limit).
- Images: `jpg jpeg png bmp gif webp`. Videos: `mp4 webm` (no `mov`; browsers often cannot play it).

### In-app sign-in (already live on the server)

`POST https://upla.com.tr/upla-app/{login|me|logout}`, `application/x-www-form-urlencoded`, header `X-Upla-App: 1`. `me` and `logout` also send `X-API-Key`. Requests time out after 30 s.

**`login` fields:**

- `login-subject`: username or e-mail, trimmed.
- `password`
- `device`: shown on the website's Connected devices page, e.g. `MacBook Pro (5f3e9a1c)` = the Mac model + the first 8 hex digits of a random per-install ID. Not the Computer Name: macOS builds that from the owner's name, and the server stores the device name.
- `two-factor-code`: digits only, when asked.

**Success (HTTP 200):**

- `{ "api_key": "...", "user": { "username": "...", "name": "...", "url": "..." } }`
- `login` must return `api_key` and `username`; `me` must return `username`.
- `logout` deletes this device's key on the server. The app forgets the key whatever the result.

**JSON errors** come as `{ "error": { "code", "message" }, "retry_after"? }`. Codes:

- `two_factor_required`
- `invalid_credentials`, `missing_fields`
- `invalid_two_factor_code`
- `too_many_attempts` (`retry_after` seconds or the `Retry-After` header)
- `account_banned`, `account_awaiting_confirmation`, `account_awaiting_email`, `account_not_valid`
- `invalid_key`
- `api_disabled`

**Non-JSON answers:**

| Answer | Meaning |
| --- | --- |
| 404/405 | the route is missing |
| 403 | Chevereto's daily lockout of an IP after failed attempts, or a Cloudflare block |
| 429 | Cloudflare rate limit (`Retry-After`) |
| 2xx HTML | maintenance, consent or private-mode page |

**Rules:**

- An account can have at most 10 device keys.
- The password is sent only over HTTPS, never stored, never logged.
- The device key goes to the **Keychain** (generic password, service = bundle ID).
- If an account is remembered but its key is missing, say so. Never silently upload as a guest instead.

**Other links:**

- Sign-up: https://upla.com.tr/signup
- Password reset: https://upla.com.tr/account/password-forgot
- Connected devices: https://upla.com.tr/upla-app/devices

### Guest key

The shared guest API key is **not in any repository**:

- **Windows:** the key lives in `APIKeysLocal.cs`, filled from the Actions secret `API_KEYS_LOCAL`.
- **Mac:** use `Config/Secrets.xcconfig` (gitignored, copy of `Config/Secrets.example.xcconfig`), with `UPLA_GUEST_API_KEY` passed through Info.plist. CI writes the file from a repository secret.
- The user provides the key. Never print it in logs, chat or commits.

## Architecture

| Part | Contents |
| --- | --- |
| `UpLa` app target | `AppDelegate` with the `NSStatusItem`; SwiftUI windows (settings, sign-in, history, onboarding) |
| `UplaKit` (local Swift package, no UI) | upload client and account client (async/await `URLSession`; multipart body written to a temp file and sent with `uploadTask(with:fromFile:)` so 100 MB videos do not sit in memory; progress via the task delegate), models, error mapping, album/tag rules, size limits |
| `Capture` | `screencapture` wrapper, ScreenCaptureKit screenshots, permission checks |
| `Recorder` | `SCStream` + `AVAssetWriter`, size-limit stop |
| Support | `Hotkeys`, `History`, `Settings` (UserDefaults), `Keychain`, `Updater` (Sparkle) |

**Tests:**

- XCTest for `UplaKit`, using `URLProtocol` stubs with JSON fixtures taken from the Windows parsers' cases, and a loopback server for real transfers.
- E2E tests (`UPLA_E2E_BASE_URL`, `UPLA_E2E_CREDS`) run only against a test site on localhost.
- No real upload, sign-in or other POST to upla.com.tr without the user's approval.

## Build, signing, distribution

**Development:** Xcode with the user's free Apple ID ("Personal Team"). A stable signature keeps the Screen Recording permission between builds; ad-hoc builds lose it after every rebuild. Put the team ID into `Config/Signing.xcconfig` (gitignored, copied from `Config/Signing.example.xcconfig`): a team chosen only in Xcode is lost at the next `xcodegen generate`. Without that file the build is ad-hoc signed, like CI.

**Release** needs the Apple Developer Program ($99/year):

- Developer ID Application certificate, hardened runtime, notarization with `notarytool`, stapled DMG.
- A GitHub Actions macOS runner builds, signs and notarizes. It is free for public repositories.
- Repository secrets: certificate `.p12` + password, App Store Connect API key, Sparkle EdDSA key, guest key.
- Releases: DMG and appcast on GitHub Releases.

**Website:**

- Add the macOS download to https://upla.com.tr/page/ekran-goruntusu.
- Extend section 9 of https://upla.com.tr/page/privacy to cover the Mac app.
- Both are server changes, so they need the user's approval.

## Milestones

| | Goal | Done when | Status |
| --- | --- | --- | --- |
| M0 | Scaffold | project builds in Xcode and in CI (unsigned), menu bar icon and empty settings window, TR/EN String Catalog | Done in CI; still to test on a Mac |
| M1 | Upload core | `UplaKit` with tests; upload via dialog and drag & drop; clipboard, notification, history | Done (UplaKit tested in WSL, E2E and CI); still to test on a Mac |
| M2 | Capture | permission onboarding; region/window/full screen; hotkeys; after-capture actions | Done; still to test on a Mac |
| M3 | Account | sign-in window with two-step code, Keychain, `me`/`logout`, expired key handling; album, tags, expiration, link type | Done (sign-in tested E2E against the local test site); still to test on a Mac |
| M4 | Recording | MP4 recording with the size-limit stop and upload | Open |
| M5 | Release 1.0 | app icon, launch at login, Sparkle, signing + notarization, DMG, README with screenshots, website link | Open (launch at login is already in 0.1) |
| 1.1 | Extras | editor, text recognition, GIF | Open |

## Open questions for the user

1. The macOS version of the MacBook (sets the minimum version).
2. The original UpLa logo as a vector or at least 1024 px for the app icon. The largest we have is the 256 px frame in `design/upla-icon.ico`.
3. Default hotkeys: 0.1 uses ⌥⇧⌘3/4/5. Confirm them on the Mac.
4. When to join the Apple Developer Program (needed for M5, not before).

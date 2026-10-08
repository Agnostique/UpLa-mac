# UpLa for Mac – plan

UpLa for Mac is a native macOS menu bar app. For Mac users it does what [UpLa for Windows](https://github.com/Agnostique/UpLa) does: take a screenshot or a screen recording, upload it to [upla.com.tr](https://upla.com.tr) and put the link on the clipboard.

It is **not a port**. UpLa for Windows is built on ShareX (WinForms and Win32 capture, hotkey and GDI+ code), which cannot run on macOS. This app is written from scratch in Swift. It copies the upla.com.tr behaviour of the Windows app, not its code structure.

This file is the shared memory between the Windows and the Mac Claude Code sessions. Update it whenever a decision is made.

## Platform

| Item | Plan |
| --- | --- |
| Minimum macOS | 14 Sonoma (ScreenCaptureKit screenshots, SMAppService); check the user's MacBook first |
| Language | Swift 6, SwiftUI for windows, AppKit where SwiftUI is not enough |
| Architectures | Universal (Apple Silicon + Intel) |
| Project | Xcode project; generating it with XcodeGen (`project.yml` in git) is preferred so the project file stays reviewable |
| Bundle ID | `tr.com.upla.UpLa` (to confirm) |
| Localization | Turkish and English in a String Catalog. Port the texts from `ShareX.HelpersLib/Upla/UplaStrings.cs` (112 TR/EN pairs) |
| Dependencies | Keep few: [Sparkle 2](https://sparkle-project.org) for updates; optionally [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (MIT) for hotkey recording |

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
- `device`: shown on the website's Connected devices page, e.g. `MacBook-Pro (5f3e9a1c)` = computer name + the first 8 hex digits of a random per-install ID.
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

- XCTest for `UplaKit`, using `URLProtocol` stubs with JSON fixtures taken from the Windows parsers' cases.
- No real upload, sign-in or other POST to upla.com.tr without the user's approval.

## Build, signing, distribution

**Development:** Xcode with the user's free Apple ID ("Personal Team"). A stable signature keeps the Screen Recording permission between builds; ad-hoc builds lose it after every rebuild.

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

| | Goal | Done when |
| --- | --- | --- |
| M0 | Scaffold | project builds in Xcode and in CI (unsigned), menu bar icon and empty settings window, TR/EN String Catalog |
| M1 | Upload core | `UplaKit` with tests; upload via dialog and drag & drop; clipboard, notification, history |
| M2 | Capture | permission onboarding; region/window/full screen; hotkeys; after-capture actions |
| M3 | Account | sign-in window with two-step code, Keychain, `me`/`logout`, expired key handling; album, tags, expiration, link type |
| M4 | Recording | MP4 recording with the size-limit stop and upload |
| M5 | Release 1.0 | app icon, launch at login, Sparkle, signing + notarization, DMG, README with screenshots, website link |
| 1.1 | Extras | editor, text recognition, GIF |

## Open questions for the user

1. The macOS version of the MacBook (sets the minimum version).
2. The original UpLa logo as a vector or at least 1024 px for the app icon. The largest we have is the 256 px frame in `design/upla-icon.ico`.
3. Default hotkeys.
4. When to join the Apple Developer Program (needed for M5, not before).

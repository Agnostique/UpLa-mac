import AppKit
import Security
import SwiftUI
import UplaKit

// Account status, sign in/out, and the advanced option of a key entered by hand.
@MainActor
struct AccountSettingsView: View {
    let app: AppController
    @ObservedObject var account: AccountStore

    @State private var manualKey = ""
    @State private var showsKey = false
    @State private var showsManualKey = false
    @State private var keyMessage: String? = nil
    @State private var isChecking = false

    init(app: AppController, account: AccountStore) {
        self.app = app
        _account = ObservedObject(wrappedValue: account)
    }

    var body: some View {
        Form {
            Section {
                Text(verbatim: statusText)
                    .fixedSize(horizontal: false, vertical: true)
                accountButtons
                accountLinks
            } header: {
                Text("upla.com.tr Account")
            }

            if account.state == .guest || account.state == .manualKey {
                Section {
                    DisclosureGroup("Enter an API key by hand (advanced)", isExpanded: $showsManualKey) {
                        manualKeyControls
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            showsManualKey = account.state == .manualKey

            // Like UpLa for Windows when its settings open: updates the name and notices a Mac removed on the website.
            Task {
                await account.refresh()
            }
        }
    }

    private var statusText: String {
        switch account.state {
        case .guest:
            return String(localized: "You upload as a guest; files are not linked to an account. Sign in to upload to your account.")
        case .signedIn:
            return String(localized: "Signed in as \(account.displayName). Files are uploaded to your account.")
        case .expired:
            return UplaText.deviceSignedOutText
        case .lost:
            if account.username.isEmpty {
                return String(localized: "The saved API key could not be read from this Mac's keychain. Sign in again or continue as a guest.")
            }
            return String(localized: "The sign-in of \(account.username) could not be read from this Mac's keychain. Sign in again or continue as a guest.")
        case .manualKey:
            return String(localized: "Using an API key entered by hand; files are uploaded to the account that owns the key.")
        }
    }

    @ViewBuilder
    private var accountButtons: some View {
        HStack {
            switch account.state {
            case .guest:
                Button("Sign In…") {
                    app.showSignIn()
                }
            case .signedIn:
                Button("Sign Out") {
                    app.signOut()
                }
            case .expired:
                Button("Sign In Again…") {
                    app.showSignIn()
                }
                Button("Sign Out") {
                    app.signOut()
                }
            case .lost:
                Button("Sign In Again…") {
                    app.showSignIn()
                }
                Button("Continue as Guest") {
                    account.clear()
                }
            case .manualKey:
                Button("Sign In…") {
                    app.showSignIn()
                }
                Button("Remove Key…") {
                    app.signOut()
                }
            }
        }
    }

    @ViewBuilder
    private var accountLinks: some View {
        HStack(spacing: 16) {
            if account.state == .guest {
                Link("Create Account", destination: Upla.signUpURL)
            }

            if account.state == .signedIn, let profile = Upla.profileURL(account.profileURL, site: AppEnvironment.baseURL) {
                Link("My Profile", destination: profile)
            }

            if account.state != .guest {
                Link("Connected Devices", destination: Upla.connectedDevicesURL)
            }
        }
    }

    @ViewBuilder
    private var manualKeyControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showsKey {
                    TextField("API key:", text: $manualKey)
                } else {
                    SecureField("API key:", text: $manualKey)
                }
                Toggle("Show", isOn: $showsKey)
            }

            HStack {
                Button("Use This Key") {
                    useKey()
                }
                .disabled(Upla.normalizeAPIKey(manualKey).isEmpty)

                Button("Check Key") {
                    checkKey()
                }
                .disabled(isChecking)

                Link("Get Key", destination: Upla.connectedDevicesURL)
            }

            if let keyMessage {
                Text(verbatim: keyMessage)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Hint("Only needed if you cannot sign in from the app. Get a key with \"Create a new API key\" on the \"Connected devices\" page. \"Regen key\" on Settings › API deletes the newest key, which may be the connection of another computer you signed in on.")

            if account.state == .manualKey {
                Hint("An empty field checks the saved key.")
            } else {
                Hint("An empty field checks the guest upload.")
            }
        }
        .padding(.top, 4)
    }

    private func useKey() {
        let status = account.useManualKey(manualKey)

        if status == errSecSuccess {
            manualKey = ""
            keyMessage = String(localized: "The key was saved. Files are uploaded to the account that owns the key.")
        } else if status == errSecParam {
            keyMessage = String(localized: "Enter a key first.")
        } else {
            keyMessage = UplaText.keychainText(status)
        }
    }

    // Sends a request without a file: Chevereto checks the key before the file. An empty field checks the key in use,
    // like the key box of UpLa for Windows: the saved key entered by hand, otherwise the guest key.
    private func checkKey() {
        let typed = Upla.normalizeAPIKey(manualKey)
        let savedKey = account.state == .manualKey ? (account.memberKey ?? "") : ""
        let memberKey = typed.isEmpty ? savedKey : typed
        let isMember = !memberKey.isEmpty
        let key = isMember ? memberKey : AppEnvironment.guestAPIKey

        guard !key.isEmpty else {
            keyMessage = UplaText.noGuestKeyText
            return
        }

        isChecking = true
        keyMessage = String(localized: "Verifying…")

        Task { @MainActor in
            let status = await UplaClient(apiKey: key, isMember: isMember, baseURL: AppEnvironment.baseURL).checkKey()
            keyMessage = UplaText.keyStatus(status, isMember: isMember)
            isChecking = false
        }
    }
}

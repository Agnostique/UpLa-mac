import AppKit
import Combine
import SwiftUI
import UplaKit

enum SignInField: Hashable {
    case loginSubject
    case password
    case code
}

// State of the sign-in window. The password lives only here: it is sent to upla.com.tr and cleared after the attempt
// (kept only while the two-step code is asked, because the code is sent together with it).
@MainActor
final class SignInModel: ObservableObject {
    @Published var loginSubject: String
    @Published var password = ""
    @Published var twoFactorCode = ""
    @Published private(set) var showsTwoFactor = false
    @Published private(set) var message: String
    @Published private(set) var isError = false
    @Published private(set) var isBusy = false
    @Published var focusRequest: SignInField?

    var onFinish: (@MainActor () -> Void)?

    private let account: AccountStore
    private var task: Task<Void, Never>?

    init(account: AccountStore) {
        self.account = account
        loginSubject = account.username
        message = SignInModel.privacyText
    }

    static var privacyText: String {
        String(localized: "Your password is only sent to upla.com.tr and is not stored on this Mac. A separate connection is created in your account for this Mac; you can remove it on the \"Connected devices\" page at upla.com.tr/upla-app/devices. Changing your password does not remove it.")
    }

    func submit() {
        guard !isBusy else {
            return
        }

        let subject = loginSubject.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !subject.isEmpty, !password.isEmpty else {
            show(String(localized: "Enter your username or email and your password."), isError: true)
            return
        }

        let secret = password
        let code: String? = showsTwoFactor ? twoFactorCode : nil
        isBusy = true
        show(String(localized: "Signing in…"), isError: false)

        task = Task {
            let outcome = await self.account.signIn(loginSubject: subject, password: secret, twoFactorCode: code)
            self.finish(outcome)
        }
    }

    // Closing the window abandons a running sign-in.
    func cancel() {
        task?.cancel()
        task = nil
        isBusy = false
        password = ""
        twoFactorCode = ""
    }

    private func finish(_ outcome: SignInOutcome) {
        guard task != nil else {
            // Cancelled meanwhile.
            return
        }

        task = nil
        isBusy = false

        switch outcome {
        case .success:
            password = ""
            twoFactorCode = ""
            onFinish?()
        case .keychainFailed(let status):
            password = ""
            show(UplaText.keychainText(status), isError: true)
        case .failed(let result):
            switch result.status {
            case .cancelled:
                password = ""
                return
            case .twoFactorRequired:
                showsTwoFactor = true
                focusRequest = .code
                show(UplaText.accountStatus(result.status), isError: false)
                return
            case .invalidTwoFactorCode:
                twoFactorCode = ""
                focusRequest = .code
            case .invalidCredentials:
                password = ""
                twoFactorCode = ""
                showsTwoFactor = false
                focusRequest = .password
            default:
                password = ""
                twoFactorCode = ""
            }

            show(UplaText.accountStatus(result.status, retryAfterSeconds: result.retryAfterSeconds), isError: true)
        }
    }

    private func show(_ text: String, isError: Bool) {
        message = text
        self.isError = isError
    }
}

@MainActor
struct SignInView: View {
    @ObservedObject var model: SignInModel
    @FocusState private var focus: SignInField?

    init(model: SignInModel) {
        _model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Form {
                TextField("Username or email:", text: $model.loginSubject)
                    .textContentType(.username)
                    .focused($focus, equals: .loginSubject)
                SecureField("Password:", text: $model.password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)

                if model.showsTwoFactor {
                    TextField("Verification code:", text: $model.twoFactorCode)
                        .textContentType(.oneTimeCode)
                        .focused($focus, equals: .code)
                }
            }
            .disabled(model.isBusy)

            Text(verbatim: model.message)
                .foregroundStyle(model.isError ? Color.red : Color.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Link("Forgot password", destination: Upla.passwordForgotURL)
                Link("Create Account", destination: Upla.signUpURL)
                Link("Connected Devices", destination: Upla.connectedDevicesURL)
            }
            .font(.callout)

            HStack {
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()

                Button("Cancel") {
                    model.cancel()
                    model.onFinish?()
                }
                .keyboardShortcut(.cancelAction)

                Button("Sign In") {
                    model.submit()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(model.isBusy)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onAppear {
            focus = model.loginSubject.isEmpty ? .loginSubject : .password
        }
        .onChange(of: model.focusRequest) { _, request in
            if let request {
                focus = request
                model.focusRequest = nil
            }
        }
        .onChange(of: model.twoFactorCode) { _, value in
            // Authenticator codes are digits; spaces from copying are dropped here (the server gets digits only anyway).
            let digits = String(value.filter { $0.isASCII && $0.isNumber }.prefix(10))
            if digits != value {
                model.twoFactorCode = digits
            }
        }
        .onDisappear {
            model.cancel()
        }
    }
}

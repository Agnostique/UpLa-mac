import AppKit
import SwiftUI
import UplaKit

@MainActor
struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text(verbatim: "UpLa")
                .font(.title.bold())

            Text("Version \(AppEnvironment.version) (\(AppEnvironment.build))")
                .foregroundStyle(.secondary)

            Text("UpLa is the screenshot and upload app of upla.com.tr. It is free and open source software, distributed under the GNU General Public License version 3 (GPL v3).")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Link(destination: Upla.websiteURL) {
                    Text(verbatim: "upla.com.tr")
                }
                Link("Source code", destination: Upla.sourceCodeURL)
                Link("License", destination: AppEnvironment.licenseURL)
            }

            Text(verbatim: "Copyright © 2026 upla.com.tr")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
    }
}

import AppKit
import SwiftUI

@MainActor
struct HistoryView: View {
    @ObservedObject var history: HistoryStore
    @State private var pendingDeletion: HistoryItem? = nil
    @State private var showsDeletionAlert = false
    @State private var confirmsClear = false

    init(history: HistoryStore) {
        _history = ObservedObject(wrappedValue: history)
    }

    var body: some View {
        VStack(spacing: 0) {
            if history.items.isEmpty {
                ContentUnavailableView("No uploads yet", systemImage: "tray",
                                       description: Text("Uploaded files and their links appear here."))
            } else {
                List {
                    ForEach(history.items) { item in
                        HistoryRow(item: item)
                            .contextMenu {
                                Button("Copy Link") {
                                    Pasteboard.copy(link: item.url)
                                }
                                Button("Open") {
                                    HistoryView.open(item.url)
                                }
                                if item.deletionURL != nil {
                                    Button("Open Delete Page…") {
                                        pendingDeletion = item
                                        showsDeletionAlert = true
                                    }
                                }
                                Divider()
                                Button("Remove from History") {
                                    history.remove(item)
                                }
                            }
                    }
                }
            }

            Divider()

            HStack {
                Text(verbatim: countText)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear History…") {
                    confirmsClear = true
                }
                .disabled(history.items.isEmpty)
            }
            .padding(10)
        }
        .frame(minWidth: 560, idealWidth: 640, minHeight: 380, idealHeight: 520)
        .alert("Deletion link", isPresented: $showsDeletionAlert, presenting: pendingDeletion) { item in
            Button("Open Delete Page", role: .destructive) {
                HistoryView.open(item.deletionURL)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Opening the deletion link can delete the uploaded file from the server immediately and permanently. Do you want to continue?")
        }
        .confirmationDialog("Clear the upload history?", isPresented: $confirmsClear) {
            Button("Clear History", role: .destructive) {
                history.removeAll()
            }
        } message: {
            Text("The links and deletion links saved on this Mac are removed. The files stay on upla.com.tr.")
        }
    }

    private var countText: String {
        String(localized: "Uploads: \(String(history.items.count))")
    }

    static func open(_ link: String?) {
        if let url = AppEnvironment.webURL(link) {
            NSWorkspace.shared.open(url)
        }
    }
}

@MainActor
struct HistoryRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: AppEnvironment.webURL(item.thumbnailURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: item.isVideo ? "film" : "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56, height: 56)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: item.fileName)
                    .font(.headline)
                    .lineLimit(1)
                Text(verbatim: item.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(item.date, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if item.awaitingModeration {
                    Text("Awaiting moderation")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Button("Copy Link") {
                Pasteboard.copy(link: item.url)
            }
            Button("Open") {
                HistoryView.open(item.url)
            }
        }
        .padding(.vertical, 4)
    }
}

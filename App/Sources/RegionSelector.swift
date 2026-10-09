import AppKit
import Carbon

// The area to record: a dimmed overlay on one screen. Drag to select an area, or click to take the whole screen; Esc
// or a right click cancels.
@MainActor
final class RegionSelector {
    private var panel: NSPanel?
    // The app that was in front before the overlay; it gets the focus back, since that is usually what is recorded.
    private var previousApp: NSRunningApplication?

    // completion gets the selection in screen coordinates (AppKit's, origin at the bottom left), or nil when cancelled.
    func select(on screen: NSScreen, completion: @escaping @MainActor (CGRect?) -> Void) {
        dismiss()

        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApp = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : frontmost

        let panel = RegionPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
        panel.setFrame(screen.frame, display: false)
        // Above the menu bar and the Dock, on every space, including full screen apps.
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // A panel hides when its app is not active; UpLa may not become active before the user drags.
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let view = RegionSelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onFinish = { [weak self] selection in
            self?.dismiss()
            completion(selection)
        }
        panel.contentView = view
        self.panel = panel

        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        _ = panel.makeFirstResponder(view)
    }

    // Closes the overlay without answering.
    func dismiss() {
        guard let panel else {
            return
        }

        self.panel = nil
        panel.orderOut(nil)
        panel.close()

        if let previousApp {
            self.previousApp = nil
            _ = previousApp.activate(options: [])
        }
    }
}

// Borderless panels cannot become key by default; the overlay must, to receive Esc.
private final class RegionPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }
}

private final class RegionSelectionView: NSView {
    // The selection in screen coordinates, or nil when cancelled. Called once.
    var onFinish: (@MainActor (CGRect?) -> Void)?

    // Smaller drags count as a click, which takes the whole screen.
    private static let minimumSize: CGFloat = 8

    private var startPoint: NSPoint?
    private var selection: NSRect?

    override var acceptsFirstResponder: Bool {
        true
    }

    // The first click selects even while UpLa is not the active app.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        selection = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint else {
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        let rect = NSRect(x: min(startPoint.x, point.x), y: min(startPoint.y, point.y),
                          width: abs(point.x - startPoint.x), height: abs(point.y - startPoint.y))
        selection = rect.intersection(bounds)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard startPoint != nil else {
            return
        }

        startPoint = nil

        if let selection, selection.width >= Self.minimumSize, selection.height >= Self.minimumSize {
            finish(selection)
        } else {
            finish(bounds)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        cancel()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            cancel()
        } else {
            super.keyDown(with: event)
        }
    }

    private func cancel() {
        let handler = onFinish
        onFinish = nil
        handler?(nil)
    }

    private func finish(_ rect: NSRect) {
        guard let window else {
            cancel()
            return
        }

        let handler = onFinish
        onFinish = nil
        handler?(window.convertToScreen(convert(rect, to: nil)))
    }

    override func draw(_ dirtyRect: NSRect) {
        // Everything but the selection is dimmed.
        let dimmed = NSBezierPath(rect: bounds)

        if let selection {
            dimmed.append(NSBezierPath(rect: selection))
            dimmed.windingRule = .evenOdd
        }

        NSColor.black.withAlphaComponent(0.35).setFill()
        dimmed.fill()

        guard let selection else {
            drawBadge(String(localized: "Drag to select the area to record, or click to record the whole screen. Press Esc to cancel."),
                      center: NSPoint(x: bounds.midX, y: bounds.midY))
            return
        }

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        // The size in pixels, under the selection.
        let scale = window?.backingScaleFactor ?? 1
        let width = String(Int((selection.width * scale).rounded()))
        let height = String(Int((selection.height * scale).rounded()))
        drawBadge("\(width) × \(height)", center: NSPoint(x: selection.midX, y: selection.minY - 20))
    }

    // White text on a dark rounded box, kept inside the screen.
    private func drawBadge(_ text: String, center: NSPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let size = string.size()
        let width = size.width + 24
        let height = size.height + 12
        let x = min(max(center.x - width / 2, bounds.minX + 8), bounds.maxX - width - 8)
        let y = min(max(center.y - height / 2, bounds.minY + 8), bounds.maxY - height - 8)
        let box = NSRect(x: x, y: y, width: width, height: height)

        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: box, xRadius: 8, yRadius: 8).fill()
        string.draw(at: NSPoint(x: box.minX + 12, y: box.minY + 6))
    }
}

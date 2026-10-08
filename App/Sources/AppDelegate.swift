import AppKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set before anything is posted, so clicks on earlier notifications open their links too.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NSApp.mainMenu = makeMainMenu()

        let controller = AppController()
        self.controller = controller
        controller.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.prepareForQuit()
    }

    // Opening the app again (e.g. from Finder) shows the settings, since a menu bar app has no window of its own.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            controller?.showSettings()
        }
        return true
    }

    @objc func showSettings(_ sender: Any?) {
        controller?.showSettings()
    }

    @objc func showAbout(_ sender: Any?) {
        controller?.showAbout()
    }

    // The menu bar is hidden for this app, but its key equivalents (copy, paste, close...) still work in the windows,
    // e.g. pasting a key into a text field.
    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenu = NSMenu(title: "UpLa")
        let about = appMenu.addItem(withTitle: String(localized: "About UpLa"), action: #selector(showAbout(_:)), keyEquivalent: "")
        about.target = self
        appMenu.addItem(.separator())
        let settings = appMenu.addItem(withTitle: String(localized: "Settings…"), action: #selector(showSettings(_:)), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: String(localized: "Quit UpLa"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        addSubmenu(appMenu, to: mainMenu)

        let editMenu = NSMenu(title: String(localized: "Edit"))
        editMenu.addItem(withTitle: String(localized: "Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: String(localized: "Redo"), action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: String(localized: "Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: String(localized: "Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: String(localized: "Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: String(localized: "Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        addSubmenu(editMenu, to: mainMenu)

        let windowMenu = NSMenu(title: String(localized: "Window"))
        windowMenu.addItem(withTitle: String(localized: "Close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: String(localized: "Minimize"), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        addSubmenu(windowMenu, to: mainMenu)

        return mainMenu
    }

    private func addSubmenu(_ submenu: NSMenu, to menu: NSMenu) {
        let item = NSMenuItem(title: submenu.title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        menu.addItem(item)
    }
}

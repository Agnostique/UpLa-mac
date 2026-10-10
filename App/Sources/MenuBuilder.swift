import AppKit
import UplaKit

// Runs what a menu item made from MenuSpec asks for.
@MainActor
protocol MenuActionHandler: AnyObject {
    func perform(_ command: MenuCommand)
    // A check item was clicked; MenuSpec.applying gives the new settings.
    func toggle(_ check: MenuCheck)
    // The items of a list that changes (windows, recent links, account…); nil or none hides it. Asked while the menu
    // is built, so the owner rebuilds the menu with fill(_:with:) from menuNeedsUpdate(_:) to keep the lists current.
    func items(for menu: DynamicMenu) -> [NSMenuItem]?
    // A title that depends on the state (the account button shows the user name); nil keeps the spec's title.
    func title(for menu: DynamicMenu) -> String?
}

// Turns MenuSpec into NSMenu items: the Windows titles through the String Catalog, Fugue icons, check marks read from
// the task settings, the hotkeys' shortcuts, and only the items the Mac can run (decision 10). The main window, the
// menu bar menu and the app menu use it, so they show the same items. A menu is a snapshot of the state when it was
// built: its owner calls fill(_:with:) from menuNeedsUpdate(_:) so checks, titles and dynamic lists are current.
@MainActor
final class MenuBuilder: NSObject {
    struct State {
        var taskSettings: TaskSettings
        var hotkeys: HotkeysConfig
        var hotkeysDisabled: Bool
        // Test builds may show planned items, greyed out.
        var includesPlanned = false
    }

    weak var handler: MenuActionHandler?
    private let state: @MainActor () -> State

    init(handler: MenuActionHandler?, state: @escaping @MainActor () -> State) {
        self.handler = handler
        self.state = state
        super.init()
    }

    func makeMenu(_ items: [MenuItem], title: String = "") -> NSMenu {
        let menu = NSMenu(title: title)
        add(items, to: menu)
        return menu
    }

    // Replaces the items of an existing menu, e.g. in menuNeedsUpdate.
    func fill(_ menu: NSMenu, with items: [MenuItem]) {
        menu.removeAllItems()
        add(items, to: menu)
    }

    private func add(_ items: [MenuItem], to menu: NSMenu) {
        let current = state()
        menu.autoenablesItems = false

        for item in MenuSpec.visibleItems(items, includePlanned: current.includesPlanned) {
            if let menuItem = makeItem(item, state: current) {
                menu.addItem(menuItem)
            }
        }
    }

    private func makeItem(_ item: MenuItem, state: State) -> NSMenuItem? {
        if item.isSeparator {
            return .separator()
        }

        let alternate = item.alternateTitle != nil && state.hotkeysDisabled
        let menuItem = NSMenuItem(title: title(of: item, state: state, alternate: alternate), action: nil, keyEquivalent: "")
        menuItem.image = image(alternate ? (item.alternateIcon ?? item.icon) : item.icon)
        menuItem.isEnabled = item.availability.isAvailable

        if let check = item.check {
            menuItem.state = MenuSpec.isChecked(check, in: state.taskSettings) ? .on : .off
        }

        switch item.kind {
        case .command(let command):
            menuItem.target = self
            menuItem.action = #selector(performCommand(_:))
            menuItem.representedObject = command.rawValue
        case .toggle:
            menuItem.target = self
            menuItem.action = #selector(performToggle(_:))
            menuItem.representedObject = item.check
        case .submenu(let children):
            // The children are already filtered by MenuSpec.visibleItems.
            let submenu = NSMenu(title: menuItem.title)
            submenu.autoenablesItems = false

            for child in children {
                if let childItem = makeItem(child, state: state) {
                    submenu.addItem(childItem)
                }
            }

            menuItem.submenu = submenu
        case .dynamic(let kind):
            guard let children = handler?.items(for: kind), !children.isEmpty else {
                return nil
            }

            let submenu = NSMenu(title: menuItem.title)
            submenu.autoenablesItems = false

            for child in children {
                submenu.addItem(child)
            }

            menuItem.submenu = submenu

            if let title = handler?.title(for: kind) {
                menuItem.title = title
            }
        case .separator:
            return .separator()
        }

        if let job = item.shortcut {
            showShortcut(of: job, on: menuItem, hotkeys: state.hotkeys)
        }

        return menuItem
    }

    // The Windows English text is the catalog key (MenuText.catalogKey adds "…" and "%@"). A title with "{0}" is a
    // format, read with localizedString so no arguments are expected while looking it up.
    private func title(of item: MenuItem, state: State, alternate: Bool) -> String {
        let key = MenuText.catalogKey(of: item, alternate: alternate)

        guard let argument = item.titleArgument else {
            return String(localized: String.LocalizationValue(key))
        }

        let format = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, MenuSpec.titleArgumentText(argument, in: state.taskSettings))
    }

    // Fugue icons are in the asset catalog's "Fugue" folder; a missing one leaves the item without an icon.
    private func image(_ icon: MenuIcon?) -> NSImage? {
        switch icon {
        case .fugue(let name)?:
            return NSImage(named: "Fugue/" + name)
        case .appLogo?:
            guard let logo = NSApp.applicationIconImage?.copy() as? NSImage else {
                return nil
            }

            logo.size = NSSize(width: 16, height: 16)
            return logo
        case nil:
            return nil
        }
    }

    // For reference only, like the 0.1 menu: the Carbon hotkey does the work.
    private func showShortcut(of job: HotkeyType, on menuItem: NSMenuItem, hotkeys: HotkeysConfig) {
        guard let info = hotkeys.hotkeys.first(where: { $0.taskSettings.job == job })?.hotkeyInfo,
              let keyCode = info.keyCode else {
            return
        }

        let hotKey = HotKey(keyCode: keyCode, modifiers: info.modifiers, key: info.key)

        if let key = hotKey.menuKeyEquivalent {
            menuItem.keyEquivalent = key
            menuItem.keyEquivalentModifierMask = hotKey.eventModifierFlags
        }
    }

    @objc private func performCommand(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let command = MenuCommand(rawValue: raw) else {
            return
        }

        handler?.perform(command)
    }

    @objc private func performToggle(_ sender: NSMenuItem) {
        guard let check = sender.representedObject as? MenuCheck else {
            return
        }

        handler?.toggle(check)
    }
}

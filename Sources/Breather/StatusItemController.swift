import AppKit
import BreatherCore

final class StatusItemController: NSObject {
    private let item: NSStatusItem

    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    override init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        if let button = item.button {
            button.target = self
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = L10n.t("StatusItemToolTip")
        }
    }

    var button: NSStatusBarButton? { item.button }

    var menu: NSMenu? {
        get { item.menu }
        set { item.menu = newValue }
    }

    @objc private func handleClick() {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
            || NSApp.currentEvent?.modifierFlags.contains(.control) == true

        if isRightClick {
            onRightClick?()
        } else {
            onLeftClick?()
        }
    }

    func update(progress: Double, isPaused: Bool) {
        item.button?.image = StatusIconRenderer.pie(progress: progress, isPaused: isPaused)
    }
}

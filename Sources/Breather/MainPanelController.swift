import AppKit
import BreatherCore

final class MainPanelController {
    private let engine: TimerEngine
    private let preferences: Preferences
    private let panel = MainPanel()
    private let contentView = MainPanelView()

    private let titleLabel = NSTextField(labelWithString: "")
    private let menuButton = NSButton()
    private let slider = AnimalSliderView()
    private let actionButton = NSButton()

    private var globalMonitor: Any?

    var onStateChange: (() -> Void)?
    var onShowMenu: ((NSView) -> Void)?

    init(engine: TimerEngine, preferences: Preferences) {
        self.engine = engine
        self.preferences = preferences
        buildUI()
        wireKeyboard()
        refresh()
    }

    // MARK: - Visibility

    func toggle(relativeTo button: NSStatusBarButton) {
        panel.isVisible ? hide() : show(relativeTo: button)
    }

    func show(relativeTo button: NSStatusBarButton) {
        contentView.applyAppearance(preferences)
        refresh()
        panel.level = preferences.panelAlwaysOnTop ? .floating : .normal
        position(relativeTo: button)
        panel.orderFrontRegardless()
        panel.makeKey()
        installGlobalMonitor()
    }

    /// Demo/diagnostic helper: parks the panel at a fixed spot so a screenshot
    /// always lands on the same pixels.
    func showAtFixedPosition() {
        contentView.applyAppearance(preferences)
        refresh()
        guard let screen = NSScreen.main else { return }
        let size = MainPanel.size
        panel.setFrameOrigin(NSPoint(
            x: screen.visibleFrame.maxX - size.width - 40,
            y: screen.visibleFrame.maxY - size.height - 40
        ))
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        removeGlobalMonitor()
        panel.orderOut(nil)
    }

    // MARK: - Refresh

    func refresh() {
        contentView.applyAppearance(preferences)
        let now = Date()
        let state = engine.state
        let remaining = engine.remaining(at: now)

        titleLabel.stringValue = title(phase: state.phase, remaining: remaining)

        slider.icon = preferences.sliderIcon
        slider.progress = engine.progress(at: now)

        actionButton.title = localized(state.isPaused ? "Resume" : "Pause")
        let inBreakPhase = state.phase == .work || state.phase == .rest
        let blocked = state.phase == .work && preferences.forceBreak
            && remaining <= Double(preferences.popupSecond)
        actionButton.isEnabled = inBreakPhase && !blocked
    }

    private func title(phase: Phase, remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        let mm = total / 60
        let ss = total % 60

        switch phase {
        case .work:
            if total >= 60 * 60 {
                return String(format: localized("Break time in X minutes"), mm)
            }
            return String(format: localized("Break time in X:Y"), mm, ss)
        case .rest, .restEnded:
            if total == 0 {
                return localized("Back to work now!")
            }
            return String(format: localized("Back to work in X:Y"), mm, ss)
        }
    }

    // MARK: - Actions

    @objc private func actionTapped() {
        let now = Date()
        if engine.state.isPaused {
            engine.resume(now: now)
        } else {
            engine.pause(now: now)
        }
        refresh()
        onStateChange?()
    }

    private func sliderChanged(_ value: Double) {
        engine.setProgress(value, now: Date())
        refresh()
        onStateChange?()
    }

    @objc private func menuTapped() {
        onShowMenu?(menuButton)
    }

    func snoozeOnce() {
        engine.snooze(multiplier: 1, now: Date())
        refresh()
        onStateChange?()
    }

    // MARK: - Keyboard

    private func wireKeyboard() {
        panel.onEscape = { [weak self] in self?.hide() }
        if ProcessInfo.processInfo.environment["BREATHER_DEMO"] == nil {
            panel.onResignKey = { [weak self] in self?.hide() }
        }
        panel.onReturn = { [weak self] in self?.actionTapped() }
        panel.onSpace = { [weak self] in
            guard let self, self.engine.snoozeWindowOpen else { return }
            self.snoozeOnce()
        }
    }

    // MARK: - Outside clicks

    private func installGlobalMonitor() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hide()
        }
    }

    private func removeGlobalMonitor() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        globalMonitor = nil
    }

    // MARK: - Layout

    private func position(relativeTo button: NSStatusBarButton) {
        guard let window = button.window else { return }
        let buttonRect = window.convertToScreen(button.convert(button.bounds, to: nil))
        let size = MainPanel.size

        var origin = NSPoint(
            x: buttonRect.midX - size.width / 2,
            y: buttonRect.minY - size.height - 2
        )

        if let screen = window.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - size.width - 4)
            origin.y = max(origin.y, visible.minY + 4)
        }

        panel.setFrameOrigin(origin)
    }

    private func buildUI() {
        contentView.frame = NSRect(origin: .zero, size: MainPanel.size)
        contentView.autoresizingMask = [.width, .height]
        panel.contentView = contentView

        let body = contentView.bounds
        let inset: CGFloat = 14

        titleLabel.frame = NSRect(x: inset, y: body.height - 32, width: body.width - inset * 2 - 26, height: 18)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail

        menuButton.frame = NSRect(x: body.width - 32, y: body.height - 31, width: 20, height: 16)
        menuButton.bezelStyle = .inline
        menuButton.isBordered = false
        menuButton.image = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: nil)
        menuButton.contentTintColor = .secondaryLabelColor
        menuButton.target = self
        menuButton.action = #selector(menuTapped)
        menuButton.refusesFirstResponder = true

        slider.frame = NSRect(x: inset, y: body.height - 58, width: body.width - inset * 2, height: AnimalSliderView.height)
        slider.onDrag = { [weak self] value in self?.sliderChanged(value) }

        let buttonWidth: CGFloat = 96
        actionButton.frame = NSRect(x: (body.width - buttonWidth) / 2, y: 14, width: buttonWidth, height: 22)
        actionButton.bezelStyle = .rounded
        actionButton.font = .systemFont(ofSize: 12)
        actionButton.target = self
        actionButton.action = #selector(actionTapped)
        actionButton.refusesFirstResponder = true

        contentView.addSubview(titleLabel)
        contentView.addSubview(menuButton)
        contentView.addSubview(slider)
        contentView.addSubview(actionButton)
    }

    private func localized(_ key: String) -> String {
        L10n.t(key)
    }
}

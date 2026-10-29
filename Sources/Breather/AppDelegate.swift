import AppKit
import BreatherCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private var engine: TimerEngine!
    private var stats: StatsStore!
    private var ticker: TimerTicker!
    private var statusItemController: StatusItemController!
    private var panelController: MainPanelController!
    private var overlayController: BreakOverlayController!
    private var preferencesWindow: PreferencesWindowController?
    private var aboutWindow: AboutWindowController?
    private var soundPlayer: SoundPlayer!
    private var idleMonitor: IdleMonitor!

    private var idleActive = false
    private var frontmostActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        stats = StatsStore()
        engine = TimerEngine(
            clock: SystemClock(),
            preferences: preferences,
            store: UserDefaultsTimerStateStore()
        )
        soundPlayer = SoundPlayer(preferences: preferences)
        idleMonitor = IdleMonitor(threshold: TimeInterval(preferences.idleMinutes * 60))

        statusItemController = StatusItemController()
        panelController = MainPanelController(engine: engine, preferences: preferences)
        overlayController = BreakOverlayController()

        panelController.onStateChange = { [weak self] in self?.stateChanged() }
        panelController.onShowMenu = { [weak self] anchor in self?.showMenu(from: anchor) }
        overlayController.onDone = { [weak self] in self?.breakOverlayDone() }

        statusItemController.onLeftClick = { [weak self] in
            guard let self, let button = self.statusItemController.button else { return }
            self.panelController.toggle(relativeTo: button)
        }
        statusItemController.onRightClick = { [weak self] in
            self?.showMenuNearStatusItem()
        }

        engine.onPhaseChange = { [weak self] previous, current in
            self?.phaseChanged(from: previous, to: current)
        }

        ticker = TimerTicker(engine: engine)
        ticker.onTick = { [weak self] in self?.tick() }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        if let transition = engine.consumeLaunchTransition() {
            phaseChanged(from: transition.from, to: transition.to)
        }

        syncOverlayWithState()
        stateChanged()
        ticker.start()

        let demo = ProcessInfo.processInfo.environment["BREATHER_DEMO"]
        if demo == "panel" {
            panelController.showAtFixedPosition()
        } else if demo == "prefs" || demo == "save" {
            openPreferences()
        } else if demo == "about" {
            openAbout()
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        engine.persistNow()
        return .terminateNow
    }

    // MARK: - Tick

    private func tick() {
        stats.record(phase: engine.state.phase, isPaused: engine.state.isPaused, at: Date())
        evaluateAutoPause()
        syncOverlayWithState()
        stateChanged()
    }

    /// Idle and frontmost are independent conditions. Pausing happens while any
    /// of them holds; the timer resumes only once none of them does, and never
    /// releases a pause the user made by hand.
    private func evaluateAutoPause() {
        let now = Date()
        idleActive = preferences.pauseWhenIdle && idleMonitor.isIdle
        if preferences.pauseWhenFrontmost, !preferences.frontmostApps.isEmpty {
            let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
            frontmostActive = preferences.frontmostApps.contains(front)
        } else {
            frontmostActive = false
        }

        if idleActive {
            engine.pause(now: now, reason: .idle)
        } else if frontmostActive {
            engine.pause(now: now, reason: .frontmost)
        } else if let reason = engine.state.pauseReason, reason != .manual {
            engine.resume(now: now, reason: reason)
        }
    }

    @objc private func systemDidWake() {
        if preferences.resetWhenWakeup {
            engine.resetToWork(now: Date())
        } else {
            engine.tick(now: Date())
        }
        syncOverlayWithState()
        stateChanged()
    }

    @objc private func activeSpaceChanged() {
        panelController.hide()
    }

    @objc private func screensChanged() {
        guard overlayController.isVisible else { return }
        overlayController.hide()
        syncOverlayWithState()
    }

    @objc private func frontmostChanged() {
        evaluateAutoPause()
        stateChanged()
    }

    // MARK: - State plumbing

    private func phaseChanged(from previous: Phase, to current: Phase) {
        if current == .rest {
            stats.countBreak(at: Date())
            if preferences.ringBellOnBreakStart { soundPlayer.playStart() }
        }
        if (previous == .rest || previous == .restEnded), current == .work {
            if preferences.ringBellOnBreakEnd { soundPlayer.playEnd() }
        }
        syncOverlayWithState()
    }

    private func syncOverlayWithState() {
        let state = engine.state
        let showsOverlay = state.phase == .rest || state.phase == .restEnded

        if showsOverlay {
            if !overlayController.isVisible {
                panelController.hide()
                overlayController.show(
                    remaining: engine.remaining(),
                    forceBreak: preferences.forceBreak,
                    preferences: preferences
                )
            }
            overlayController.refresh(
                remaining: engine.remaining(),
                forceBreak: preferences.forceBreak,
                isBreakOver: state.phase == .restEnded
            )
        } else if overlayController.isVisible {
            overlayController.hide()
        }
    }

    private func stateChanged() {
        statusItemController.update(progress: engine.progress(), isPaused: engine.state.isPaused)
        panelController.refresh()
    }

    private func breakOverlayDone() {
        let now = Date()
        switch engine.state.phase {
        case .rest:
            stats.countCancel(at: now)
            engine.endBreakEarly(now: now)
        case .restEnded:
            engine.confirmBreakEnded(now: now)
        case .work:
            break
        }
        syncOverlayWithState()
        stateChanged()
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        func add(_ title: String, _ action: Selector) {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        add(L10n.t("Settings"), #selector(openPreferences))
        add(L10n.t("About"), #selector(openAbout))
        add(L10n.t("ContactDeveloper"), #selector(emailDeveloper))
        add(L10n.t("Quit"), #selector(quit))

        return menu
    }

    private func showMenu(from view: NSView) {
        buildMenu().popUp(positioning: nil, at: NSPoint(x: 0, y: view.bounds.minY - 4), in: view)
    }

    private func showMenuNearStatusItem() {
        guard let button = statusItemController.button else { return }
        buildMenu().popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY - 4), in: button)
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController(preferences: preferences) { [weak self] in
                self?.applyPreferences()
            }
        }
        panelController.hide()
        preferencesWindow?.show()
    }

    @objc private func openAbout() {
        if aboutWindow == nil {
            aboutWindow = AboutWindowController()
        }
        panelController.hide()
        aboutWindow?.show()
    }

    @objc private func emailDeveloper() {
        guard let url = URL(string: "mailto:\(AppInfo.contactEmail)?subject=Breather") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        engine.persistNow()
        NSApp.terminate(nil)
    }

    private func applyPreferences() {
        // Windows cache their localized titles, so drop them to pick up a
        // language change. Deferred: this is called from inside the settings
        // window's own save handler, and releasing the controller mid-method
        // would free the window under the code still using it.
        DispatchQueue.main.async { [weak self] in
            self?.preferencesWindow = nil
            self?.aboutWindow = nil
        }
        engine.applyDurations(now: Date())
        idleMonitor = IdleMonitor(threshold: TimeInterval(preferences.idleMinutes * 60))
        syncOverlayWithState()
        stateChanged()
    }
}

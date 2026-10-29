import AppKit
import BreatherCore

final class TimerTicker {
    private let engine: TimerEngine
    private var timer: Timer?

    var onTick: (() -> Void)?

    init(engine: TimerEngine) {
        self.engine = engine
    }

    func start() {
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.fire()
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    deinit {
        timer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func systemDidWake() {
        fire()
    }

    private func fire() {
        engine.tick(now: Date())
        onTick?()
    }
}

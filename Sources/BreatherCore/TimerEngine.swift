import Foundation

public enum Phase: String, Equatable {
    case work
    case rest
    case restEnded
}

public enum PauseReason: String, Equatable {
    case manual
    case idle
    case frontmost
}

public struct TimerState: Equatable {
    public var phase: Phase
    public var phaseDuration: TimeInterval
    public var endDate: Date?
    public var pausedRemaining: TimeInterval
    public var isPaused: Bool
    public var pauseReason: PauseReason?
    public var isSnoozeAvailable: Bool
    public var pausedAt: Date?
}

public protocol TimerStateStore {
    func load() -> TimerState?
    func save(_ state: TimerState)
}

/// Wall-clock driven work/rest state machine. Holds no timers: the caller
/// drives `tick(now:)` and every transition is derived from absolute dates.
public final class TimerEngine {
    public private(set) var state: TimerState

    /// A phase change that happened while restoring, before callbacks existed.
    /// The app consumes this once after wiring so break counting and bells match
    /// a transition that occurred while the app was not running.
    private var launchTransition: (from: Phase, to: Phase)?

    public func consumeLaunchTransition() -> (from: Phase, to: Phase)? {
        defer { launchTransition = nil }
        return launchTransition
    }

    public var onPhaseChange: ((Phase, Phase) -> Void)?

    private let clock: BreatherClock
    private let preferences: Preferences
    private let store: TimerStateStore?
    private let calendar: Calendar

    public init(
        clock: BreatherClock,
        preferences: Preferences,
        store: TimerStateStore? = nil,
        calendar: Calendar = .current
    ) {
        self.clock = clock
        self.preferences = preferences
        self.store = store
        self.calendar = calendar

        if let restored = store?.load() {
            state = restored
            let previous = restored.phase
            tick(now: clock.now)
            if state.phase != previous {
                launchTransition = (previous, state.phase)
            }
        } else {
            state = TimerState(
                phase: .work,
                phaseDuration: Self.workDuration(preferences),
                endDate: clock.now.addingTimeInterval(Self.workDuration(preferences)),
                pausedRemaining: 0,
                isPaused: false,
                pauseReason: nil,
                isSnoozeAvailable: true,
                pausedAt: nil
            )
        }

        persist()
    }

    public func remaining(at now: Date) -> TimeInterval {
        if state.isPaused {
            return max(0, state.pausedRemaining)
        }
        guard let endDate = state.endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(now))
    }

    public func remaining() -> TimeInterval {
        remaining(at: clock.now)
    }

    public func progress(at now: Date) -> Double {
        guard state.phaseDuration > 0 else { return 0 }
        let elapsed = state.phaseDuration - remaining(at: now)
        return min(max(elapsed / state.phaseDuration, 0), 1)
    }

    public func progress() -> Double {
        progress(at: clock.now)
    }

    public var snoozeWindowOpen: Bool {
        state.phase == .work && !state.isPaused && state.isSnoozeAvailable
            && remaining() <= TimeInterval(preferences.popupSecond)
    }

    // MARK: - Events

    public func tick(now: Date) {
        autoResumeIfCrossedDay(now: now)

        guard !state.isPaused else { return }

        // At most one transition per tick: a jump that spans several phases
        // lands in the next phase and lets the user see it.
        switch state.phase {
        case .work where remaining(at: now) <= 0:
            enterRest(now: now)
        case .rest where remaining(at: now) <= 0:
            enterRestEnded()
        default:
            break
        }
    }

    public func pause(now: Date, reason: PauseReason = .manual) {
        guard !state.isPaused else { return }
        guard state.phase == .work || state.phase == .rest else { return }
        if state.phase == .work, preferences.forceBreak, remaining(at: now) <= popupWindow {
            return
        }

        state.pausedRemaining = remaining(at: now)
        state.endDate = nil
        state.isPaused = true
        state.pauseReason = reason
        state.pausedAt = now
        persist()
    }

    public func resume(now: Date, reason: PauseReason = .manual) {
        guard state.isPaused else { return }
        // An automatic resume must not release a manual pause.
        if reason != .manual, state.pauseReason != reason { return }

        state.endDate = now.addingTimeInterval(state.pausedRemaining)
        state.pausedRemaining = 0
        state.isPaused = false
        state.pauseReason = nil
        state.pausedAt = nil
        persist()
    }

    public func snooze(multiplier: Int, now: Date) {
        guard state.phase == .work, !state.isPaused, state.isSnoozeAvailable else { return }
        let current = remaining(at: now)
        guard current <= popupWindow else { return }

        let extra = TimeInterval(preferences.postponePeriod * 60 * max(1, multiplier))
        let capped = min(current + extra, Self.workDuration(preferences))
        state.endDate = now.addingTimeInterval(capped)
        state.isSnoozeAvailable = false
        persist()
    }

    /// Dragging the panel slider changes the remaining time of the current phase.
    public func setProgress(_ fraction: Double, now: Date) {
        guard state.phase == .work || state.phase == .rest else { return }
        let duration = state.phaseDuration
        guard duration > 0 else { return }

        let clamped = min(max(fraction, 0), 1)
        let remaining = max(duration * (1 - clamped), 0)

        if state.isPaused {
            state.pausedRemaining = remaining
        } else {
            state.endDate = now.addingTimeInterval(remaining)
        }
        persist()
    }

    public func endBreakEarly(now: Date) {
        guard state.phase == .rest, !preferences.forceBreak else { return }
        enterWork(now: now)
    }

    public func confirmBreakEnded(now: Date) {
        guard state.phase == .restEnded else { return }
        enterWork(now: now)
    }

    public func resetToWork(now: Date) {
        enterWork(now: now)
    }

    public func applyDurations(now: Date) {
        guard state.phase == .work || state.phase == .rest else { return }
        let duration = state.phase == .work
            ? Self.workDuration(preferences)
            : TimeInterval(preferences.breakPeriod * 60)
        guard duration != state.phaseDuration else { return }

        let fraction = progress(at: now)
        state.phaseDuration = duration
        let remaining = max(duration * (1 - fraction), 0)
        if state.isPaused {
            state.pausedRemaining = remaining
        } else {
            state.endDate = now.addingTimeInterval(remaining)
        }
        persist()
    }

    public func persistNow() {
        persist()
    }

    // MARK: - Transitions

    private func enterRest(now: Date) {
        transition(to: .rest)
        let duration = TimeInterval(preferences.breakPeriod * 60)
        state.phaseDuration = duration
        state.endDate = now.addingTimeInterval(duration)
        state.pausedRemaining = 0
        state.isPaused = false
        state.pauseReason = nil
        state.pausedAt = nil
        state.isSnoozeAvailable = true
        persist()
    }

    private func enterRestEnded() {
        transition(to: .restEnded)
        state.endDate = nil
        state.pausedRemaining = 0
        state.isPaused = false
        state.pauseReason = nil
        state.pausedAt = nil
        persist()
    }

    private func enterWork(now: Date) {
        transition(to: .work)
        let duration = Self.workDuration(preferences)
        state.phaseDuration = duration
        state.endDate = now.addingTimeInterval(duration)
        state.pausedRemaining = 0
        state.isPaused = false
        state.pauseReason = nil
        state.pausedAt = nil
        state.isSnoozeAvailable = true
        persist()
    }

    private func transition(to phase: Phase) {
        let previous = state.phase
        state.phase = phase
        if previous != phase {
            onPhaseChange?(previous, phase)
        }
    }

    private func autoResumeIfCrossedDay(now: Date) {
        guard state.isPaused, let pausedAt = state.pausedAt else { return }
        guard !calendar.isDate(pausedAt, inSameDayAs: now) else { return }
        guard calendar.component(.hour, from: now) >= 7 else { return }
        resume(now: now, reason: .manual)
    }

    private var popupWindow: TimeInterval {
        TimeInterval(preferences.popupSecond)
    }

    private static func workDuration(_ preferences: Preferences) -> TimeInterval {
        TimeInterval(preferences.workPeriod * 60)
    }

    private func persist() {
        store?.save(state)
    }
}

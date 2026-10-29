import Foundation

public final class UserDefaultsTimerStateStore: TimerStateStore {
    private enum Key {
        static let phase = "timer.phase"
        static let phaseDuration = "timer.phaseDuration"
        static let endDate = "timer.endDate"
        static let pausedRemaining = "timer.pausedRemaining"
        static let isPaused = "timer.isPaused"
        static let pauseReason = "timer.pauseReason"
        static let isSnoozeAvailable = "timer.isSnoozeAvailable"
        static let pausedAt = "timer.pausedAt"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> TimerState? {
        guard let raw = defaults.string(forKey: Key.phase), let phase = Phase(rawValue: raw) else {
            return nil
        }

        return TimerState(
            phase: phase,
            phaseDuration: defaults.double(forKey: Key.phaseDuration),
            endDate: defaults.object(forKey: Key.endDate) as? Date,
            pausedRemaining: defaults.double(forKey: Key.pausedRemaining),
            isPaused: defaults.bool(forKey: Key.isPaused),
            pauseReason: defaults.string(forKey: Key.pauseReason).flatMap(PauseReason.init(rawValue:)),
            isSnoozeAvailable: defaults.bool(forKey: Key.isSnoozeAvailable),
            pausedAt: defaults.object(forKey: Key.pausedAt) as? Date
        )
    }

    public func save(_ state: TimerState) {
        defaults.set(state.phase.rawValue, forKey: Key.phase)
        defaults.set(state.phaseDuration, forKey: Key.phaseDuration)
        defaults.set(state.pausedRemaining, forKey: Key.pausedRemaining)
        defaults.set(state.isPaused, forKey: Key.isPaused)

        if let reason = state.pauseReason {
            defaults.set(reason.rawValue, forKey: Key.pauseReason)
        } else {
            defaults.removeObject(forKey: Key.pauseReason)
        }
        defaults.set(state.isSnoozeAvailable, forKey: Key.isSnoozeAvailable)

        if let endDate = state.endDate {
            defaults.set(endDate, forKey: Key.endDate)
        } else {
            defaults.removeObject(forKey: Key.endDate)
        }

        if let pausedAt = state.pausedAt {
            defaults.set(pausedAt, forKey: Key.pausedAt)
        } else {
            defaults.removeObject(forKey: Key.pausedAt)
        }
    }
}

import Foundation

/// Minute-granularity daily log. Mirrors the original app's model: each minute
/// of work or rest is appended once as an hour*60+minute point per local day.
public final class StatsStore {
    private enum Prefix {
        static let work = "w_"
        static let rest = "b_"
        static let workWeekday = "w__"
        static let restWeekday = "b__"
        static let lastStat = "last_stat"
        static let breakCount = "breakCount"
        static let cancelCount = "cancelCount"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    // MARK: - Recording

    public func record(phase: Phase, isPaused: Bool, at date: Date) {
        guard !isPaused else { return }
        guard phase == .work || phase == .rest else { return }

        let key = dayKey(for: date)
        guard defaults.string(forKey: Prefix.lastStat) != key else { return }

        let previous = defaults.string(forKey: Prefix.lastStat)
        defaults.set(key, forKey: Prefix.lastStat)

        let minuteOfDay = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let day = dayString(for: date)
        let bucket = "\(phase == .work ? Prefix.work : Prefix.rest)\(day)"
        let existing = defaults.string(forKey: bucket)
        defaults.set(existing == nil ? "\(minuteOfDay)" : "\(existing!),\(minuteOfDay)", forKey: bucket)

        let weekday = calendar.component(.weekday, from: date)
        let weekdayKey = "\(phase == .work ? Prefix.workWeekday : Prefix.restWeekday)\(weekday)"
        defaults.set(defaults.integer(forKey: weekdayKey) + 1, forKey: weekdayKey)

        if let previous, !previous.hasPrefix(day) {
            let dayCountKey = "t__\(weekday)"
            defaults.set(defaults.integer(forKey: dayCountKey) + 1, forKey: dayCountKey)
        }
    }

    public func countBreak(at date: Date) {
        defaults.set(defaults.integer(forKey: Prefix.breakCount) + 1, forKey: Prefix.breakCount)
    }

    public func countCancel(at date: Date) {
        defaults.set(defaults.integer(forKey: Prefix.cancelCount) + 1, forKey: Prefix.cancelCount)
    }

    // MARK: - Reading

    public struct DayStats: Equatable {
        public var workMinutes: Int
        public var restMinutes: Int
    }

    public func stats(for date: Date) -> DayStats {
        let day = dayString(for: date)
        return DayStats(
            workMinutes: minuteCount(key: Prefix.work + day),
            restMinutes: minuteCount(key: Prefix.rest + day)
        )
    }

    public func breakCount() -> Int { defaults.integer(forKey: Prefix.breakCount) }
    public func cancelCount() -> Int { defaults.integer(forKey: Prefix.cancelCount) }

    /// Last `days` days ending at `date`, oldest first.
    public func lastDays(_ days: Int, endingAt date: Date) -> [(date: Date, stats: DayStats)] {
        (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) else {
                return nil
            }
            return (day, stats(for: day))
        }
    }

    // MARK: - Helpers

    private func minuteCount(key: String) -> Int {
        guard let raw = defaults.string(forKey: key), !raw.isEmpty else { return 0 }
        return raw.split(separator: ",").count
    }

    private func dayString(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)_\(c.month ?? 0)_\(c.day ?? 0)"
    }

    private func dayKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return "\(c.year ?? 0)_\(c.month ?? 0)_\(c.day ?? 0)_\(c.hour ?? 0)_\(c.minute ?? 0)"
    }
}

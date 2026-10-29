import Foundation
import CoreGraphics

/// Reports seconds since the last user input without requiring any permission.
public final class IdleMonitor {
    private let threshold: TimeInterval

    public init(threshold: TimeInterval) {
        self.threshold = threshold
    }

    public var isIdle: Bool {
        secondsSinceLastInput() >= threshold
    }

    private func secondsSinceLastInput() -> TimeInterval {
        let events: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseUp, .rightMouseUp, .otherMouseUp,
            .scrollWheel, .keyDown, .keyUp, .flagsChanged,
        ]

        return events
            .map { CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: $0) }
            .min() ?? 0
    }
}

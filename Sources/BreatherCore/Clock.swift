import Foundation

public protocol BreatherClock {
    var now: Date { get }
}

public struct SystemClock: BreatherClock {
    public init() {}

    public var now: Date { Date() }
}

import Foundation

/// The animal drawn as the main panel slider's thumb. Stored in preferences by
/// its raw value so adding options later does not shift existing choices.
public enum SliderIcon: String, CaseIterable, Sendable {
    case tortoise
    case dog
    case cat
    case person
    case hare

    public static let `default`: SliderIcon = .tortoise

    /// Missing or unknown stored values fall back to the default so a stale
    /// preference never leaves the panel without a thumb.
    public init(stored: String) {
        self = SliderIcon(rawValue: stored) ?? .default
    }

    public var symbolName: String {
        switch self {
        case .tortoise: return "tortoise.fill"
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .person: return "figure.walk"
        case .hare: return "hare.fill"
        }
    }

    /// Optical height in points, picked so the five silhouettes read as roughly
    /// the same visual weight. Width follows the symbol's aspect ratio.
    public var opticalHeight: Double {
        switch self {
        case .tortoise: return 12
        case .dog: return 15
        case .cat: return 15
        case .person: return 16
        case .hare: return 14
        }
    }
}

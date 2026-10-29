import Foundation

/// Maps between the slider's horizontal position and its progress. Kept free
/// of AppKit so the drag maths can be unit tested.
public enum SliderGeometry {
    /// `inset` keeps the thumb fully inside the track at both ends; it is half
    /// the thumb width. Values outside the track clamp to 0...1.
    public static func progress(forX x: Double, width: Double, inset: Double) -> Double {
        let travel = width - 2 * inset
        guard travel > 0 else { return 0 }
        return min(max((x - inset) / travel, 0), 1)
    }

    public static func x(forProgress progress: Double, width: Double, inset: Double) -> Double {
        let travel = width - 2 * inset
        guard travel > 0 else { return width / 2 }
        return inset + min(max(progress, 0), 1) * travel
    }
}

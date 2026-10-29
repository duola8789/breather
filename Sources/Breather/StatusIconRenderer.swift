import AppKit
import BreatherCore

/// Monochrome pie: the wedge still filled is the time that remains, so the icon
/// drains as the phase progresses. Rendered as a template image so macOS tints
/// it for light and dark menu bars, matching the original.
enum StatusIconRenderer {
    static let size = NSSize(width: 18, height: 18)

    static func pie(progress: Double, isPaused: Bool) -> NSImage {
        let alpha: CGFloat = isPaused ? 0.38 : 1
        let image = NSImage(size: size, flipped: false) { rect in
            let remaining = 1 - min(max(progress, 0), 1)
            let center = NSPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2 - 1.5

            let path = NSBezierPath()
            path.move(to: center)
            path.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 90,
                endAngle: 90 - 360 * CGFloat(remaining),
                clockwise: true
            )
            path.close()
            NSColor.black.withAlphaComponent(alpha).setFill()
            path.fill()

            let outline = NSBezierPath()
            outline.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            outline.lineWidth = 1
            NSColor.black.withAlphaComponent(alpha).setStroke()
            outline.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}

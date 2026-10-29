import AppKit
import BreatherCore

/// The main panel's timeline slider. Replaces `NSSlider` because the system
/// knob cannot be swapped for a symbol that stands on the track: the 4pt bar
/// would otherwise run straight through the animal's body.
final class AnimalSliderView: NSView {
    static let height: CGFloat = 26
    private static let trackHeight: CGFloat = 4
    private static let trackCenterY: CGFloat = 9
    private static let minimumInset: CGFloat = 7

    /// Elapsed fraction of the current phase, 0...1.
    var progress: Double = 0 {
        didSet {
            guard progress != oldValue else { return }
            needsDisplay = true
            layoutThumb()
        }
    }

    var icon: SliderIcon = .default {
        didSet {
            guard icon != oldValue else { return }
            reloadIcon()
            needsDisplay = true
        }
    }

    /// Called continuously while dragging, and once for a click on the track.
    var onDrag: ((Double) -> Void)?

    private let thumb = NSImageView()
    private var thumbAspect: CGFloat = 1

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        thumb.imageScaling = .scaleProportionallyUpOrDown
        thumb.contentTintColor = .labelColor
        thumb.isEditable = false
        thumb.setAccessibilityElement(false)
        addSubview(thumb)

        reloadIcon()
        layoutThumb()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let trackRect = NSRect(
            x: 0,
            y: Self.trackCenterY - Self.trackHeight / 2,
            width: bounds.width,
            height: Self.trackHeight
        )
        NSColor.separatorColor.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: 2, yRadius: 2).fill()

        let center = thumbCenterX()
        if center > 0.5 {
            let filled = NSRect(x: 0, y: trackRect.minY, width: center, height: trackRect.height)
            NSColor.controlAccentColor.setFill()
            NSBezierPath(roundedRect: filled, xRadius: 2, yRadius: 2).fill()
        }

        // A soft contact shadow under the feet so the animal reads as standing
        // on the track rather than floating above it.
        let thumbWidth = thumb.frame.width
        if thumbWidth > 0 {
            let shadow = NSRect(
                x: center - thumbWidth * 0.28,
                y: Self.trackCenterY - 1.1,
                width: thumbWidth * 0.56,
                height: 2.2
            )
            NSColor.black.withAlphaComponent(0.22).setFill()
            NSBezierPath(ovalIn: shadow).fill()
        }
    }

    override func layout() {
        super.layout()
        layoutThumb()
    }

    // MARK: - Thumb

    private func reloadIcon() {
        let config = NSImage.SymbolConfiguration(
            pointSize: CGFloat(icon.opticalHeight),
            weight: .semibold
        )
        guard let image = NSImage(systemSymbolName: icon.symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            thumb.image = nil
            thumbAspect = 1
            layoutThumb()
            return
        }
        image.isTemplate = true
        thumb.image = image
        thumbAspect = image.size.height > 0 ? image.size.width / image.size.height : 1
        layoutThumb()
    }

    private func layoutThumb() {
        guard bounds.width > 0 else { return }
        let height = CGFloat(icon.opticalHeight)
        let width = height * thumbAspect
        let center = thumbCenterX()
        thumb.frame = NSRect(
            x: center - width / 2,
            y: Self.trackCenterY,
            width: width,
            height: height
        )
    }

    private func thumbCenterX() -> CGFloat {
        CGFloat(SliderGeometry.x(
            forProgress: progress,
            width: Double(bounds.width),
            inset: Double(inset)
        ))
    }

    private var inset: CGFloat {
        max(CGFloat(icon.opticalHeight) * thumbAspect / 2, Self.minimumInset)
    }

    // MARK: - Dragging

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, alphaValue > 0 else { return nil }
        return bounds.contains(convert(point, from: superview)) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        drag(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        drag(with: event)
    }

    private func drag(with event: NSEvent) {
        let x = convert(event.locationInWindow, from: nil).x
        let value = SliderGeometry.progress(
            forX: Double(x),
            width: Double(bounds.width),
            inset: Double(inset)
        )
        guard value != progress else { return }
        progress = value
        onDrag?(value)
    }

    // MARK: - Accessibility

    override func isAccessibilityElement() -> Bool { true }

    override func accessibilityRole() -> NSAccessibility.Role? { .slider }

    override func accessibilityLabel() -> String? { L10n.t("TimeRemainingProgress") }

    override func accessibilityValue() -> Any? { Int((progress * 100).rounded()) }

    override func accessibilityMinValue() -> Any? { 0 }

    override func accessibilityMaxValue() -> Any? { 100 }

    override func accessibilityValueDescription() -> String? {
        "\(Int((progress * 100).rounded()))%"
    }

    override func accessibilityPerformIncrement() -> Bool {
        adjust(by: 0.05)
        return true
    }

    override func accessibilityPerformDecrement() -> Bool {
        adjust(by: -0.05)
        return true
    }

    private func adjust(by delta: Double) {
        let value = min(max(progress + delta, 0), 1)
        guard value != progress else { return }
        progress = value
        onDrag?(value)
    }
}

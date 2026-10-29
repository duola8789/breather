import AppKit
import BreatherCore

final class MainPanel: NSPanel {
    var onEscape: (() -> Void)?
    var onSpace: (() -> Void)?
    var onReturn: (() -> Void)?
    var onResignKey: (() -> Void)?

    static let size = NSSize(width: 268, height: 102)
    static let cornerRadius: CGFloat = 12

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = false
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        isMovable = false
        hasShadow = true
        level = .floating
        collectionBehavior = [.fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: onEscape?()
        case 49: onSpace?()
        case 36, 76: onReturn?()
        default: super.keyDown(with: event)
        }
    }
}

/// The popover card. On macOS 26 and later it uses the system glass effect;
/// older systems get a blurred vibrancy view with the same corner radius.
final class MainPanelView: NSView {
    private let effect = NSVisualEffectView()
    private var glass: NSView?
    private var tint: NSColor?

    /// `NSGlassEffectView` only exists in the macOS 26 SDK. Looking it up by
    /// name keeps this file compiling against older SDKs (CI uses one) while
    /// still using glass on machines that have it.
    private static func makeGlassView(frame: NSRect) -> NSView? {
        guard let cls = NSClassFromString("NSGlassEffectView") as? NSView.Type else { return nil }
        let view = cls.init(frame: frame)
        view.setValue(MainPanel.cornerRadius, forKey: "cornerRadius")
        return view
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        if let glass = Self.makeGlassView(frame: bounds) {
            glass.autoresizingMask = [.width, .height]
            addSubview(glass)
            self.glass = glass
        } else {
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.frame = bounds
            effect.autoresizingMask = [.width, .height]
            effect.wantsLayer = true
            effect.layer?.cornerRadius = MainPanel.cornerRadius
            effect.layer?.masksToBounds = true
            addSubview(effect)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func applyAppearance(_ preferences: Preferences) {
        switch preferences.panelAppearance {
        case "light":
            appearance = NSAppearance(named: .aqua)
            tint = nil
        case "dark":
            appearance = NSAppearance(named: .darkAqua)
            tint = nil
        case "custom":
            appearance = NSAppearance(named: .darkAqua)
            if let color = preferences.panelColor {
                tint = NSColor(
                    srgbRed: color.red, green: color.green, blue: color.blue, alpha: 0.92
                )
            }
        default:
            appearance = nil
            tint = nil
        }

        if let glass {
            glass.setValue(tint, forKey: "tintColor")
        } else {
            effect.material = preferences.panelAppearance == "dark" ? .hudWindow : .popover
            effect.appearance = appearance
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if let tint {
            tint.setFill()
            NSBezierPath(
                roundedRect: bounds,
                xRadius: MainPanel.cornerRadius,
                yRadius: MainPanel.cornerRadius
            ).fill()
        }
        guard glass == nil else { return }
        let outline = NSBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            xRadius: MainPanel.cornerRadius,
            yRadius: MainPanel.cornerRadius
        )
        NSColor.separatorColor.withAlphaComponent(0.7).setStroke()
        outline.lineWidth = 1
        outline.stroke()
    }
}
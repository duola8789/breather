import AppKit
import BreatherCore

/// Keeps the break overlay out of its own background snapshot and draws the
/// banner as one card, the way the original does.
final class BreakOverlayController {
    private var windows: [NSWindow] = []
    private let mainText = NSTextField(labelWithString: "")
    private let subText = NSTextField(labelWithString: "")
    private let doneButton = NSButton()
    private let card = BannerCard()

    var onDone: (() -> Void)?

    var isVisible: Bool { !windows.isEmpty }

    func show(remaining: TimeInterval, forceBreak: Bool, preferences: Preferences) {
        hide()

        let screens = NSScreen.screens
        guard let primary = screens.first else { return }
        let snapshot = preferences.captureDesktopImage ? Self.captureDesktop() : nil

        for (index, screen) in screens.enumerated() {
            let window = makeWindow(
                for: screen,
                primary: index == 0,
                preferences: preferences,
                snapshot: snapshot
            )
            windows.append(window)
        }

        if let primaryWindow = windows.first, let content = primaryWindow.contentView {
            buildPrimaryContent(in: content, screen: primary)
        }

        refresh(remaining: remaining, forceBreak: forceBreak, isBreakOver: false)

        for window in windows {
            window.orderFrontRegardless()
        }
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKey()
    }

    func hide() {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()
    }

    func refresh(remaining: TimeInterval, forceBreak: Bool, isBreakOver: Bool) {
        let total = Int(max(remaining, 0).rounded(.up))
        let mm = total / 60
        let ss = total % 60

        if isBreakOver {
            mainText.stringValue = L10n.t("It's time for Work!")
            subText.stringValue = L10n.t("Back to work now!")
            doneButton.isEnabled = true
        } else {
            mainText.stringValue = L10n.t("It's time for Relax!")
            subText.stringValue = String(format: L10n.t("OverlayBackToWork"), mm, ss)
            doneButton.isEnabled = !forceBreak
        }
    }

    private func makeWindow(
        for screen: NSScreen,
        primary: Bool,
        preferences: Preferences,
        snapshot: NSImage?
    ) -> NSWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = true
        // The original uses 101 (pop-up menu level): high enough to cover apps,
        // low enough that screenshot tools can still draw above it.
        window.level = NSWindow.Level(rawValue: 101)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 1)
        window.hasShadow = false
        window.isReleasedWhenClosed = false

        if let snapshot, let content = window.contentView {
            let imageView = NSImageView(frame: content.bounds)
            imageView.image = snapshot
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.autoresizingMask = [.width, .height]
            imageView.alphaValue = preferences.overlayBrightness
            content.addSubview(imageView)
        }

        window.onKey = { [weak self] in
            guard let self, self.doneButton.isEnabled else { return }
            self.onDone?()
        }

        return window
    }

    private func buildPrimaryContent(in content: NSView, screen: NSScreen) {
        let bounds = content.bounds

        let cardWidth: CGFloat = 340
        let cardHeight: CGFloat = 132
        card.frame = NSRect(
            x: bounds.midX - cardWidth / 2,
            y: bounds.midY - cardHeight / 2,
            width: cardWidth,
            height: cardHeight
        )
        card.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        card.addSubview(mainText)
        card.addSubview(subText)
        card.addSubview(doneButton)

        mainText.frame = NSRect(x: 0, y: 84, width: cardWidth, height: 26)
        mainText.font = .systemFont(ofSize: 18, weight: .semibold)
        mainText.textColor = .white
        mainText.alignment = .center
        mainText.drawsBackground = false
        mainText.isBezeled = false
        mainText.isEditable = false

        subText.frame = NSRect(x: 0, y: 62, width: cardWidth, height: 18)
        subText.font = .systemFont(ofSize: 12)
        subText.textColor = NSColor.white.withAlphaComponent(0.72)
        subText.alignment = .center
        subText.drawsBackground = false
        subText.isBezeled = false
        subText.isEditable = false

        doneButton.frame = NSRect(x: (cardWidth - 96) / 2, y: 22, width: 96, height: 30)
        doneButton.title = L10n.t("Done")
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        doneButton.target = self
        doneButton.action = #selector(doneTapped)

        content.addSubview(card)
    }

    @objc private func doneTapped() {
        guard doneButton.isEnabled else { return }
        onDone?()
    }

    /// Desktop snapshot with this app's own windows removed, so the panel can
    /// never appear frozen into the background.
    private static func captureDesktop() -> NSImage? {
        guard let info = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        var ids: [CGWindowID] = []
        for entry in info {
            guard let pid = entry[kCGWindowOwnerPID as String] as? Int32, pid != ownPID else { continue }
            guard let number = entry[kCGWindowNumber as String] as? CGWindowID else { continue }
            ids.append(number)
        }
        guard !ids.isEmpty else { return nil }

        guard let cgImage = CGImage(
            windowListFromArrayScreenBounds: CGRect.null,
            windowArray: ids as CFArray,
            imageOption: [.bestResolution]
        ) else { return nil }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}

final class BreakOverlayWindow: NSWindow {
    var onKey: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76, 49, 53:
            onKey?()
        default:
            super.keyDown(with: event)
        }
    }
}

/// The banner the countdown and button sit in.
final class BannerCard: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        NSColor(calibratedWhite: 0.12, alpha: 0.72).setFill()
        path.fill()
        NSColor(calibratedWhite: 1, alpha: 0.08).setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}



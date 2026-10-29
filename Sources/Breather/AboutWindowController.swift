import AppKit
import BreatherCore

final class AboutWindowController: NSWindowController {
    private let checkButton = NSButton()

    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.t("About")
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        super.init(window: panel)

        let content = panel.contentView ?? NSView()

        let title = NSTextField(labelWithString: "Breather")
        title.frame = NSRect(x: 0, y: 150, width: 320, height: 24)
        title.alignment = .center
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        content.addSubview(title)

        let version = NSTextField(labelWithString: "\(L10n.t("Version")) \(AppInfo.version)")
        version.frame = NSRect(x: 0, y: 126, width: 320, height: 18)
        version.alignment = .center
        version.font = .systemFont(ofSize: 12)
        content.addSubview(version)

        let note = NSTextField(labelWithString: L10n.t("AboutTagline"))
        note.frame = NSRect(x: 20, y: 78, width: 280, height: 40)
        note.alignment = .center
        note.font = .systemFont(ofSize: 11)
        note.textColor = .secondaryLabelColor
        content.addSubview(note)

        checkButton.title = L10n.t("CheckForUpdates")
        checkButton.frame = NSRect(x: 100, y: 34, width: 120, height: 30)
        checkButton.bezelStyle = .rounded
        checkButton.target = self
        checkButton.action = #selector(checkForUpdates)
        content.addSubview(checkButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func show() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func checkForUpdates() {
        checkButton.isEnabled = false
        checkButton.title = L10n.t("CheckingForUpdates")

        UpdateChecker.check { [weak self] outcome in
            guard let self else { return }
            self.checkButton.isEnabled = true
            self.checkButton.title = L10n.t("CheckForUpdates")

            switch outcome {
            case .upToDate(let current):
                self.present(message: String(format: L10n.t("UpToDate"), current), download: nil)
            case .updateAvailable(let version, let url):
                self.present(message: String(format: L10n.t("UpdateAvailable"), version), download: url)
            case .failed(let reason):
                self.present(message: String(format: L10n.t("UpdateFailed"), reason), download: nil)
            }
        }
    }

    private func present(message: String, download: URL?) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        if let download {
            alert.addButton(withTitle: L10n.t("Download"))
            alert.addButton(withTitle: L10n.t("OK"))
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(download)
            }
        } else {
            alert.addButton(withTitle: L10n.t("OK"))
            alert.runModal()
        }
    }
}

import AppKit
import BreatherCore

final class PreferencesWindowController: NSWindowController {
    private let preferences: Preferences
    private let onApply: () -> Void

    private let workSlider = NSSlider()
    private let breakSlider = NSSlider()
    private let workValue = NSTextField(labelWithString: "")
    private let breakValue = NSTextField(labelWithString: "")
    private let startAtLogin = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let alwaysOnTop = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let ringBell = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let forceBreak = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let appearancePopup = NSPopUpButton()
    private let colorWell = NSColorWell()
    private let iconPopup = NSPopUpButton()
    private let languagePopup = NSPopUpButton()

    private static let width: CGFloat = 420
    private static let height: CGFloat = 496
    private static let margin: CGFloat = 24
    private static let labelWidth: CGFloat = 104
    private static let valueWidth: CGFloat = 52

    init(preferences: Preferences, onApply: @escaping () -> Void) {
        self.preferences = preferences
        self.onApply = onApply

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: Self.height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.t("Settings")
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating

        super.init(window: panel)
        buildUI()
        loadValues()

        if ProcessInfo.processInfo.environment["BREATHER_DEMO"] == "save" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.saveTapped()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func show() {
        loadValues()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func loadValues() {
        workSlider.doubleValue = Double(preferences.workPeriod)
        breakSlider.doubleValue = Double(preferences.breakPeriod)
        updateValueLabels()

        startAtLogin.state = LoginItem.isEnabled ? .on : .off
        alwaysOnTop.state = preferences.panelAlwaysOnTop ? .on : .off
        ringBell.state = preferences.ringBellOnBreakStart ? .on : .off
        forceBreak.state = preferences.forceBreak ? .on : .off

        let appearances = ["system", "light", "dark", "custom"]
        appearancePopup.selectItem(at: appearances.firstIndex(of: preferences.panelAppearance) ?? 0)
        colorWell.color = storedColor()
        colorWell.isEnabled = preferences.panelAppearance == "custom"

        iconPopup.selectItem(at: SliderIcon.allCases.firstIndex(of: preferences.sliderIcon) ?? 0)

        let languages = L10n.availableLanguages()
        languagePopup.selectItem(at: languages.firstIndex(of: preferences.appLanguage) ?? 0)
    }

    private func storedColor() -> NSColor {
        guard let stored = preferences.panelColor else { return .windowBackgroundColor }
        return NSColor(srgbRed: stored.red, green: stored.green, blue: stored.blue, alpha: 1)
    }

    private func updateValueLabels() {
        let unit = L10n.t("min")
        workValue.stringValue = "\(Int(workSlider.doubleValue)) \(unit)"
        breakValue.stringValue = "\(Int(breakSlider.doubleValue)) \(unit)"
    }

    @objc private func sliderMoved() {
        updateValueLabels()
    }

    @objc private func appearanceChanged() {
        colorWell.isEnabled = appearancePopup.indexOfSelectedItem == 3
    }

    @objc private func saveTapped() {
        preferences.workPeriod = Int(workSlider.doubleValue)
        preferences.breakPeriod = Int(breakSlider.doubleValue)
        preferences.panelAlwaysOnTop = alwaysOnTop.state == .on
        preferences.ringBellOnBreakStart = ringBell.state == .on
        preferences.forceBreak = forceBreak.state == .on

        let appearances = ["system", "light", "dark", "custom"]
        let appearanceIndex = appearancePopup.indexOfSelectedItem
        if appearanceIndex >= 0, appearanceIndex < appearances.count {
            preferences.panelAppearance = appearances[appearanceIndex]
        }
        if preferences.panelAppearance == "custom" {
            let rgb = colorWell.color.usingColorSpace(.sRGB) ?? .gray
            preferences.panelColor = (
                Double(rgb.redComponent),
                Double(rgb.greenComponent),
                Double(rgb.blueComponent)
            )
        } else {
            preferences.panelColor = nil
        }

        let icons = SliderIcon.allCases
        if iconPopup.indexOfSelectedItem >= 0, iconPopup.indexOfSelectedItem < icons.count {
            preferences.sliderIcon = icons[iconPopup.indexOfSelectedItem]
        }

        let languages = L10n.availableLanguages()
        if languagePopup.indexOfSelectedItem >= 0,
           languagePopup.indexOfSelectedItem < languages.count {
            preferences.appLanguage = languages[languagePopup.indexOfSelectedItem]
        }

        let wantsLogin = startAtLogin.state == .on
        if wantsLogin != LoginItem.isEnabled {
            if case .failed(let message) = LoginItem.setEnabled(wantsLogin) {
                let alert = NSAlert()
                alert.messageText = message
                alert.runModal()
                startAtLogin.state = LoginItem.isEnabled ? .on : .off
            } else {
                preferences.autoStartup = wantsLogin
            }
        }

        onApply()
        window?.close()

        let notice = NSAlert()
        notice.messageText = L10n.t("SavedPreferences")
        notice.runModal()
    }

    private func iconTitle(_ icon: SliderIcon) -> String {
        switch icon {
        case .tortoise: return L10n.t("IconTortoise")
        case .dog: return L10n.t("IconDog")
        case .cat: return L10n.t("IconCat")
        case .person: return L10n.t("IconPerson")
        case .hare: return L10n.t("IconHare")
        }
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }
        let labelFont = NSFont.systemFont(ofSize: 12)
        let headerFont = NSFont.systemFont(ofSize: 11, weight: .semibold)

        func header(_ text: String, y: CGFloat) {
            let field = NSTextField(labelWithString: text)
            field.frame = NSRect(x: Self.margin, y: y, width: 260, height: 15)
            field.font = headerFont
            field.textColor = .secondaryLabelColor
            content.addSubview(field)
        }

        func label(_ text: String, y: CGFloat) {
            let field = NSTextField(labelWithString: text)
            field.frame = NSRect(x: Self.margin, y: y, width: Self.labelWidth, height: 17)
            field.font = labelFont
            field.alignment = .left
            content.addSubview(field)
        }

        func divider(y: CGFloat) {
            let line = DividerView(frame: NSRect(
                x: Self.margin, y: y,
                width: Self.width - Self.margin * 2, height: 1
            ))
            content.addSubview(line)
        }

        let fieldX = Self.margin + Self.labelWidth + 12
        let fieldWidth = Self.width - Self.margin - Self.valueWidth - 10 - fieldX

        header("时长", y: 448)

        label(L10n.t("ExpectedWorkPeriod"), y: 418)
        workSlider.frame = NSRect(x: fieldX, y: 416, width: fieldWidth, height: 20)
        configure(slider: workSlider, min: 1, max: 120)
        workValue.frame = NSRect(
            x: Self.width - Self.margin - Self.valueWidth, y: 418,
            width: Self.valueWidth, height: 17
        )
        styleValue(workValue, font: labelFont)
        content.addSubview(workValue)

        label(L10n.t("ExpectedBreakPeriod"), y: 388)
        breakSlider.frame = NSRect(x: fieldX, y: 386, width: fieldWidth, height: 20)
        configure(slider: breakSlider, min: 1, max: 60)
        breakValue.frame = NSRect(
            x: Self.width - Self.margin - Self.valueWidth, y: 388,
            width: Self.valueWidth, height: 17
        )
        styleValue(breakValue, font: labelFont)
        content.addSubview(breakValue)

        divider(y: 370)

        header("启动与显示", y: 344)
        configure(checkbox: startAtLogin, title: L10n.t("StartAtLogin"), y: 316)
        configure(checkbox: alwaysOnTop, title: L10n.t("KeepThisPopoverOnTop"), y: 290)
        configure(checkbox: ringBell, title: L10n.t("RingBellWhenStarting"), y: 264)
        configure(checkbox: forceBreak, title: L10n.t("ForceBreak"), y: 238)

        divider(y: 220)

        header("外观与语言", y: 194)

        label("面板背景", y: 164)
        appearancePopup.frame = NSRect(x: fieldX, y: 160, width: 150, height: 24)
        appearancePopup.addItems(withTitles: ["跟随系统", "浅色", "深色", "自定义"])
        appearancePopup.target = self
        appearancePopup.action = #selector(appearanceChanged)
        content.addSubview(appearancePopup)

        colorWell.frame = NSRect(x: fieldX + 162, y: 160, width: 44, height: 24)
        content.addSubview(colorWell)

        label(L10n.t("SliderIcon"), y: 124)
        iconPopup.frame = NSRect(x: fieldX, y: 120, width: 150, height: 24)
        iconPopup.addItems(withTitles: SliderIcon.allCases.map(iconTitle))
        content.addSubview(iconPopup)

        label(L10n.t("Language"), y: 84)
        languagePopup.frame = NSRect(x: fieldX, y: 80, width: 150, height: 24)
        languagePopup.addItems(withTitles: [
            L10n.t("FollowSystem"), L10n.t("Chinese"), L10n.t("English"),
        ])
        content.addSubview(languagePopup)

        divider(y: 62)

        let save = NSButton(title: L10n.t("Save"), target: self, action: #selector(saveTapped))
        save.frame = NSRect(x: Self.width - Self.margin - 96, y: 16, width: 96, height: 30)
        save.bezelStyle = .rounded
        save.keyEquivalent = "\r"
        content.addSubview(save)
    }

    private func styleValue(_ field: NSTextField, font: NSFont) {
        field.font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: .regular)
        field.alignment = .right
        field.textColor = .secondaryLabelColor
    }

    private func configure(slider: NSSlider, min: Double, max: Double) {
        slider.minValue = min
        slider.maxValue = max
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderMoved)
        window?.contentView?.addSubview(slider)
    }

    private func configure(checkbox: NSButton, title: String, y: CGFloat) {
        checkbox.title = title
        checkbox.frame = NSRect(x: Self.margin, y: y, width: Self.width - Self.margin * 2, height: 20)
        checkbox.font = NSFont.systemFont(ofSize: 12)
        window?.contentView?.addSubview(checkbox)
    }
}

final class DividerView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.separatorColor.setFill()
        bounds.fill()
    }
}

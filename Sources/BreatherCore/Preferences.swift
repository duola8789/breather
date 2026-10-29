import Foundation

public final class Preferences {
    public enum Key {
        public static let workPeriod = "workPeriod"
        public static let breakPeriod = "breakPeriod"
        public static let postponePeriod = "postponePeriod"
        public static let popupSecond = "popupSecond"
        public static let forceBreak = "forceBreak"
        public static let autoStartup = "autoStartup"
        public static let panelAlwaysOnTop = "panelAlwaysOnTop"
        public static let showIndicatorBeforeBreak = "showIndicatorBeforeBreak"
        public static let showPopupBeforeBreak = "showPopupBeforeBreak"
        public static let ringBellOnBreakStart = "ringBellOnBreakStart"
        public static let ringBellOnBreakEnd = "ringBellOnBreakEnd"
        public static let autoCloseBreakOverlay = "autoCloseBreakOverlay"
        public static let pauseWhenIdle = "checkIDLE"
        public static let idleMinutes = "idleMinutes"
        public static let pauseWhenFrontmost = "checkPauseWhenFrontMost"
        public static let frontmostApps = "frontmostApps"
        public static let resetWhenWakeup = "chkResetWhenWakeup"
        public static let captureDesktopImage = "captureDesktopImage"
        public static let overlayBrightness = "blurView"
        public static let bellStartVolume = "bellStartVolume"
        public static let bellEndVolume = "bellEndVolume"
        public static let usingSystemScreenLock = "usingSysScreenLock"
        public static let appLanguage = "appLanguage"
        public static let panelAppearance = "panelAppearance"
        public static let panelRed = "panelRed"
        public static let panelGreen = "panelGreen"
        public static let panelBlue = "panelBlue"
        public static let sliderIcon = "sliderIcon"
    }

    /// Defaults mirror the values the reference implementation ships with.
    public enum Defaults {
        public static let workPeriod = 45
        public static let breakPeriod = 5
        public static let postponePeriod = 5
        public static let popupSecond = 10
        public static let forceBreak = false
        public static let autoStartup = false
        public static let panelAlwaysOnTop = true
        public static let showIndicatorBeforeBreak = true
        public static let showPopupBeforeBreak = true
        public static let ringBellOnBreakStart = true
        public static let ringBellOnBreakEnd = true
        public static let autoCloseBreakOverlay = false
        public static let pauseWhenIdle = false
        public static let idleMinutes = 5
        public static let pauseWhenFrontmost = false
        public static let resetWhenWakeup = false
        public static let captureDesktopImage = true
        public static let overlayBrightness = 0.2
        public static let bellStartVolume = 70
        public static let bellEndVolume = 70
        public static let usingSystemScreenLock = false
        public static let appLanguage = "system"
        public static let panelAppearance = "system"
        public static let sliderIcon = SliderIcon.default.rawValue
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var workPeriod: Int {
        get { int(Key.workPeriod, Defaults.workPeriod) }
        set { defaults.set(newValue, forKey: Key.workPeriod) }
    }
    public var breakPeriod: Int {
        get { int(Key.breakPeriod, Defaults.breakPeriod) }
        set { defaults.set(newValue, forKey: Key.breakPeriod) }
    }
    public var postponePeriod: Int {
        get { int(Key.postponePeriod, Defaults.postponePeriod) }
        set { defaults.set(newValue, forKey: Key.postponePeriod) }
    }
    public var popupSecond: Int {
        get { int(Key.popupSecond, Defaults.popupSecond) }
        set { defaults.set(newValue, forKey: Key.popupSecond) }
    }
    public var idleMinutes: Int {
        get { int(Key.idleMinutes, Defaults.idleMinutes) }
        set { defaults.set(newValue, forKey: Key.idleMinutes) }
    }
    public var bellStartVolume: Int {
        get { int(Key.bellStartVolume, Defaults.bellStartVolume) }
        set { defaults.set(newValue, forKey: Key.bellStartVolume) }
    }
    public var bellEndVolume: Int {
        get { int(Key.bellEndVolume, Defaults.bellEndVolume) }
        set { defaults.set(newValue, forKey: Key.bellEndVolume) }
    }
    public var overlayBrightness: Double {
        get { double(Key.overlayBrightness, Defaults.overlayBrightness) }
        set { defaults.set(newValue, forKey: Key.overlayBrightness) }
    }

    public var forceBreak: Bool {
        get { bool(Key.forceBreak, Defaults.forceBreak) }
        set { defaults.set(newValue, forKey: Key.forceBreak) }
    }
    public var autoStartup: Bool {
        get { bool(Key.autoStartup, Defaults.autoStartup) }
        set { defaults.set(newValue, forKey: Key.autoStartup) }
    }
    public var panelAlwaysOnTop: Bool {
        get { bool(Key.panelAlwaysOnTop, Defaults.panelAlwaysOnTop) }
        set { defaults.set(newValue, forKey: Key.panelAlwaysOnTop) }
    }
    public var showIndicatorBeforeBreak: Bool {
        get { bool(Key.showIndicatorBeforeBreak, Defaults.showIndicatorBeforeBreak) }
        set { defaults.set(newValue, forKey: Key.showIndicatorBeforeBreak) }
    }
    public var showPopupBeforeBreak: Bool {
        get { bool(Key.showPopupBeforeBreak, Defaults.showPopupBeforeBreak) }
        set { defaults.set(newValue, forKey: Key.showPopupBeforeBreak) }
    }
    public var ringBellOnBreakStart: Bool {
        get { bool(Key.ringBellOnBreakStart, Defaults.ringBellOnBreakStart) }
        set { defaults.set(newValue, forKey: Key.ringBellOnBreakStart) }
    }
    public var ringBellOnBreakEnd: Bool {
        get { bool(Key.ringBellOnBreakEnd, Defaults.ringBellOnBreakEnd) }
        set { defaults.set(newValue, forKey: Key.ringBellOnBreakEnd) }
    }
    public var autoCloseBreakOverlay: Bool {
        get { bool(Key.autoCloseBreakOverlay, Defaults.autoCloseBreakOverlay) }
        set { defaults.set(newValue, forKey: Key.autoCloseBreakOverlay) }
    }
    public var pauseWhenIdle: Bool {
        get { bool(Key.pauseWhenIdle, Defaults.pauseWhenIdle) }
        set { defaults.set(newValue, forKey: Key.pauseWhenIdle) }
    }
    public var pauseWhenFrontmost: Bool {
        get { bool(Key.pauseWhenFrontmost, Defaults.pauseWhenFrontmost) }
        set { defaults.set(newValue, forKey: Key.pauseWhenFrontmost) }
    }
    public var resetWhenWakeup: Bool {
        get { bool(Key.resetWhenWakeup, Defaults.resetWhenWakeup) }
        set { defaults.set(newValue, forKey: Key.resetWhenWakeup) }
    }
    public var captureDesktopImage: Bool {
        get { bool(Key.captureDesktopImage, Defaults.captureDesktopImage) }
        set { defaults.set(newValue, forKey: Key.captureDesktopImage) }
    }
    public var usingSystemScreenLock: Bool {
        get { bool(Key.usingSystemScreenLock, Defaults.usingSystemScreenLock) }
        set { defaults.set(newValue, forKey: Key.usingSystemScreenLock) }
    }

    public var appLanguage: String {
        get { defaults.string(forKey: Key.appLanguage) ?? Defaults.appLanguage }
        set { defaults.set(newValue, forKey: Key.appLanguage) }
    }

    /// Icon drawn as the main panel slider's thumb. Unknown stored values
    /// resolve to the default instead of failing.
    public var sliderIcon: SliderIcon {
        get { SliderIcon(stored: defaults.string(forKey: Key.sliderIcon) ?? "") }
        set { defaults.set(newValue.rawValue, forKey: Key.sliderIcon) }
    }

    /// "system" | "light" | "dark" | "custom"
    public var panelAppearance: String {
        get { defaults.string(forKey: Key.panelAppearance) ?? Defaults.panelAppearance }
        set { defaults.set(newValue, forKey: Key.panelAppearance) }
    }

    public var panelColor: (red: Double, green: Double, blue: Double)? {
        get {
            guard defaults.object(forKey: Key.panelRed) != nil else { return nil }
            return (
                defaults.double(forKey: Key.panelRed),
                defaults.double(forKey: Key.panelGreen),
                defaults.double(forKey: Key.panelBlue)
            )
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.panelRed)
                defaults.removeObject(forKey: Key.panelGreen)
                defaults.removeObject(forKey: Key.panelBlue)
                return
            }
            defaults.set(newValue.red, forKey: Key.panelRed)
            defaults.set(newValue.green, forKey: Key.panelGreen)
            defaults.set(newValue.blue, forKey: Key.panelBlue)
        }
    }

    public var frontmostApps: [String] {
        get { defaults.stringArray(forKey: Key.frontmostApps) ?? [] }
        set { defaults.set(newValue, forKey: Key.frontmostApps) }
    }

    public func set(_ value: Int, for key: String) { defaults.set(value, forKey: key) }
    public func set(_ value: Bool, for key: String) { defaults.set(value, forKey: key) }
    public func set(_ value: Double, for key: String) { defaults.set(value, forKey: key) }

    // Reads never write: a missing key falls back to the default without
    // registering it, so an untouched install has an empty persistent domain.
    private func int(_ key: String, _ fallback: Int) -> Int {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.integer(forKey: key)
    }

    private func double(_ key: String, _ fallback: Double) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.double(forKey: key)
    }

    private func bool(_ key: String, _ fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }
}

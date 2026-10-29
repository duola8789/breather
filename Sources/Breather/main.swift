import AppKit
import BreatherCore

let app = NSApplication.shared

if CommandLine.arguments.contains("--version") {
    print(AppInfo.version)
    exit(0)
}

if CommandLine.arguments.contains("--check-updates") {
    let semaphore = DispatchSemaphore(value: 0)
    UpdateChecker.check(deliveringOn: .global()) { outcome in
        switch outcome {
        case .upToDate(let current):
            print("up-to-date \(current)")
        case .updateAvailable(let version, let url):
            print("update-available \(version) \(url.absoluteString)")
        case .failed(let reason):
            print("failed \(reason)")
        }
        semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + 20) == .timedOut {
        print("failed timeout")
    }
    exit(0)
}

if CommandLine.arguments.contains("--dump-localized") {
    let keys = [
        "StatusItemToolTip", "Break time in X:Y", "Back to work in X:Y",
        "It's time for Relax!", "It's time for Work!", "Back to work now!", "OverlayBackToWork",
        "Resume", "Pause", "Snooze5Minutes", "Done", "SavedPreferences",
        "Preferences", "PreferencesEllipsis", "About", "Support",
        "EmailTheDeveloper", "RateOnMacAppStore", "Statistics",
        "AdvancedConfiguration", "Quit", "Save", "StartAtLogin",
        "KeepThisPopoverOnTop", "RingBellWhenStarting", "Break", "Work",
        "ForceBreak", "ExpectedWorkPeriod", "ExpectedBreakPeriod", "min",
        "minutes", "Preview", "PauseWhenIdleAfter", "ResetTimerAfterWakeup",
        "RingTheBellWhenStarting", "RingTheBellWhenEnding", "Volume",
        "CaptureDesktopImage", "Brightness", "AddApplication", "Remove",
        "Avg.Break", "Avg.Work", "WorkVs.Break", "OneDay", "Version",
    ]
    for key in keys {
        print("\(key)=\(L10n.t(key))")
    }
    exit(0)
}

if let index = CommandLine.arguments.firstIndex(of: "--dump-appicon") {
    let directory = CommandLine.arguments.count > index + 1
        ? CommandLine.arguments[index + 1]
        : NSTemporaryDirectory()
    do {
        try AppIconRenderer.writeIconset(to: URL(fileURLWithPath: directory))
        exit(0)
    } catch {
        FileHandle.standardError.write(Data("appicon: \(error)\n".utf8))
        exit(1)
    }
}

if let index = CommandLine.arguments.firstIndex(of: "--dump-icons") {
    let directory = CommandLine.arguments.count > index + 1
        ? CommandLine.arguments[index + 1]
        : NSTemporaryDirectory()
    exit(IconDump.run(directory: directory))
}

var retainedLock: InstanceLock?
switch InstanceLock.acquire(in: InstanceLock.defaultDirectory()) {
case .acquired(let lock):
    retainedLock = lock
case .alreadyRunning:
    exit(0)
case .unavailable(let error):
    NSLog("Breather: instance lock unavailable, continuing without it: \(error)")
}

let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

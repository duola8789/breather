import Foundation
import BreatherCore

/// Resolves strings from the language the user picked, falling back to the
/// system preference and then to English. Independent of `-AppleLanguages`
/// so the choice can change without restarting the app.
enum L10n {
    static let systemValue = "system"

    static func availableLanguages() -> [String] {
        ["system", "zh-Hans", "en"]
    }

    static func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    private static var bundle: Bundle {
        let chosen = Preferences().appLanguage
        let resolved = resolve(chosen)
        if let path = Bundle.main.path(forResource: resolved, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    private static func resolve(_ chosen: String) -> String {
        guard chosen == systemValue else { return chosen }

        for preferred in Locale.preferredLanguages {
            if preferred.hasPrefix("zh") { return "zh-Hans" }
            if preferred.hasPrefix("en") { return "en" }
        }
        return "en"
    }
}

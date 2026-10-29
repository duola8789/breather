import Foundation

public enum AppInfo {
    public static let version = "1.0.0"
    public static let bundleIdentifier = "com.duola8789.Breather"
    public static let contactEmail = "duola8789@126.com"
    public static let repositoryURL = "https://github.com/duola8789/breather"

    /// Public JSON with {"version", "url"}. Kept in a gist because the source
    /// repository is private, so its Releases API is not anonymously readable.
    public static let updateFeedURL = "https://gist.githubusercontent.com/duola8789/ec17499928fc74cf061f46a75f7df12d/raw/breather-version.json"
}

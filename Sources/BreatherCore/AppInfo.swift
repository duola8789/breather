import Foundation

public enum AppInfo {
    public static let version = "1.1.0"
    public static let bundleIdentifier = "com.duola8789.Breather"
    public static let contactEmail = "duola8789@126.com"
    public static let repositoryURL = "https://github.com/duola8789/breather"

    /// GitHub's public Releases API. The repository is public, so this is
    /// readable without a token; it always reflects the latest actual release,
    /// so there is no separate version file to keep in sync.
    /// The API is authoritative but rate limited to 60 requests/hour per IP,
    /// which a shared corporate NAT can exhaust. The releases page redirects to
    /// the latest tag and is not subject to that limit, so it is the backup.
    public static let updateFeedURL = "https://api.github.com/repos/duola8789/breather/releases/latest"
    public static let updateFeedFallbackURL = "https://github.com/duola8789/breather/releases/latest"
}

import AppKit
import BreatherCore

/// Lightweight update check: fetch a small JSON feed, compare versions, and
/// point the user at the download page. Deliberately does not replace the
/// running app — that needs Sparkle plus a stable signing identity.
enum UpdateChecker {
    struct Feed: Decodable {
        let version: String
        let url: String
    }

    enum Outcome {
        case upToDate(current: String)
        case updateAvailable(version: String, url: URL)
        case failed(String)
    }

    static func check(deliveringOn queue: DispatchQueue = .main, completion: @escaping (Outcome) -> Void) {
        guard let feedURL = URL(string: AppInfo.updateFeedURL) else {
            completion(.failed("no feed configured"))
            return
        }

        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, _, error in
            let result: Outcome
            if let error {
                result = .failed(error.localizedDescription)
            } else if let data, let feed = try? JSONDecoder().decode(Feed.self, from: data) {
                if Version.isNewer(feed.version, than: AppInfo.version), let url = URL(string: feed.url) {
                    result = .updateAvailable(version: feed.version, url: url)
                } else {
                    result = .upToDate(current: AppInfo.version)
                }
            } else {
                result = .failed("invalid feed")
            }
            queue.async { completion(result) }
        }.resume()
    }

}

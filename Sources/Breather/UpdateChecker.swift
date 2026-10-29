import AppKit
import BreatherCore

/// Lightweight update check: read a version feed, compare, and point the user
/// at the download page. Deliberately does not replace the running app — that
/// needs Sparkle plus a stable signing identity.
enum UpdateChecker {
    enum Outcome {
        case upToDate(current: String)
        case updateAvailable(version: String, url: URL)
        case failed(String)
    }

    /// Decodes both feed shapes: GitHub's `releases/latest` payload and the
    /// small JSON we keep as a fallback.
    struct Feed: Decodable {
        let tagName: String?
        let htmlUrl: String?
        let version: String?
        let url: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case version
            case url
        }

        var resolvedVersion: String? {
            guard let raw = version ?? tagName else { return nil }
            return raw.hasPrefix("v") ? String(raw.dropFirst()) : raw
        }

        var resolvedURL: URL? {
            guard let raw = url ?? htmlUrl else { return nil }
            return URL(string: raw)
        }
    }

    static func check(deliveringOn queue: DispatchQueue = .main, completion: @escaping (Outcome) -> Void) {
        guard let primaryURL = URL(string: AppInfo.updateFeedURL) else {
            queue.async { completion(.failed("no feed configured")) }
            return
        }

        fetch(primaryURL) { primary in
            if case .failed = primary, let fallback = URL(string: AppInfo.updateFeedFallbackURL) {
                fetch(fallback) { result in
                    queue.async { completion(result) }
                }
            } else {
                queue.async { completion(primary) }
            }
        }
    }

    private static func fetch(_ url: URL, completion: @escaping (Outcome) -> Void) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failed(error.localizedDescription))
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                completion(.failed("HTTP \(http.statusCode)"))
                return
            }
            guard
                let data,
                let feed = try? JSONDecoder().decode(Feed.self, from: data),
                let version = feed.resolvedVersion,
                let link = feed.resolvedURL
            else {
                completion(.failed("invalid feed"))
                return
            }

            if Version.isNewer(version, than: AppInfo.version) {
                completion(.updateAvailable(version: version, url: link))
            } else {
                completion(.upToDate(current: AppInfo.version))
            }
        }.resume()
    }
}

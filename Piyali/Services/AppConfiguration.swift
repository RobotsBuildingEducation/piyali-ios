import Foundation
struct AppConfiguration {
    let values: [String: Any]
    init(bundle: Bundle = .main) {
        let url = bundle.url(forResource: "AppConfiguration.local", withExtension: "plist") ?? bundle.url(forResource: "AppConfiguration", withExtension: "plist")
        values = url.flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]
    }
    func string(_ key: String, default fallback: String = "") -> String { values[key] as? String ?? fallback }
    func list(_ key: String) -> [String] { values[key] as? [String] ?? [] }
    var auth: URL { URL(string: string("AuthBaseURL", default: "https://piyali-ios-api.robotsbuildingeducation.workers.dev"))! }
    var worker: URL { URL(string: string("WorkerBaseURL", default: "https://piyali.app/api/tts-proxy"))! }
    var web: URL { URL(string: string("WebBaseURL", default: "https://piyali.app"))! }
    // The reference app's actual payment route is /subscribe.
    var subscriptionURL: URL { web.appendingPathComponent("subscribe") }
}

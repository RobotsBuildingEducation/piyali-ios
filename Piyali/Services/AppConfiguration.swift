import Foundation
import FirebaseAILogic
struct AppConfiguration {
    let values: [String: Any]
    init(values: [String: Any]) { self.values = values }
    init(bundle: Bundle = .main) {
        func read(_ name: String) -> [String: Any] {
            bundle.url(forResource:name,withExtension:"plist").flatMap { NSDictionary(contentsOf:$0) as? [String:Any] } ?? [:]
        }
        values = read("AppConfiguration").merging(read("AppConfiguration.local")) { _, override in override }
    }
    func string(_ key: String, default fallback: String = "") -> String { values[key] as? String ?? fallback }
    func list(_ key: String) -> [String] { values[key] as? [String] ?? [] }
    func geminiBackend(live: Bool = false) -> Backend {
        string("GeminiAPIProvider", default:"googleAI") == "googleAI" ? .googleAI() : .agentPlatform(location: live ? string("GeminiLiveLocation",default:"us-central1") : "global")
    }
    var auth: URL { URL(string: string("AuthBaseURL", default: "https://piyali-ios-api.robotsbuildingeducation.workers.dev"))! }
    var worker: URL { URL(string: string("WorkerBaseURL", default: "https://piyali-ios-api.robotsbuildingeducation.workers.dev"))! }
    var web: URL { URL(string: string("WebBaseURL", default: "https://piyali.app"))! }
    // The reference app's actual payment route is /subscribe.
    var subscriptionURL: URL { web.appendingPathComponent("subscribe") }
}

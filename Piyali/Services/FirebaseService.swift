import Foundation
import FirebaseCore
import FirebaseAppCheck
import FirebaseFirestore

final class PiyaliAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app) ?? DeviceCheckProvider(app: app)
        #endif
    }
}
@MainActor final class FirebaseService {
    static let shared = FirebaseService()
    var configured: Bool { Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil && FirebaseApp.app() != nil }
    static func configure() {
        guard FirebaseApp.app() == nil, Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else { return }
        AppCheck.setAppCheckProviderFactory(PiyaliAppCheckFactory())
        FirebaseApp.configure()
    }
    func appCheckHeaders() async throws -> [String: String] {
        guard configured else { throw AppError.message("Add the iOS GoogleService-Info.plist from Firebase to enable online services.") }
        let token = try await AppCheck.appCheck().token(forcingRefresh: false)
        return ["X-Firebase-AppCheck": token.token]
    }
    func load(npub: String) async throws -> LearnerState? {
        guard configured else { return nil }
        let snapshot = try await Firestore.firestore().collection("users").document(npub).getDocument()
        guard let fields = snapshot.data() else { return nil }
        if let data = fields["iosStateJSON"] as? String, let bytes = data.data(using: .utf8) { return try JSONDecoder().decode(LearnerState.self, from: bytes) }
        // Import web preferences and XP without modifying legacy progress structures.
        var state = LearnerState()
        let progress = fields["progress"] as? [String: Any] ?? [:]
        state.name = fields["displayName"] as? String ?? ""
        state.target = progress["targetLang"] as? String ?? "es"
        state.support = progress["supportLang"] as? String ?? fields["language"] as? String ?? "en"
        state.level = progress["cefrLevel"] as? String ?? "Pre-A1"
        state.xpByLanguage = progress["languageXp"] as? [String: Int] ?? [state.target: progress["totalXp"] as? Int ?? 0]
        state.dailyGoal = fields["dailyGoalXp"] as? Int ?? 50
        state.companionName = fields["dailyGoalPetName"] as? String ?? "Piyali"
        return state
    }
    func save(_ state: LearnerState, npub: String) async throws {
        guard configured else { return }
        let json = String(decoding: try JSONEncoder().encode(state), as: UTF8.self)
        // Use a separate versioned field so iOS cannot overwrite the web's nested maps.
        try await Firestore.firestore().collection("users").document(npub).setData([
            "local_npub": npub, "iosStateJSON": json, "iosStateVersion": 1, "iosUpdatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
}

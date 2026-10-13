import Foundation
import FirebaseAuth

struct FirebaseSignInChallenge: Decodable {
    struct Event: Decodable {
        let pubkey: String
        let created_at: Int64
        let kind: Int
        let tags: [[String]]
        let content: String
    }
    let challengeId: String
    let event: Event
    let expiresAt: Double
    func validate(npubHex: String, endpoint: URL, now: Date = Date()) throws {
        guard UUID(uuidString: challengeId) != nil, event.pubkey == npubHex,
              event.kind == 27235, event.content == "Piyali Firebase sign-in",
              event.tags == [["u", endpoint.absoluteString], ["method", "POST"], ["challenge", challengeId]],
              expiresAt > now.timeIntervalSince1970 * 1000,
              expiresAt <= (now.timeIntervalSince1970 + 150) * 1000,
              abs(Double(event.created_at) - now.timeIntervalSince1970) < 150 else {
            throw AppError.message("The server returned an invalid sign-in challenge.")
        }
    }
}

/// Proves the locally held Nostr key to the dedicated Piyali backend. Private keys never leave Keychain.
@MainActor final class FirebaseIdentityService {
    static let shared = FirebaseIdentityService()
    private var pending: (id: UUID, task: Task<Void, Error>)?
    func clearSession() { pending?.task.cancel();if FirebaseService.shared.configured { try? Auth.auth().signOut() } }
    func ensure(_ identity: IdentityService) async throws {
        guard FirebaseService.shared.configured else { return }
        // Serialize SDK sign-ins, including an account switch while an HTTP request is pending.
        if let pending { _ = try? await pending.task.value }
        let npub = identity.npub
        guard !npub.isEmpty else { throw AppError.message("Sign in first.") }
        if Auth.auth().currentUser?.uid == npub { return }
        let task = Task { @MainActor in
            try Auth.auth().signOut()
            let base = AppConfiguration().auth
            guard base.scheme == "https", base.user == nil, base.password == nil else { throw AppError.message("Configure a secure Piyali sign-in server.") }
            let endpoint = base.appendingPathComponent("auth/sign-in")
            let headers = try await FirebaseService.shared.appCheckHeaders()
            let challenge: FirebaseSignInChallenge = try await Self.post(base.appendingPathComponent("auth/challenge"), body: ["npub": npub], headers: headers)
            guard identity.npub == npub else { throw CancellationError() }
            try challenge.validate(npubHex: identity.hex, endpoint: endpoint)
            let signed = try await identity.signEvent(kind: challenge.event.kind, tags: challenge.event.tags, content: challenge.event.content, createdAt: challenge.event.created_at,expectedAuthor:challenge.event.pubkey)
            struct Result: Decodable { let npub: String; let token: String }
            let result: Result = try await Self.post(endpoint, body: ["challengeId": challenge.challengeId, "event": try JSONSerialization.jsonObject(with: JSONEncoder().encode(signed))], headers: headers)
            guard identity.npub == npub, result.npub == npub else { throw CancellationError() }
            let user = try await Auth.auth().signIn(withCustomToken: result.token).user
            guard identity.npub == npub, user.uid == npub else {
                try? Auth.auth().signOut()
                throw CancellationError()
            }
        }
        let taskID = UUID()
        pending = (taskID, task)
        defer { if pending?.id == taskID { pending = nil } }
        try await task.value
    }
    private static func post<T: Decodable>(_ url: URL, body: [String: Any], headers: [String: String]) async throws -> T {
        var request = URLRequest(url: url); request.httpMethod = "POST"; request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw AppError.message("Piyali cloud sign-in is unavailable. Your progress is saved on this iPhone.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

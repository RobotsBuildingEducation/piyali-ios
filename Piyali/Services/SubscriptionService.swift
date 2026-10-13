import Foundation
import StoreKit

@MainActor final class SubscriptionService: ObservableObject {
    @Published private(set) var authorized = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var webAuthorized = false
    @Published private(set) var appleAuthorized = false
    @Published var error: String?
    @Published var busy = false
    @Published private(set) var externalPaymentAllowed = false
    private let config = AppConfiguration()
    private var updates: Task<Void, Never>?
    private var expiryMonitor: Task<Void, Never>?
    var hasAccess: Bool { (webAuthorized && (webExpiry ?? .distantPast) > Date()) || (appleAuthorized && (appleExpiry ?? .distantPast) > Date()) }
    private var identity: IdentityService?
    private var accountID: String?
    private var webExpiry: Date?
    private var appleExpiry: Date?
    init() {
        expiryMonitor = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard let self else { return }; self.checkExpiry()
            }
        }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await self.refreshApple(); await transaction.finish()
                }
            }
        }
    }
    func bind(_ identity: IdentityService) {
        if accountID != identity.npub { webAuthorized = false; appleAuthorized = false; authorized = false; webExpiry = nil; appleExpiry = nil }
        self.identity = identity; accountID = identity.npub
    }
    func refresh() async {
        guard let identity, !identity.npub.isEmpty else { return }
        busy = true; error = nil; defer { busy = false }
        do { products = try await Product.products(for: config.list("SubscriptionProductIDs")) } catch { self.error = error.localizedDescription }
        let storefront = await Storefront.current
        externalPaymentAllowed = config.list("ExternalPaymentStorefronts").contains(storefront?.countryCode ?? "")
        #if DEBUG
        externalPaymentAllowed = true
        #endif
        await refreshApple()
        do { try await restoreWeb() } catch { self.error = error.localizedDescription }
        recomputeAccess()
    }
    func checkExpiry() { recomputeAccess() }
    private func recomputeAccess() {
        if let expiry = webExpiry, expiry <= Date() { webAuthorized = false }
        if let expiry = appleExpiry, expiry <= Date() { appleAuthorized = false }
        authorized = webAuthorized || appleAuthorized
    }
    func refreshApple() async {
        guard let identity, !identity.npub.isEmpty else { appleAuthorized = false; appleExpiry = nil; recomputeAccess(); return }
        let checkingAccount = identity.npub, checkingToken = identity.accountToken
        var valid = false, expiry: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                config.list("SubscriptionProductIDs").contains(transaction.productID),
                transaction.revocationDate == nil,
                let end = transaction.expirationDate, end > Date(),
                transaction.appAccountToken == checkingToken else { continue }
            valid = true; expiry = max(expiry ?? end, end)
        }
        guard accountID == checkingAccount, self.identity?.npub == checkingAccount else { return }
        appleAuthorized = valid; appleExpiry = expiry; recomputeAccess()
    }
    func buy(_ product: Product) async {
        guard let identity else { return }
        busy = true; error = nil; defer { busy = false }
        do {
            switch try await product.purchase(options: [.appAccountToken(identity.accountToken)]) {
            case .success(let result):
                guard case .verified(let transaction) = result else { throw AppError.message("Apple could not verify this purchase.") }
                await refreshApple(); await transaction.finish()
            case .pending: error = "Purchase pending approval."
            case .userCancelled: break
            @unknown default: break
            }
        } catch { self.error = error.localizedDescription }
    }
    func restore() async {
        do { try await AppStore.sync(); await refresh() } catch { self.error = error.localizedDescription }
    }
    private func post(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: config.web.appendingPathComponent("api/patreon/\(path)"))
        request.httpMethod = "POST"; request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else { throw AppError.message(value["error"] as? String ?? "Subscription service unavailable.") }
        return value
    }
    func restoreWeb() async throws {
        guard let identity else { return }
        let checkingAccount = identity.npub
        let challenge = try await post("link-challenge", body: ["npub": checkingAccount, "action": "restore"])
        let proof = try JSONDecoder().decode(PatreonRestoreChallenge.self,from:JSONSerialization.data(withJSONObject:challenge))
        try proof.validate()
        guard identity.npub == checkingAccount, accountID == checkingAccount else { return }
        let event = proof.eventTemplate
        let signed = try identity.sign(kind:event.kind,tags:event.tags,content:event.content,createdAt:event.created_at)
        let signedObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(signed))
        let status = try await post("key-status", body: ["challengeId":proof.challengeId, "signedEvent": signedObject])
        guard identity.npub == checkingAccount, accountID == checkingAccount else { return }
        webAuthorized = status["authorized"] as? Bool == true
        // Revalidate web access on foreground; keep in-memory authorization short lived.
        webExpiry = webAuthorized ? Date().addingTimeInterval(15 * 60) : nil
    }
}

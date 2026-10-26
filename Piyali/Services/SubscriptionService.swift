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
    @Published private(set) var practiceXP:Int?
    private let config: AppConfiguration
    private var webSession: URLSession
    private let ownsWebSession:Bool
    private var revision=UUID()
    private var restoreTask:(id:UUID,task:Task<Void,Error>)?
    @Published private(set) var statusPayload:JSONValue = .object(["authorized":.bool(false),"linked":.bool(false)])
    @Published private(set) var statusResolved=false
    @Published private(set) var statusError=""
    @Published private(set) var result=""
    @Published var browser:SubscriptionBrowserRequest?
    private var browserReturn:SubscriptionBrowserRequest?
    private var awaitingCheckout=false
    var awaiting:Bool{awaitingCheckout || statusPayload["checkoutRequired"].boolean}
    var replacementRequired:Bool{statusPayload["replacementRequired"].boolean}
    private var suppressNetwork:Bool{
        #if DEBUG
        let e=ProcessInfo.processInfo.environment
        return ownsWebSession && e["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil && e["PIYALI_LIVE_API_TESTS"] != "1" && !["localhost","127.0.0.1","::1"].contains(config.web.host ?? "")
        #else
        return false
        #endif
    }
    private var updates: Task<Void, Never>?
    private var expiryMonitor: Task<Void, Never>?
    // The web paywall begins at 300 account XP, not at the first AI activity.
    var hasAccess: Bool { (accountID?.isEmpty == false && practiceXP.map { $0 < 300 } == true) || (webAuthorized && (webExpiry ?? .distantPast) > Date()) || (appleAuthorized && (appleExpiry ?? .distantPast) > Date()) }
    func updatePracticeXP(_ value:Int) { let value=max(0,value);if practiceXP != value { practiceXP=value } }
    private var identity: IdentityService?
    private var accountID: String?
    private var webExpiry: Date?
    private var appleExpiry: Date?
    private var pendingAppleProduct: String?
    private var entitlementCheck = 0
    init(configuration: AppConfiguration = AppConfiguration(), webSession: URLSession? = nil) {
        var selected=configuration
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let raw=env["PIYALI_SUBSCRIPTION_TEST_URL"],let url=URL(string:raw),url.scheme == "http",["127.0.0.1","localhost","::1"].contains(url.host ?? ""){selected=AppConfiguration(values:configuration.values.merging(["WebBaseURL":raw]){_,new in new})}
        #endif
        self.config = selected; self.webSession = webSession ?? URLSession(configuration:.ephemeral);ownsWebSession=webSession == nil
        #if DEBUG
        externalPaymentAllowed = true
        #endif
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
        if accountID != identity.npub { revision=UUID();restoreTask?.task.cancel();restoreTask=nil;browser=nil;browserReturn=nil;awaitingCheckout=false;statusResolved=false;statusError="";result="";statusPayload = .object(["authorized":.bool(false),"linked":.bool(false)]);busy=false;error=nil
            if ownsWebSession{webSession.invalidateAndCancel();webSession=URLSession(configuration:.ephemeral)}
            practiceXP=nil;webAuthorized = false; appleAuthorized = false; authorized = false; webExpiry = nil; appleExpiry = nil; pendingAppleProduct = nil; entitlementCheck += 1 }
        self.identity = identity; accountID = identity.npub
    }
    func refresh() async {
        guard !busy,let identity, !identity.npub.isEmpty else { return }
        if suppressNetwork{statusResolved=true;return}
        let token=revision
        busy = true; error = nil; defer { if revision == token{busy = false} }
        if !suppressLoopback{do { try await loadAppleProducts() } catch { if token == revision{self.error = error.localizedDescription} }}
        guard token == revision else{return}
        let storefront = suppressLoopback ? nil:await Storefront.current
        externalPaymentAllowed = config.list("ExternalPaymentStorefronts").contains(storefront?.countryCode ?? "")
        #if DEBUG
        externalPaymentAllowed = true
        #endif
        if !suppressLoopback{await refreshApple()}
        guard token == revision else{return}
        do { try await restoreWeb() } catch { if token == revision{self.error = error.localizedDescription;statusError="unavailable";statusResolved=true} }
        recomputeAccess()
    }
    func checkExpiry() { recomputeAccess() }
    private func recomputeAccess() {
        if let expiry = webExpiry, expiry <= Date() { webAuthorized = false }
        if let expiry = appleExpiry, expiry <= Date() { appleAuthorized = false }
        authorized = webAuthorized || appleAuthorized
    }
    func refreshApple() async {
        entitlementCheck += 1; let check = entitlementCheck
        guard let identity, !identity.npub.isEmpty else { appleAuthorized = false; appleExpiry = nil; recomputeAccess(); return }
        let checkingAccount = identity.npub, checkingToken = identity.accountToken
        var valid = false, expiry: Date?; var activeProducts: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                config.list("SubscriptionProductIDs").contains(transaction.productID),
                transaction.revocationDate == nil, !transaction.isUpgraded,
                let end = transaction.expirationDate, end > Date(),
                transaction.appAccountToken == checkingToken else { continue }
            activeProducts.insert(transaction.productID)
            valid = true; expiry = max(expiry ?? end, end)
        }
        guard entitlementCheck == check, accountID == checkingAccount, self.identity?.npub == checkingAccount else { return }
        if let pendingAppleProduct, activeProducts.contains(pendingAppleProduct) { self.pendingAppleProduct = nil; error = nil }
        appleAuthorized = valid; appleExpiry = expiry; recomputeAccess()
    }
    func buy(_ product: Product) async {
        guard !busy, let identity, !identity.npub.isEmpty, accountID == identity.npub else { return }
        guard config.list("SubscriptionProductIDs").contains(product.id) else { error = "This subscription plan is unavailable."; return }
        let token=revision
        busy = true; error = nil; defer { if revision == token{busy = false} }
        do {
            switch try await product.purchase(options: [.appAccountToken(identity.accountToken)]) {
            case .success(let result):
                guard case .verified(let transaction) = result else { throw AppError.message("Apple could not verify this purchase.") }
                await refreshApple(); await transaction.finish()
            case .pending: if revision == token{pendingAppleProduct = product.id; error = "Purchase pending approval."}
            case .userCancelled: break
            @unknown default: break
            }
        } catch { if revision == token{self.error = error.localizedDescription} }
    }
    func loadAppleProducts() async throws {
        products = try await Product.products(for:config.list("SubscriptionProductIDs")).sorted { $0.price < $1.price }
    }
    func restoreApple() async throws {
        guard let identity, !identity.npub.isEmpty else { throw AppError.message("Sign in before restoring purchases.") }
        try await AppStore.sync(); await refreshApple()
    }
    func restore() async {
        guard !busy, let identity, !identity.npub.isEmpty else { return }
        let token=revision
        busy = true; error = nil; defer { if token == revision{busy = false} }
        var failures: [String] = []
        do { try await AppStore.sync() } catch { failures.append("Apple: " + error.localizedDescription) }
        guard token == revision else{return}
        await refreshApple()
        do { try await restoreWeb() } catch { failures.append("Web: " + error.localizedDescription) }
        guard token == revision else{return}
        recomputeAccess()
        if !authorized { error = failures.isEmpty ? "No active subscription is linked to this Piyali key." : failures.joined(separator:"\n") }
    }
    deinit { updates?.cancel(); expiryMonitor?.cancel() }
    struct RequestFailure:LocalizedError {let code:String;var errorDescription:String?{code}}
    private func post(_ path:String,body:[String:Any])async throws->[String:Any]{
        var request=URLRequest(url:config.web.appendingPathComponent("api/patreon/\(path)"));request.httpMethod="POST";request.timeoutInterval=25
        request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.setValue("application/json",forHTTPHeaderField:"Accept")
        request.httpBody=try JSONSerialization.data(withJSONObject:body)
        let(data,response)=try await webSession.data(for:request),value=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] ?? [:]
        guard let response=response as? HTTPURLResponse,(200..<300).contains(response.statusCode) else{throw RequestFailure(code:value["error"] as? String ?? "patreon_unavailable")};return value
    }
    private func proof(_ action:String,account:String,token:UUID)async throws->[String:Any]{
        guard let identity,identity.npub == account,revision == token else{throw CancellationError()}
        let challenge=try await post("link-challenge",body:["npub":account,"action":action]),proof=try JSONDecoder().decode(PatreonRestoreChallenge.self,from:JSONSerialization.data(withJSONObject:challenge));try proof.validate(action:action)
        guard identity.npub == account,revision == token else{throw CancellationError()}
        let e=proof.eventTemplate,signed=try await identity.signEvent(kind:e.kind,tags:e.tags,content:e.content,createdAt:e.created_at,expectedAuthor:identity.hex)
        guard identity.npub == account,revision == token else{throw CancellationError()}
        return ["challengeId":proof.challengeId,"signedEvent":try JSONSerialization.jsonObject(with:JSONEncoder().encode(signed))]
    }
    private func receive(_ status:[String:Any]){
        statusPayload=JSONValue.foundation(status);statusResolved=true;statusError=""
        webAuthorized=statusPayload["authorized"] == .bool(true)
        webExpiry=webAuthorized ? Date().addingTimeInterval(15*60):nil
        if webAuthorized || replacementRequired{awaitingCheckout=false}
        recomputeAccess()
    }
    func restoreWeb()async throws{
        guard let account=accountID,!account.isEmpty else{return}
        if suppressNetwork{statusResolved=true;return}
        if let restoreTask{try await restoreTask.task.value;return}
        let token=revision,id=UUID(),task=Task{[weak self] in
            guard let self else{return}
            let signed=try await self.proof("restore",account:account,token:token),status=try await self.post("key-status",body:signed)
            guard self.revision == token,self.accountID == account else{throw CancellationError()};self.receive(status)
        }
        restoreTask=(id,task);defer{if restoreTask?.id == id{restoreTask=nil}}
        do{try await task.value}catch{if revision == token{statusResolved=true;statusError="unavailable";statusPayload=statusPayload.setting("error",.string("patreon_unavailable"))};throw error}
    }
    /// Safari owns checkout cookies. A fresh signed link lets the server verify
    /// the now-paid membership when a key restore has not linked it yet.
    func checkMembership(language:String)async{
        guard !busy else{return};let token=revision;busy=true;statusError=""
        do{try await restoreWeb()}catch{if token == revision{busy=false;statusError="unavailable"};return}
        guard token == revision else{return};busy=false
        if awaiting,!webAuthorized,!replacementRequired{await connect(language:language)}
    }
    func connect(language:String)async{
        guard !busy,let account=accountID,!account.isEmpty else{return};let token=revision
        busy=true;statusError="";error=nil;defer{if token == revision{busy=false}}
        do{
            var body=try await proof("link",account:account,token:token);body["plan"]="annual";body["returnMode"]="page";body["supportLanguage"]=language
            let value=try await post("link-start",body:body)
            guard token == revision else{return}
            let url=try SubscriptionBrowserRequest.authorizeURL(value["authorizeUrl"] as? String ?? "",web:config.web,allowLoopback:suppressLoopback)
            let request=SubscriptionBrowserRequest(url:url,account:account,revision:token,kind:.connect);browserReturn=request;browser=request;awaitingCheckout=true
        }catch{if token == revision{statusError="unavailable";self.error=error.localizedDescription}}
    }
    private var suppressLoopback:Bool{
        #if DEBUG
        let e=ProcessInfo.processInfo.environment;return e["PIYALI_OFFLINE_TESTS"] == "1" && UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil && ["localhost","127.0.0.1","::1"].contains(config.web.host ?? "")
        #else
        return false
        #endif
    }
    func checkout(){guard let account=accountID else{return};let url=suppressLoopback ? config.web.appendingPathComponent("checkout"):URL(string:"https://subscribe.piyali.app/")!;let request=SubscriptionBrowserRequest(url:url,account:account,revision:revision,kind:.checkout);browserReturn=request;browser=request;awaitingCheckout=true}
    func browserClosed(){guard let request=browserReturn else{return};browser=nil;browserReturn=nil;guard request.account == accountID,request.revision == revision else{return};Task{[weak self]in guard let self,self.revision == request.revision,self.accountID == request.account else{return};do{try await self.restoreWeb()}catch{}}}
    func replaceLinkedKey()async{await signedAction("replace",endpoint:"replace-link")}
    func disconnectWeb()async{await signedAction("disconnect",endpoint:"disconnect")}
    private func signedAction(_ action:String,endpoint:String)async{
        guard !busy,let account=accountID,!account.isEmpty else{return};let token=revision
        busy=true;statusError="";error=nil;defer{if token == revision{busy=false}}
        do{let body=try await proof(action,account:account,token:token),value=try await post(endpoint,body:body);guard token == revision else{return}
            if action == "disconnect"{receive(["authorized":false,"linked":false,"subscription":NSNull()]);awaitingCheckout=false;result=""}
            else{guard value["authorized"] as? Bool == true else{throw RequestFailure(code:value["error"] as? String ?? "replacement_failed")};receive(value);result="connected"}
        }catch{if token == revision{let code=(error as? RequestFailure)?.code ?? "unavailable";statusError=code;self.error=error.localizedDescription
            if action == "replace",["replacement_expired","replacement_state_changed","membership_not_active"].contains(code){statusPayload = .object(["authorized":.bool(false),"linked":.bool(false)]);awaitingCheckout=false}
        }}
    }
    func cancelReplacement()async{
        guard !busy else{return};let token=revision;busy=true;defer{if token == revision{busy=false}}
        do{_=try await post("cancel-replacement",body:[:]);guard token == revision else{return};statusPayload = .object(["authorized":.bool(false),"linked":.bool(false)]);awaitingCheckout=false;statusError="";result=""}catch{if token == revision{statusError="unavailable";self.error=error.localizedDescription}}
    }
}

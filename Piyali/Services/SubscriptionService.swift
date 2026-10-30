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
    private enum WebCheck:Equatable {case restore,passive,forced,renewal}
    private var webTask:(id:UUID,mode:WebCheck,task:Task<Void,Error>)?
    private var webEpoch=UUID()
    private var statusMutation:UUID?
    private var webRetryAt:Date?
    private var applicationActive=false
    private let now:()->Date
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
    var hasAccess: Bool { (accountID?.isEmpty == false && practiceXP.map { $0 < 300 } == true) || (webAuthorized && (webExpiry ?? .distantPast) > now()) || (appleAuthorized && (appleExpiry ?? .distantPast) > now()) }
    func updatePracticeXP(_ value:Int) { let value=max(0,value);if practiceXP != value { practiceXP=value } }
    private var identity: IdentityService?
    private var accountID: String?
    private var webExpiry: Date?
    private var appleExpiry: Date?
    private var pendingAppleProduct: String?
    private var entitlementCheck = 0
    init(configuration: AppConfiguration = AppConfiguration(), webSession: URLSession? = nil, now:@escaping()->Date = Date.init) {
        var selected=configuration
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let raw=env["PIYALI_SUBSCRIPTION_TEST_URL"],let url=URL(string:raw),url.scheme == "http",["127.0.0.1","localhost","::1"].contains(url.host ?? ""){selected=AppConfiguration(values:configuration.values.merging(["WebBaseURL":raw]){_,new in new})}
        #endif
        self.config = selected; self.webSession = webSession ?? URLSession(configuration:.ephemeral);ownsWebSession=webSession == nil;self.now=now
        #if DEBUG
        externalPaymentAllowed = true
        #endif
        expiryMonitor = Task { [weak self] in
            while !Task.isCancelled {
                do {try await Task.sleep(for:.seconds(30))} catch {return}
                guard let self else { return };self.checkExpiry();await self.maintainWebAccess()
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
        if accountID != identity.npub { revision=UUID();invalidateWebChecks();statusMutation=nil;webRetryAt=nil;browser=nil;browserReturn=nil;awaitingCheckout=false;statusResolved=false;statusError="";result="";statusPayload = .object(["authorized":.bool(false),"linked":.bool(false)]);busy=false;error=nil
            if ownsWebSession{webSession.invalidateAndCancel();webSession=URLSession(configuration:.ephemeral)}
            practiceXP=nil;webAuthorized = false; appleAuthorized = false; authorized = false; webExpiry = nil; appleExpiry = nil; pendingAppleProduct = nil; entitlementCheck += 1 }
        self.identity = identity; accountID = identity.npub
    }
    func refresh(forceWeb:Bool=false) async {
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
        do { try await refreshWeb(force:forceWeb) } catch { if token == revision{self.error = error.localizedDescription;statusError="unavailable";statusResolved=true} }
        recomputeAccess()
    }
    func checkExpiry() { recomputeAccess() }
    private func recomputeAccess() {
        if let expiry = webExpiry, expiry <= now() { webAuthorized = false }
        if let expiry = appleExpiry, expiry <= now() { appleAuthorized = false }
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
                let end = transaction.expirationDate, end > now(),
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
    deinit { updates?.cancel(); expiryMonitor?.cancel();webTask?.task.cancel() }
    struct RequestFailure:LocalizedError {let code:String;var errorDescription:String?{code}}
    private struct WebResponse {let status:Int,value:[String:Any]}
    private func request(_ path:String,body:[String:Any]=[:],method:String="POST",account:String?=nil)async throws->WebResponse{
        var request=URLRequest(url:config.web.appendingPathComponent("api/patreon/\(path)"));request.httpMethod=method;request.timeoutInterval=25;request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json",forHTTPHeaderField:"Accept")
        if let account=account ?? accountID,!account.isEmpty{request.setValue(account,forHTTPHeaderField:"X-Piyali-Npub")}
        if method == "POST"{request.setValue("application/json",forHTTPHeaderField:"Content-Type");request.httpBody=try JSONSerialization.data(withJSONObject:body)}
        let(data,response)=try await webSession.data(for:request)
        guard let response=response as? HTTPURLResponse else{throw RequestFailure(code:"patreon_unavailable")}
        return WebResponse(status:response.statusCode,value:(try? JSONSerialization.jsonObject(with:data)) as? [String:Any] ?? [:])
    }
    private func post(_ path:String,body:[String:Any])async throws->[String:Any]{
        let response=try await request(path,body:body)
        guard (200..<300).contains(response.status) else{throw RequestFailure(code:response.value["error"] as? String ?? "patreon_unavailable")};return response.value
    }
    private var hasWebSession:Bool{
        let url=config.web.appendingPathComponent("api/patreon/status")
        return (webSession.configuration.httpCookieStorage?.cookies(for:url) ?? []).contains{cookie in cookie.name == "__session" && (cookie.value.removingPercentEncoding ?? cookie.value).hasPrefix("auth-session.")}
    }
    private func proof(_ action:String,account:String,token:UUID)async throws->[String:Any]{
        guard let identity,identity.npub == account,revision == token else{throw CancellationError()}
        let challenge=try await post("link-challenge",body:["npub":account,"action":action]),proof=try JSONDecoder().decode(PatreonRestoreChallenge.self,from:JSONSerialization.data(withJSONObject:challenge));try proof.validate(action:action)
        guard identity.npub == account,revision == token else{throw CancellationError()}
        let e=proof.eventTemplate,signed=try await identity.signEvent(kind:e.kind,tags:e.tags,content:e.content,createdAt:e.created_at,expectedAuthor:identity.hex)
        guard identity.npub == account,revision == token else{throw CancellationError()}
        return ["challengeId":proof.challengeId,"signedEvent":try JSONSerialization.jsonObject(with:JSONEncoder().encode(signed))]
    }
    private func receive(_ status:[String:Any],renewLease:Bool=true){
        statusPayload=JSONValue.foundation(status);statusResolved=true;statusError=""
        let granted=statusPayload["authorized"] == .bool(true)
        if !granted{webAuthorized=false;webExpiry=nil}
        else if renewLease{webAuthorized=true;webExpiry=now().addingTimeInterval(15*60);webRetryAt=nil}
        else{webAuthorized=webAuthorized && (webExpiry ?? .distantPast)>now()}
        if webAuthorized || replacementRequired{awaitingCheckout=false}
        recomputeAccess()
    }
    private func invalidateWebChecks(){webEpoch=UUID();webTask?.task.cancel();webTask=nil}
    private func beginStatusMutation()->UUID{invalidateWebChecks();let id=UUID();statusMutation=id;return id}
    private func finishStatusMutation(_ id:UUID){if statusMutation == id{statusMutation=nil}}
    func restoreWeb()async throws{try await checkWeb(.restore)}
    func refreshWeb(force:Bool=false)async throws{try await checkWeb(force ? .forced:.passive)}
    private func checkWeb(_ mode:WebCheck)async throws{
        guard let account=accountID,!account.isEmpty else{return}
        if suppressNetwork{statusResolved=true;return}
        guard statusMutation == nil else{throw CancellationError()}
        let requestedRevision=revision,requestedEpoch=webEpoch
        while let existing=webTask{
            do{try await existing.task.value}catch{
                guard mode == .forced,existing.mode != .forced else{throw error}
            }
            if webTask?.id == existing.id{webTask=nil}
            guard statusMutation == nil,accountID == account,revision == requestedRevision,webEpoch == requestedEpoch else{throw CancellationError()}
            // A manual force must follow a cached read. Every other caller can
            // share the in-flight authority check without a second signature.
            if mode != .forced || existing.mode == .forced{return}
        }
        let token=requestedRevision,epoch=requestedEpoch,id=UUID()
        let task=Task{[weak self] in
            guard let self else{return}
            try await self.performWebCheck(mode,account:account,token:token,epoch:epoch)
        }
        webTask=(id,mode,task);defer{if webTask?.id == id{webTask=nil}}
        do{try await task.value}catch{
            if revision == token,webEpoch == epoch,!(error is CancellationError){
                statusResolved=true;statusError="unavailable";statusPayload=statusPayload.setting("error",.string("patreon_unavailable"));webRetryAt=now().addingTimeInterval(60)
            }
            throw error
        }
    }
    private func validateWebScope(_ account:String,_ token:UUID,_ epoch:UUID)throws{
        try Task.checkCancellation()
        guard revision == token,webEpoch == epoch,accountID == account,statusMutation == nil else{throw CancellationError()}
    }
    private func performRestore(account:String,token:UUID,epoch:UUID)async throws{
        let signed=try await proof("restore",account:account,token:token)
        try validateWebScope(account,token,epoch)
        let status=try await post("key-status",body:signed)
        try validateWebScope(account,token,epoch);receive(status)
    }
    private func performWebCheck(_ mode:WebCheck,account:String,token:UUID,epoch:UUID)async throws{
        try validateWebScope(account,token,epoch)
        if mode == .restore{try await performRestore(account:account,token:token,epoch:epoch);return}
        if !hasWebSession{
            if mode == .renewal,identity?.isRemote == true{throw RequestFailure(code:"not_authenticated")}
            try await performRestore(account:account,token:token,epoch:epoch)
            guard mode == .forced,hasWebSession else{return}
        }
        let response=try await request(mode == .forced ? "refresh-status":"status",method:mode == .forced ? "POST":"GET",account:account)
        try validateWebScope(account,token,epoch)
        if response.status == 429{
            // A cached rate-limit response may revoke a grant, but cannot
            // manufacture a new 15-minute lease or prolong the existing one.
            receive(response.value,renewLease:false)
            let milliseconds=(response.value["retryAfterMs"] as? Double) ?? 60_000
            let delay=milliseconds.isFinite ? min(16*60*60,max(1.5,milliseconds/1000)):60
            webRetryAt=now().addingTimeInterval(delay);return
        }
        guard (200..<300).contains(response.status) else{throw RequestFailure(code:response.value["error"] as? String ?? "patreon_unavailable")}
        receive(response.value)
        if (mode == .passive || mode == .renewal),!webAuthorized,!statusPayload["linked"].boolean,!replacementRequired,!awaiting{
            // An expired/revoked cookie is never an entitlement. Local keys can
            // silently restore their own mapping; remote signing stays explicit.
            if identity?.isRemote != true{try await performRestore(account:account,token:token,epoch:epoch)}
        }
    }
    func setApplicationActive(_ active:Bool){applicationActive=active}
    func maintainWebAccess()async{
        checkExpiry()
        guard applicationActive,!busy,statusMutation == nil,let expiry=webExpiry,expiry.timeIntervalSince(now())<=60,
              webRetryAt.map({$0<=now()}) ?? true,!suppressNetwork else{return}
        // Cookie-based status reads avoid periodic remote-signer approval prompts.
        guard hasWebSession || identity?.isRemote != true else{return}
        let token=revision,epoch=webEpoch;webRetryAt=now().addingTimeInterval(60)
        do{try await checkWeb(.renewal)}catch{if revision == token,webEpoch == epoch{checkExpiry()}}
    }
    /// Safari owns checkout cookies. A fresh signed link lets the server verify
    /// the now-paid membership when a key restore has not linked it yet.
    func checkMembership(language:String)async{
        guard !busy else{return};let token=revision;busy=true;statusError=""
        do{try await refreshWeb(force:true)}catch{if token == revision{busy=false;statusError="unavailable"};return}
        guard token == revision else{return};busy=false
        if awaiting,!webAuthorized,!replacementRequired{await connect(language:language)}
    }
    func connect(language:String)async{
        guard !busy,let account=accountID,!account.isEmpty else{return};let token=revision
        busy=true;statusError="";error=nil;defer{if token == revision{busy=false}}
        do{
            var body=try await proof("link",account:account,token:token);guard token == revision else{return};body["plan"]="annual";body["returnMode"]="page";body["supportLanguage"]=language
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
        let mutation=beginStatusMutation()
        busy=true;statusError="";error=nil;defer{finishStatusMutation(mutation);if token == revision{busy=false}}
        do{let body=try await proof(action,account:account,token:token);guard token == revision,statusMutation == mutation else{return};let value=try await post(endpoint,body:body);guard token == revision else{return}
            if action == "disconnect"{receive(["authorized":false,"linked":false,"subscription":NSNull()]);awaitingCheckout=false;result=""}
            else{guard value["authorized"] as? Bool == true else{throw RequestFailure(code:value["error"] as? String ?? "replacement_failed")};receive(value);result="connected"}
        }catch{if token == revision{let code=(error as? RequestFailure)?.code ?? "unavailable";statusError=code;self.error=error.localizedDescription
            if action == "replace",["replacement_expired","replacement_state_changed","membership_not_active"].contains(code){receive(["authorized":false,"linked":false]);statusError=code;awaitingCheckout=false}
        }}
    }
    func cancelReplacement()async{
        guard !busy else{return};let token=revision,mutation=beginStatusMutation();busy=true;defer{finishStatusMutation(mutation);if token == revision{busy=false}}
        do{_=try await post("cancel-replacement",body:[:]);guard token == revision else{return};statusPayload = .object(["authorized":.bool(false),"linked":.bool(false)]);awaitingCheckout=false;statusError="";result=""}catch{if token == revision{statusError="unavailable";self.error=error.localizedDescription}}
    }
}

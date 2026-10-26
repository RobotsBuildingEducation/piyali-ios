import Foundation
import NostrSDK
import CashuSwift
import secp256k1

@MainActor final class WalletService:ObservableObject {
    @Published private(set) var busy=false
    @Published private(set) var ready=false
    @Published private(set) var canCreate=false
    @Published private(set) var canRestore=false
    @Published private(set) var depositID=""
    @Published private(set) var needsReceivingInfo=false
    @Published private(set) var balance=0
    @Published private(set) var invoice=""
    @Published private(set) var automatic=AutomaticTipJournal()
    @Published private(set) var tipPreview:WalletTipPreview?
    @Published private(set) var archivedCount=0
    @Published private(set) var invoiceExpired=false
    @Published private(set) var pending=false
    @Published private(set) var status=""
    @Published private(set) var error:String?
    private static var leases:[String:UUID]=[:]
    private let vault=WalletVault()
    private let bootstrap:NostrRelayClient
    private let mintAPI:any WalletMintNetworking
    private let now:()->Date
    private let fixedRelays:Bool
    private var state:WalletPrivateState?
    private var owner=""
    private var generation=UUID()
    private var task:Task<Void,Error>?
    init(client:NostrRelayClient? = nil,mint:(any WalletMintNetworking)? = nil,now:@escaping ()->Date = Date.init) {
        var selected=client
        #if DEBUG
        if selected == nil,ProcessInfo.processInfo.environment["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:ProcessInfo.processInfo.environment["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let value=ProcessInfo.processInfo.environment["PIYALI_WALLET_TEST_RELAY"],let url=URL(string:value),["localhost","127.0.0.1","::1"].contains(url.host ?? ""),let relay=try? BunkerConnection.relay(value,allowLoopback:true) { selected=NostrRelayClient(relays:[relay],timeout:.seconds(2)) }
        #endif
        bootstrap=selected ?? NostrRelayClient();fixedRelays=selected != nil;mintAPI=mint ?? CashuHTTPClient();self.now=now
    }
    func cancel(clear:Bool = false) { generation=UUID();task?.cancel();task=nil;busy=false;if clear { state=nil;owner="";ready=false;canCreate=false;canRestore=false;depositID="";needsReceivingInfo=false;balance=0;invoice="";automatic=AutomaticTipJournal();tipPreview=nil;archivedCount=0;invoiceExpired=false;pending=false;status="";error=nil } }
    private func check(_ identity:IdentityService,_ version:UUID) throws { try Task.checkCancellation();guard version == generation,identity.hex == owner,!owner.isEmpty else { throw CancellationError() } }
    private func save() throws { state?.ledger.compact();guard let state,state.owner == owner else { throw CancellationError() };try vault.save(state);automatic=try vault.automaticTips(owner:owner);ready=state.configurationPublished;canRestore=state.legacySource != nil && !state.configurationPublished;needsReceivingInfo=state.configurationPublished && state.receivingInfo == nil;depositID=state.invoice?["quote"]["quote"].string ?? "";invoice=state.invoice?["quote"]["request"].string ?? "";pending=state.pending != nil;archivedCount=state.archivedInvoices?.count ?? 0;invoiceExpired=state.invoice.map { $0["quote"]["expiry"].number <= now().timeIntervalSince1970 } ?? false }
    private func authenticate(_ identity:IdentityService) -> NostrRelayClient.Authenticate { let author=owner;return { relay,challenge in try await identity.signEvent(kind:22242,tags:[["relay",relay],["challenge",challenge]],content:"",expectedAuthor:author) } }
    private var client:NostrRelayClient { fixedRelays ? bootstrap : NostrRelayClient(relays:state?.relays.isEmpty == false ? state!.relays : ["wss://relay.ditto.pub","wss://relay.primal.net","wss://nos.lol"]) }
    private func run(_ identity:IdentityService,_ action:@escaping @MainActor (UUID) async throws -> Void) async throws {
        guard !busy,!identity.hex.isEmpty else { throw WalletContract.Failure.pending }
        let account=identity.hex
        guard Self.leases[account] == nil else { error=WalletContract.Failure.pending.localizedDescription;throw WalletContract.Failure.pending }
        let lease=UUID();Self.leases[account]=lease
        defer { if Self.leases[account] == lease { Self.leases.removeValue(forKey:account) } }
        if owner != account { cancel(clear:true);owner=account }
        state=try vault.load(owner:account)
        if state != nil { try save() }
        generation=UUID();let version=generation;busy=true;error=nil
        let active=Task { try await action(version) };task=active
        defer { if generation == version { busy=false;task=nil } }
        do { try await withTaskCancellationHandler { try await active.value } onCancel:{ active.cancel() } }
        catch is CancellationError { throw CancellationError() }
        catch { if generation == version { self.error=(error as? WalletContract.Failure)?.localizedDescription ?? (error as? AppError)?.localizedDescription ?? "The wallet request could not be completed. Saved recovery data has been retained. Refresh or recover before starting another payment." };throw error }
    }
    private func quoteState(_ value:JSONValue) throws -> String {
        if ["UNPAID","PAID","ISSUED"].contains(value["state"].string) { return value["state"].string }
        if value["state"] == .null || value["state"].string.isEmpty,case .bool(let paid)=value["paid"] { return paid ? "PAID" : "UNPAID" }
        throw WalletContract.Failure.invalidToken
    }
    private func signed(kind:Int,payload:JSONValue,tags:[[String]] = [],identity:IdentityService,version:UUID) async throws -> NostrEventPayload {
        try check(identity,version);let content=try await identity.encryptWallet(payload.json,expectedAuthor:owner);try check(identity,version)
        let event=try await identity.signEvent(kind:kind,tags:tags,content:content,expectedAuthor:owner);try check(identity,version);return event
    }
    func refresh(identity:IdentityService) async throws {
        try await run(identity) { version in
            var discoveredRelays:[String]=[]
            var discovery=try await self.bootstrap.querySnapshots(filter:["kinds":[10019,10002],"authors":[self.owner]],authenticate:self.authenticate(identity));try self.check(identity,version)
            if self.state == nil,!self.fixedRelays {
                let latest=discovery.filter { $0.kind == 10019 }.max { $0.created_at < $1.created_at }
                let advertised=latest?.tags.filter { $0.first == "relay" && $0.count >= 2 }.compactMap { try? BunkerConnection.relay($0[1]) } ?? []
                let fallback=discovery.filter { $0.kind == 10002 }.max { $0.created_at < $1.created_at }?.tags.filter { $0.first == "r" && $0.count >= 2 && ($0.count == 2 || $0[2] == "read") }.compactMap { try? BunkerConnection.relay($0[1]) } ?? []
                let urls=Array(Set(advertised.isEmpty ? fallback : advertised).prefix(16))
                discoveredRelays=urls
                if !urls.isEmpty { discovery += try await NostrRelayClient(relays:urls).querySnapshots(filter:["kinds":[17375,375,37375,7375,7376,5,37513,7374],"authors":[self.owner]],authenticate:self.authenticate(identity));try self.check(identity,version) }
            }
            let events=try await self.client.querySnapshots(filter:["kinds":[17375,375,37375,7375,7376,5,37513,7374],"authors":[self.owner]],authenticate:self.authenticate(identity));try self.check(identity,version)
            let all=Dictionary((discovery+events).filter { $0.pubkey == self.owner }.map { ($0.id,$0) },uniquingKeysWith:{ first,_ in first }).values
            guard all.count < 2048 else { throw AppError.message("This wallet needs a complete relay history before it can be opened. Its funds have not been changed.") }
            let modern=all.filter { $0.kind == 17375 }.sorted { $0.created_at == $1.created_at ? $0.id < $1.id : $0.created_at > $1.created_at }
            let backups=all.filter { [375,37375,37513].contains($0.kind) }.sorted { $0.created_at == $1.created_at ? $0.id < $1.id : $0.created_at > $1.created_at }
            var importedConfiguration:(NostrEventPayload,ImportedWalletConfiguration)?
            for candidate in modern.first.map({ [$0] }) ?? backups {
                do {
                    let clear=try await identity.decryptWallet(candidate.content,expectedAuthor:self.owner);try self.check(identity,version)
                    let imported=try ImportedWalletConfiguration(JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8)))
                    importedConfiguration=(candidate,imported);break
                } catch is CancellationError { throw CancellationError() }
                catch { if candidate.kind == 17375 { throw error } }
            }
            if let (configuration,imported)=importedConfiguration {
                let importedKeys=try imported.privateKeys.map { value -> Keypair in guard let key=Keypair(hex:value) else { throw WalletContract.Failure.invalidToken };return key }
                let safeKeys=identity.isRemote ? importedKeys.filter { $0.publicKey.hex != self.owner } : importedKeys
                guard !safeKeys.isEmpty else { throw AppError.message("This older wallet backs up its main identity key. Restore it using a local key before migrating its receiving setup; the encrypted records have not been changed.") }
                let advertised=discovery.filter { $0.kind == 10019 }.max { $0.created_at < $1.created_at }?.tag("pubkey") ?? ""
                let selected=safeKeys.first { $0.publicKey.hex == advertised || "02"+$0.publicKey.hex == advertised } ?? safeKeys.first { $0.privateKey.hex == self.state?.walletPrivateKey } ?? safeKeys.first { $0.publicKey.hex != self.owner } ?? safeKeys[0]
                if self.state == nil { self.state=WalletPrivateState(owner:self.owner,walletPrivateKey:selected.privateKey.hex,mints:imported.mints,relays:discoveredRelays) }
                let priorKeys=[self.state!.walletPrivateKey]+(self.state?.additionalReceivingKeys ?? [])
                let keys=Array(Set(priorKeys+safeKeys.map { $0.privateKey.hex })).sorted();self.state?.walletPrivateKey=selected.privateKey.hex;self.state?.additionalReceivingKeys=keys.filter { $0 != selected.privateKey.hex }
                let mints=Array(Set((self.state?.mints ?? [])+imported.mints)).sorted();guard mints.count <= 16 else { throw WalletContract.Failure.invalidMint };self.state?.mints=mints
                if configuration.kind == 17375 { self.state?.configurationPublished=true } else if self.state?.configurationPublished != true { self.state?.legacySource=String(configuration.kind) }
            }
            if self.state == nil,all.contains(where:{ [7375,7374].contains($0.kind) }) {
                var mints=Set<String>()
                for event in all where [7375,7374].contains(event.kind) {
                    let clear=try await identity.decryptWallet(event.content,expectedAuthor:self.owner);try self.check(identity,version)
                    let payload=try JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8))
                    if event.kind == 7375 { let token=try WalletTokenRecord(id:event.id,payload:WalletImport.token(payload,mintTag:event.tag("mint")));mints.insert(token.mint) }
                    else if let quote=try? WalletImport.quote(payload,eventID:event.id) { mints.insert(quote["mint"].string) }
                }
                if !mints.isEmpty,mints.count <= 16,let key=Keypair() {
                    self.state=WalletPrivateState(owner:self.owner,walletPrivateKey:key.privateKey.hex,mints:mints.sorted(),relays:discoveredRelays);self.state?.legacySource="tokens-only"
                }
            }
            if self.state != nil {
                var keys=Set([self.state!.walletPrivateKey]+(self.state?.additionalReceivingKeys ?? []))
                for backup in backups where backup.kind == 375 {
                    do {
                        let clear=try await identity.decryptWallet(backup.content,expectedAuthor:self.owner);try self.check(identity,version)
                        let config=try ImportedWalletConfiguration(JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8)))
                        for value in config.privateKeys { if let key=Keypair(hex:value),!identity.isRemote || key.publicKey.hex != self.owner { keys.insert(value) } }
                        let mints=Array(Set((self.state?.mints ?? [])+config.mints)).sorted();guard mints.count <= 16 else { throw WalletContract.Failure.invalidMint };self.state?.mints=mints
                    } catch is CancellationError { throw CancellationError() } catch { /* A malformed old backup cannot replace the current configuration. */ }
                }
                let current=self.state!.walletPrivateKey;self.state?.additionalReceivingKeys=keys.filter { $0 != current }.sorted()
                let advertised=discovery.filter { $0.kind == 10019 }.sorted { $0.created_at == $1.created_at ? $0.id < $1.id : $0.created_at > $1.created_at }.first
                if let info=advertised,let key=Keypair(hex:current),info.tag("pubkey") == key.publicKey.hex || info.tag("pubkey") == "02"+key.publicKey.hex { self.state?.receivingInfo=info }
            }
            if self.state == nil {
                self.canCreate = !all.contains { [17375,375,37375,7375,7376,37513,7374,10019].contains($0.kind) || $0.kind == 5 && $0.tags.contains(["k","7375"]) }
                self.status=self.canCreate ? "No wallet found. Create one to receive deposits and nutzaps." : "An existing wallet or deposit was found. Its records are preserved; restore its receiving key before creating another wallet."
                return
            }
            self.canCreate=false
            for event in all where event.kind == 7375 {
                let clear=try await identity.decryptWallet(event.content,expectedAuthor:self.owner);try self.check(identity,version);let decoded=try JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8)),payload=try WalletImport.token(decoded,mintTag:event.tag("mint"))
                if payload["unit"] != .null && payload["unit"].string != "sat" { continue }
                let token=try WalletTokenRecord(id:event.id,payload:payload);try self.state?.ledger.ingest(token)
            }
            for event in all where event.kind == 7374 && !(self.state?.importedQuotes?.contains(event.id) ?? false) {
                let clear=try await identity.decryptWallet(event.content,expectedAuthor:self.owner);try self.check(identity,version)
                let payload=try JSONDecoder().decode(JSONValue.self,from:Data(clear.utf8))
                if let quote=try? WalletImport.quote(payload,eventID:event.id),self.state!.mints.contains(quote["mint"].string) {
                    let prior=(self.state?.archivedInvoices ?? [])+[self.state?.invoice ?? .null]
                    if !prior.contains(where:{ $0["mint"] == quote["mint"] && $0["quote"]["quote"] == quote["quote"]["quote"] }) { if self.state?.archivedInvoices == nil { self.state?.archivedInvoices=[] };self.state?.archivedInvoices?.append(quote) }
                    if self.state?.importedQuotes == nil { self.state?.importedQuotes=[] };self.state?.importedQuotes?.insert(event.id)
                }
            }
            for event in all where event.kind == 7376 { self.state?.redeemed.formUnion(event.tags.filter { $0.count >= 4 && $0[0] == "e" && $0[3] == "redeemed" && WalletContract.key($0[1]) }.map { $0[1] }) }
            for event in all where event.kind == 5 && event.tags.contains(["k","7375"]) { self.state?.ledger.remove(event.tags.filter { $0.first == "e" && $0.count >= 2 }.map { $0[1] }) }
            try self.save();if self.state?.legacySource == nil || self.state?.configurationPublished == true { try await self.publishConfiguration(identity,version:version) };try await self.updateBalance(identity,version:version);self.status="Wallet synchronized."
        }
    }
    func create(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard self.state == nil,self.canCreate,let keys=Keypair() else { throw AppError.message("Refresh the wallet before creating one.") }
            let existing=try await self.bootstrap.querySnapshots(filter:["kinds":[17375,375,37375,37513,7375,7376,7374,10019],"authors":[self.owner]],authenticate:self.authenticate(identity));try self.check(identity,version)
            guard existing.isEmpty else { self.canCreate=false;throw AppError.message("A wallet was found. Refresh and restore it before creating another wallet.") }
            self.state=WalletPrivateState(owner:self.owner,walletPrivateKey:keys.privateKey.hex,mints:[WalletContract.defaultMint],relays:["wss://relay.ditto.pub","wss://relay.primal.net","wss://nos.lol"]);try self.save()
            let config:JSONValue = .array([.array([.string("privkey"),.string(keys.privateKey.hex)]),.array([.string("mint"),.string(WalletContract.defaultMint)])])
            let event=try await self.signed(kind:17375,payload:config,identity:identity,version:version)
            let tags=[["pubkey",keys.publicKey.hex],["mint",WalletContract.defaultMint,"sat"]]+self.state!.relays.map { ["relay",$0] }
            let info=try await identity.signEvent(kind:10019,tags:tags,content:"",expectedAuthor:self.owner);try self.check(identity,version)
            self.state?.configurationOutbox=[event,info];try self.save();try await self.publishConfiguration(identity,version:version);self.canCreate=false;self.status="Wallet created."
        }
    }
    private func publishConfiguration(_ identity:IdentityService,version:UUID) async throws {
        if let wallet=state,!wallet.configurationPublished,wallet.configurationOutbox.isEmpty {
            guard let keys=Keypair(hex:wallet.walletPrivateKey),keys.publicKey.hex != owner else { throw WalletContract.Failure.invalidToken }
            let keyTags=([wallet.walletPrivateKey]+(wallet.additionalReceivingKeys ?? [])).map { value -> [String] in [Keypair(hex:value)?.publicKey.hex == owner ? "legacy_privkey" : "privkey",value] }
            let tags=keyTags+wallet.mints.map { ["mint",$0] }
            let config:JSONValue = .array(tags.map { .array($0.map(JSONValue.string)) })
            let event=try await signed(kind:17375,payload:config,identity:identity,version:version)
            let info=try await identity.signEvent(kind:10019,tags:[["pubkey",keys.publicKey.hex]]+wallet.mints.map { ["mint",$0,"sat"] }+wallet.relays.map { ["relay",$0] },content:"",expectedAuthor:owner);try check(identity,version)
            state?.configurationOutbox=[event,info];try save()
        }
        while let event=state?.configurationOutbox.first {
            try await client.publish(event,authenticate:authenticate(identity));try check(identity,version);if event.kind == 10019 { state?.receivingInfo=event };state?.configurationOutbox.removeFirst();try save()
        }
        if state != nil { state?.configurationPublished=true;try save() }
    }
    func deposit(amount:Int,identity:IdentityService) async throws {
        try await run(identity) { version in
            guard let wallet=self.state,wallet.configurationPublished,wallet.pending == nil else { throw WalletContract.Failure.pending }
            if wallet.invoice != nil { self.status="The saved invoice is ready. Check its payment status to continue.";try self.save();return }
            guard (1...1_000_000).contains(amount),let mint=wallet.mints.first else { throw WalletContract.Failure.invalidMint }
            _=try await self.mintAPI.loadMint(mint);try self.check(identity,version)
            let raw=try await self.mintAPI.request(mint:mint,path:"v1/mint/quote/bolt11",body:.object(["amount":.number(Double(amount)),"unit":.string("sat")]))
            try self.check(identity,version);let quote=try CashuHTTPClient.validateQuote(raw,amount:amount,now:self.now())
            self.state?.invoice = .object(["mint":.string(mint),"amount":.number(Double(amount)),"quote":quote]);try self.save();self.status="Pay this Lightning invoice, then check payment status."
        }
    }
    func checkDeposit(identity:IdentityService) async throws {
        try await run(identity) { version in
            if self.state?.pending != nil { try await self.recover(identity,version:version);return }
            guard let invoice=self.state?.invoice else { return };let mint=invoice["mint"].string,quote=invoice["quote"],id=quote["quote"].string
            let latest=try await self.mintAPI.request(mint:mint,path:"v1/mint/quote/bolt11/"+id,body:nil);try self.check(identity,version)
            let status=try self.quoteState(latest)
            guard latest["quote"] == .null || latest["quote"].string == id else { throw WalletContract.Failure.invalidToken }
            if status == "UNPAID" {
                if quote["expiry"].number <= self.now().timeIntervalSince1970 { try self.save();self.status="The invoice expired. Its quote is retained in case a payment is still settling. Archive it to request another invoice." }
                else { self.status="Waiting for payment. The invoice is saved on this device." };return
            }
            guard status == "PAID" else { throw AppError.message("This invoice has already been issued by the mint. Keep the wallet recovery data and recover its saved operation before requesting another payment.") }
            let loaded=try await self.mintAPI.loadMint(mint);try self.check(identity,version)
            let batch=try CashuMintBatch.prepare(amount:Int(invoice["amount"].number),mint:loaded)
            self.state?.pending=WalletPendingOperation(purpose:.deposit,mint:mint,amount:Int(invoice["amount"].number),batch:batch,keepCount:batch.outputs.count,quote:quote)
            try self.save();try await self.submitDeposit(identity,mint:loaded,version:version)
        }
    }
    func archiveInvoice(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard let invoice=self.state?.invoice,self.state?.pending == nil,invoice["quote"]["expiry"].number <= self.now().timeIntervalSince1970 else { throw WalletContract.Failure.pending }
            let latest=try await self.mintAPI.request(mint:invoice["mint"].string,path:"v1/mint/quote/bolt11/"+invoice["quote"]["quote"].string,body:nil);try self.check(identity,version)
            guard try self.quoteState(latest) == "UNPAID" else { throw AppError.message("This invoice may have been paid. Check payment status before archiving it.") }
            var archived=self.state?.archivedInvoices ?? [];guard archived.count < 100 else { throw AppError.message("Check the archived invoices before adding more deposit requests.") }
            if !archived.contains(where:{ $0["mint"] == invoice["mint"] && $0["quote"]["quote"] == invoice["quote"]["quote"] }) { archived.append(invoice) }
            self.state?.archivedInvoices=archived;self.state?.invoice=nil;try self.save();self.status="Unpaid invoice archived. Its quote remains recoverable if a payment settles later."
        }
    }
    func checkArchived(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard self.state?.pending == nil else { throw WalletContract.Failure.pending }
            for invoice in self.state?.archivedInvoices ?? [] {
                let latest=try await self.mintAPI.request(mint:invoice["mint"].string,path:"v1/mint/quote/bolt11/"+invoice["quote"]["quote"].string,body:nil);try self.check(identity,version)
                if try self.quoteState(latest) == "PAID" {
                    var archived=(self.state?.archivedInvoices ?? []).filter { $0 != invoice }
                    if let current=self.state?.invoice { archived.append(current) }
                    self.state?.archivedInvoices=archived;self.state?.invoice=invoice;try self.save();self.status="An archived invoice was paid. Check payment status to receive its tokens.";return
                }
            }
            self.status="No archived invoice is paid yet. Their recovery data is retained."
        }
    }
    private func submitDeposit(_ identity:IdentityService,mint:CashuSwift.Mint,version:UUID) async throws {
        guard let operation=state?.pending,operation.purpose == .deposit else { throw WalletContract.Failure.pending }
        state?.pending?.phase = .submitted;try save()
        let outputs=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(operation.batch.outputs))
        let response=try await mintAPI.request(mint:operation.mint,path:"v1/mint/bolt11",body:.object(["quote":operation.quote?["quote"] ?? .null,"outputs":outputs]));try check(identity,version)
        let signatures=try JSONDecoder().decode([CashuSwift.Promise].self,from:JSONEncoder().encode(response["signatures"]))
        state?.pending?.signatures=signatures;state?.pending?.phase = .minted;try save();try await finishDeposit(identity,mint:mint,version:version)
    }
    private func recover(_ identity:IdentityService,version:UUID) async throws {
        guard let operation=state?.pending else { throw WalletContract.Failure.pending }
        if operation.purpose != .deposit { try await recoverSwap(identity,version:version);return }
        let mint=try await mintAPI.loadMint(operation.mint);try check(identity,version)
        if operation.signatures != nil || operation.received != nil { try await finishDeposit(identity,mint:mint,version:version);return }
        if operation.phase == .prepared { try await submitDeposit(identity,mint:mint,version:version);return }
        let outputs=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(operation.batch.outputs))
        let restored=try await mintAPI.request(mint:operation.mint,path:"v1/restore",body:.object(["outputs":outputs]));try check(identity,version)
        let known=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(restored["outputs"])),signatures=try JSONDecoder().decode([CashuSwift.Promise].self,from:JSONEncoder().encode(restored["signatures"]))
        if !known.isEmpty {
            let proofs=try operation.batch.recover(outputs:known,signatures:signatures,mint:mint);state?.pending?.received=try proofs.map { try WalletProof(JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0))) };state?.pending?.phase = .minted;try save();try await finishDeposit(identity,mint:mint,version:version);return
        }
        let quote=try await mintAPI.request(mint:operation.mint,path:"v1/mint/quote/bolt11/"+(operation.quote?["quote"].string ?? ""),body:nil);try check(identity,version)
        guard try quoteState(quote) == "PAID" else { throw AppError.message("The mint has not returned the complete saved deposit. Recovery data is retained; check again later.") }
        try await submitDeposit(identity,mint:mint,version:version)
    }
    private func finishDeposit(_ identity:IdentityService,mint:CashuSwift.Mint,version:UUID) async throws {
        guard var operation=state?.pending else { throw WalletContract.Failure.pending }
        if operation.received == nil {
            let proofs=try operation.batch.unblind(operation.signatures ?? [],mint:mint)
            operation.received=try proofs.map { try WalletProof(JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0))) };state?.pending=operation;try save()
        }
        if operation.outbox.isEmpty {
            let payload:JSONValue = .object(["mint":.string(operation.mint),"unit":.string("sat"),"proofs":.array(operation.received!.map(\.wire)),"del":.array([])])
            let token=try await signed(kind:7375,payload:payload,identity:identity,version:version)
            let history:JSONValue = .array([["direction","in"],["amount",String(operation.amount)],["unit","sat"],["e",token.id,"","created"]].map { .array($0.map(JSONValue.string)) })
            let record=try await signed(kind:7376,payload:history,identity:identity,version:version)
            state?.pending?.outbox=[token,record];state?.pending?.phase = .publishing;try save()
        }
        for event in state!.pending!.outbox where !(state?.pending?.acknowledged.contains(event.id) ?? true) {
            try await client.publish(event,authenticate:authenticate(identity));try check(identity,version);state?.pending?.acknowledged.insert(event.id);try save()
        }
        guard let token=state?.pending?.outbox.first(where:{ $0.kind == 7375 }) else { throw WalletContract.Failure.invalidToken }
        let payload:JSONValue = .object(["mint":.string(operation.mint),"unit":.string("sat"),"proofs":.array(operation.received!.map(\.wire)),"del":.array([])])
        try state?.ledger.ingest(WalletTokenRecord(id:token.id,payload:payload));state?.invoice=nil;state?.pending=nil;try save();try await updateBalance(identity,version:version);status="Deposit received and wallet records saved."
    }
    private func updateBalance(_ identity:IdentityService,version:UUID) async throws {
        guard let wallet=state else { balance=0;return };var total=0;var checked=Set<String>()
        for value in wallet.mints {
            guard checked.insert(try WalletContract.canonicalMint(value)).inserted else { continue }
            let proofs=try wallet.ledger.proofs(mint:value);if proofs.isEmpty { continue }
            let mint=try await mintAPI.loadMint(value);try check(identity,version)
            let typed=try proofs.map { try JSONDecoder().decode(CashuSwift.Proof.self,from:JSONEncoder().encode($0.wire)) }
            let states=try await mintAPI.states(typed,mint:mint);try check(identity,version);guard states.count == proofs.count else { throw WalletContract.Failure.invalidProof }
            for index in proofs.indices where states[index] == .unspent { total += proofs[index].amount }
        }
        balance=total
    }
}

struct WalletTipPreview:Equatable {
    let recipient:String
    let fee:Int
    var label:String { fee == 0 ? "Send 1 sat" : "Send 1 sat + \(fee) sat mint fee" }
}
private struct WalletTipPlan {
    let destination:NutzapDestination
    let mint:CashuSwift.Mint
    let selected:[WalletProof]
    let rollover:[WalletProof]
    let destroyed:[String]
    let fee:Int
}
extension WalletService {
    private func typed(_ values:[WalletProof]) throws -> [CashuSwift.Proof] { try values.map { try JSONDecoder().decode(CashuSwift.Proof.self,from:JSONEncoder().encode($0.wire)) } }
    private func wire(_ values:[CashuSwift.Proof]) throws -> [WalletProof] { try values.map { try WalletProof(JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode($0))) } }
    private func tipPlan(_ recipient:String,identity:IdentityService,version:UUID) async throws -> WalletTipPlan {
        guard let wallet=state,wallet.configurationPublished,wallet.pending == nil else { throw WalletContract.Failure.pending }
        let cleaned=recipient.trimmingCharacters(in:.whitespacesAndNewlines)
        guard let key=cleaned.hasPrefix("npub1") ? PublicKey(npub:cleaned) : PublicKey(hex:cleaned),key.hex != owner else { throw WalletContract.Failure.invalidRecipient }
        let records=try await bootstrap.querySnapshots(filter:["kinds":[10019,10002],"authors":[key.hex]],authenticate:authenticate(identity));try check(identity,version)
        guard let info=records.filter({ $0.kind == 10019 }).sorted(by:{ $0.created_at == $1.created_at ? $0.id < $1.id : $0.created_at > $1.created_at }).first else { throw WalletContract.Failure.invalidRecipient }
        let metadata=try NutzapRecipient(author:key.hex,tags:info.tags),value=try metadata.compatibleMint(holding:wallet.mints)
        let mint=try await mintAPI.loadMint(value);try check(identity,version)
        let capabilities=try await mintAPI.request(mint:value,path:"v1/info",body:nil);try check(identity,version)
        guard capabilities["nuts"]["11"]["supported"].boolean,capabilities["nuts"]["12"]["supported"].boolean else { throw WalletContract.Failure.invalidMint }
        let all=try wallet.ledger.proofs(mint:value),normalized=try typed(all).withFullKeysetID(of:mint),states=try await mintAPI.states(normalized,mint:mint);try check(identity,version)
        guard states.count == all.count else { throw WalletContract.Failure.invalidProof }
        var available:[WalletProof]=[],unspent:[WalletProof]=[]
        for index in all.indices where states[index] == .unspent {
            unspent.append(all[index])
            if let secret=try? JSONDecoder().decode(JSONValue.self,from:Data(all[index].secret.utf8)),["P2PK","HTLC"].contains(secret.array.first?.string ?? "") { continue }
            available.append(try wire([normalized[index]])[0])
        }
        available.sort { $0.amount == $1.amount ? $0.id < $1.id : $0.amount < $1.amount }
        var selected:[WalletProof]=[],total=0,fee=0
        for proof in available { selected.append(proof);total += proof.amount;fee=try CashuSwift.calculateFee(for:typed(selected),of:mint);if total >= 1+fee { break } }
        guard !selected.isEmpty,total >= 1+fee else { throw WalletContract.Failure.insufficientBalance }
        let ids=Set(selected.map(\.id)),canonical=try WalletContract.canonicalMint(value)
        let affected=wallet.ledger.records.values.filter { !wallet.ledger.deleted.contains($0.id) && (try? WalletContract.canonicalMint($0.mint)) == canonical && $0.proofs.contains(where:{ ids.contains($0.id) }) }
        let retained=Set(affected.flatMap(\.proofs).map(\.id)).subtracting(ids),rollover=unspent.filter { retained.contains($0.id) }
        let fallback=records.filter { $0.kind == 10002 }.max { $0.created_at < $1.created_at }?.tags.filter { $0.first == "r" && $0.count >= 2 && ($0.count == 2 || $0[2] == "read") }.compactMap { try? BunkerConnection.relay($0[1]) } ?? []
        let relays=Array(Set(metadata.relays.isEmpty ? fallback : metadata.relays).prefix(16))
        return WalletTipPlan(destination:NutzapDestination(author:key.hex,walletKey:metadata.walletKey,mint:value,relays:relays),mint:mint,selected:selected,rollover:rollover,destroyed:affected.map(\.id).sorted(),fee:fee)
    }
    func previewTip(to recipient:String,identity:IdentityService) async throws {
        tipPreview=nil
        try await run(identity) { version in let plan=try await self.tipPlan(recipient,identity:identity,version:version);self.tipPreview=WalletTipPreview(recipient:recipient,fee:plan.fee) }
    }
    func sendOneSat(to recipient:String,maximumFee:Int,identity:IdentityService) async throws {
        try await run(identity) { version in try await self.prepareTip(recipient,maximumFee:maximumFee,trigger:nil,identity:identity,version:version) }
    }
    private func prepareTip(_ recipient:String,maximumFee:Int,trigger:String?,identity:IdentityService,version:UUID) async throws {
            let plan=try await tipPlan(recipient,identity:identity,version:version)
            guard maximumFee >= 0,plan.fee <= maximumFee else { throw WalletContract.Failure.feeChanged }
            if let trigger {
                let current=try vault.automaticTips(owner:owner)
                guard current.enabled,current.queue.contains(where:{ $0.id == trigger }) else { throw CancellationError() }
            }
            let change=plan.selected.reduce(0) { $0+$1.amount }-1-plan.fee
            let keep=change > 0 ? try CashuMintBatch.prepare(amount:change,mint:plan.mint) : CashuMintBatch(outputs:[],secrets:[],blindingFactors:[])
            let send=try CashuMintBatch.prepare(amount:1,mint:plan.mint,lock:plan.destination.walletKey)
            let batch=CashuMintBatch(outputs:keep.outputs+send.outputs,secrets:keep.secrets+send.secrets,blindingFactors:keep.blindingFactors+send.blindingFactors)
            var operation=WalletPendingOperation(purpose:.tip,mint:plan.destination.mint,amount:1,batch:batch,inputs:plan.selected,destroyedTokenIDs:plan.destroyed,recipient:plan.destination,keepCount:keep.outputs.count)
            operation.automaticTrigger=trigger;operation.rollover=plan.rollover;operation.mintFee=plan.fee;state?.pending=operation;try save();tipPreview=nil
            try await submitSwap(identity,mint:plan.mint,version:version)
    }
    func receiveNutzaps(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard let wallet=self.state,wallet.configurationPublished,wallet.pending == nil,let walletKey=Keypair(hex:wallet.walletPrivateKey) else { throw WalletContract.Failure.pending }
            var receiving:[String:String]=[:]
            for key in [wallet.walletPrivateKey]+(wallet.additionalReceivingKeys ?? []) { if let pair=Keypair(hex:key) { receiving["02"+pair.publicKey.hex]=key } }
            _=walletKey
            let events=try await self.client.querySnapshots(filter:["kinds":[9321],"#p":[self.owner],"#u":wallet.mints],authenticate:self.authenticate(identity));try self.check(identity,version)
            var accepted:[String:[NostrEventPayload]]=[:]
            for event in Dictionary(events.map { ($0.id,$0) },uniquingKeysWith:{ first,_ in first }).values where !wallet.redeemed.contains(event.id) {
                guard event.tags.filter({ $0.first == "p" }).count == 1,event.tag("p") == self.owner,event.tags.filter({ $0.first == "u" }).count == 1,wallet.mints.contains(event.tag("u")),event.tags.filter({ $0.first == "unit" }).count <= 1,(event.tag("unit").isEmpty || event.tag("unit") == "sat") else { continue }
                let raw=event.tags.filter { $0.first == "proof" && $0.count == 2 };guard !raw.isEmpty,raw.count <= 128 else { continue }
                guard let proofs=try? raw.map({ try WalletProof(JSONDecoder().decode(JSONValue.self,from:Data($0[1].utf8))) }),proofs.allSatisfy({ proof in receiving.keys.contains { proof.locked(to:$0) } }),Set(proofs.map(\.id)).count == proofs.count else { continue }
                accepted[event.tag("u"),default:[]].append(event)
            }
            for (value,group) in accepted.sorted(by:{ $0.key < $1.key }) {
                let mint=try await self.mintAPI.loadMint(value);try self.check(identity,version)
                let info=try await self.mintAPI.request(mint:value,path:"v1/info",body:nil);try self.check(identity,version);guard info["nuts"]["11"]["supported"].boolean,info["nuts"]["12"]["supported"].boolean else { throw WalletContract.Failure.invalidMint }
                var unique:[String:WalletProof]=[:],verifiedEvents:[(event:NostrEventPayload,ids:Set<String>)]=[]
                for event in group {
                    guard let decoded=try? event.tags.filter({ $0.first == "proof" && $0.count == 2 }).map({ try JSONDecoder().decode(CashuSwift.Proof.self,from:Data($0[1].utf8)) }).withFullKeysetID(of:mint),case .valid? = try? CashuSwift.Crypto.checkDLEQ(for:decoded,with:mint) else { continue }
                    let canonical=try self.wire(decoded)
                    guard Set(canonical.map(\.secret)).count == canonical.count else { continue }
                    var conflict=false
                    for proof in canonical { if let previous=unique[proof.id],previous.amount != proof.amount || previous.secret != proof.secret || previous.wire["id"] != proof.wire["id"] { conflict=true } }
                    let ids=Set(canonical.map(\.id));guard !conflict,unique.count+ids.subtracting(Set(unique.keys)).count <= 512 else { continue };for proof in canonical where unique[proof.id] == nil { unique[proof.id]=proof };verifiedEvents.append((event,ids))
                }
                guard !unique.isEmpty else { continue }
                let proofs=unique.values.sorted { $0.id < $1.id },normalized=try self.typed(proofs)
                let states=try await self.mintAPI.states(normalized,mint:mint);try self.check(identity,version);guard states.count == proofs.count else { throw WalletContract.Failure.invalidProof }
                let spent=Set(proofs.indices.filter { states[$0] == .spent }.map { proofs[$0].id })
                for record in verifiedEvents where record.ids.isSubset(of:spent) { self.state?.redeemed.insert(record.event.id) }
                try self.save()
                let spendable=Set(proofs.indices.filter { states[$0] == .unspent }.map { proofs[$0].id }),settled=spent.union(spendable)
                let rows=Array(verifiedEvents.filter { $0.ids.isSubset(of:settled) && !$0.ids.isDisjoint(with:spendable) }.prefix(128))
                let incoming=rows.map(\.event);guard !incoming.isEmpty else { continue }
                let wanted=Set(rows.flatMap { Array($0.ids) }).intersection(spendable)
                let inputs=try normalized.filter { wanted.contains($0.C) }.map { proof -> WalletProof in
                    let secret=try JSONDecoder().decode(JSONValue.self,from:Data(proof.secret.utf8));guard let privateKey=receiving[secret.array[1]["data"].string] else { throw WalletContract.Failure.invalidProof }
                    let signature=try secp256k1.Schnorr.PrivateKey(dataRepresentation:CashuMintBatch.bytes(privateKey)).signature(for:Data(proof.secret.utf8))
                    let witness=JSONValue.object(["signatures":.array([.string(CashuMintBatch.hex(signature.dataRepresentation))])]).json
                    return try self.wire([proof])[0].replacingWitness(witness)
                }
                let fee=try CashuSwift.calculateFee(for:self.typed(inputs),of:mint),amount=inputs.reduce(0) { $0+$1.amount }-fee
                guard amount > 0 else { continue }
                let batch=try CashuMintBatch.prepare(amount:amount,mint:mint)
                var operation=WalletPendingOperation(purpose:.receive,mint:value,amount:amount,batch:batch,inputs:inputs,keepCount:batch.outputs.count);operation.incoming=incoming;operation.mintFee=fee
                self.state?.pending=operation;try self.save();try await self.submitSwap(identity,mint:mint,version:version);return
            }
            self.status="No new redeemable nutzaps found. Tiny payments may need to accumulate to cover the mint fee."
        }
    }
    private func submitSwap(_ identity:IdentityService,mint:CashuSwift.Mint,version:UUID) async throws {
        guard let operation=state?.pending,operation.purpose != .deposit else { throw WalletContract.Failure.pending }
        state?.pending?.phase = .submitted;try save()
        let outputs=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(operation.batch.outputs))
        let response=try await mintAPI.request(mint:operation.mint,path:"v1/swap",body:.object(["inputs":.array(operation.inputs.map(\.wire)),"outputs":outputs]));try check(identity,version)
        state?.pending?.signatures=try JSONDecoder().decode([CashuSwift.Promise].self,from:JSONEncoder().encode(response["signatures"]));state?.pending?.phase = .minted;try save();try await finishSwap(identity,mint:mint,version:version)
    }
    private func recoverSwap(_ identity:IdentityService,version:UUID) async throws {
        guard let operation=state?.pending,operation.purpose != .deposit else { throw WalletContract.Failure.pending }
        let mint=try await mintAPI.loadMint(operation.mint);try check(identity,version)
        if operation.received != nil || operation.signatures != nil { try await finishSwap(identity,mint:mint,version:version);return }
        if operation.phase == .prepared { try await submitSwap(identity,mint:mint,version:version);return }
        let outputs=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(operation.batch.outputs))
        let response=try await mintAPI.request(mint:operation.mint,path:"v1/restore",body:.object(["outputs":outputs]));try check(identity,version)
        let restored=try JSONDecoder().decode([CashuSwift.Output].self,from:JSONEncoder().encode(response["outputs"])),signatures=try JSONDecoder().decode([CashuSwift.Promise].self,from:JSONEncoder().encode(response["signatures"]))
        if !restored.isEmpty { state?.pending?.received=try wire(operation.batch.recover(outputs:restored,signatures:signatures,mint:mint));state?.pending?.phase = .minted;try save();try await finishSwap(identity,mint:mint,version:version);return }
        let states=try await mintAPI.states(typed(operation.inputs),mint:mint);try check(identity,version)
        guard states.count == operation.inputs.count,states.allSatisfy({ $0 == .unspent }) else { throw AppError.message("The mint has not returned this saved transfer. Its recovery data is retained; try again when the mint has reconciled the spent or pending inputs.") }
        try await submitSwap(identity,mint:mint,version:version)
    }
    private func finishSwap(_ identity:IdentityService,mint:CashuSwift.Mint,version:UUID) async throws {
        guard var operation=state?.pending,operation.purpose != .deposit else { throw WalletContract.Failure.pending }
        if operation.received == nil { operation.received=try wire(operation.batch.unblind(operation.signatures ?? [],mint:mint));state?.pending=operation;try save() }
        let proofs=operation.received!;guard operation.keepCount <= proofs.count,operation.keepCount >= 0 else { throw WalletContract.Failure.invalidProof }
        let keep=Array(proofs.prefix(operation.keepCount))+(operation.rollover ?? [])
        if operation.outbox.isEmpty {
            let payload:JSONValue = .object(["mint":.string(operation.mint),"unit":.string("sat"),"proofs":.array(keep.map(\.wire)),"del":.array(operation.destroyedTokenIDs.map(JSONValue.string))])
            let token=try await signed(kind:7375,payload:payload,identity:identity,version:version);var outbox=[token]
            if !operation.destroyedTokenIDs.isEmpty { outbox.append(try await identity.signEvent(kind:5,tags:[["k","7375"]]+operation.destroyedTokenIDs.map { ["e",$0] },content:"",expectedAuthor:owner));try check(identity,version) }
            let history=[["direction",operation.purpose == .tip ? "out" : "in"],["amount",String(operation.amount)],["unit","sat"],["e",token.id,"","created"]]+operation.destroyedTokenIDs.map { ["e",$0,"","destroyed"] }
            let receiptTags=(operation.incoming ?? []).flatMap { [["e",$0.id,"","redeemed"],["p",$0.pubkey]] }
            outbox.append(try await signed(kind:7376,payload:.array(history.map { .array($0.map(JSONValue.string)) }),tags:receiptTags,identity:identity,version:version))
            if operation.purpose == .tip {
                guard let destination=operation.recipient else { throw WalletContract.Failure.invalidRecipient }
                let send=Array(proofs.dropFirst(operation.keepCount));guard send.reduce(0,{ $0+$1.amount }) == 1,send.allSatisfy({ $0.locked(to:destination.walletKey) }) else { throw WalletContract.Failure.invalidProof }
                outbox.append(try await identity.signEvent(kind:9321,tags:send.map { ["proof",$0.wire.json] }+[["alt","This is a nutzap"],["amount","1"],["unit","sat"],["u",destination.mint],["p",destination.author]],content:WalletCopy.publicNote,expectedAuthor:owner));try check(identity,version)
            }
            state?.pending?.outbox=outbox;state?.pending?.phase = .publishing;try save()
        }
        for event in state!.pending!.outbox where !(state?.pending?.acknowledged.contains(event.id) ?? true) {
            let destination=operation.recipient?.relays ?? [],target=event.kind == 9321 && !fixedRelays && !destination.isEmpty ? NostrRelayClient(relays:destination) : client
            try await target.publish(event,authenticate:authenticate(identity));try check(identity,version);state?.pending?.acknowledged.insert(event.id);try save()
        }
        guard let token=state?.pending?.outbox.first(where:{ $0.kind == 7375 }) else { throw WalletContract.Failure.invalidToken }
        try state?.ledger.ingest(WalletTokenRecord(id:token.id,payload:.object(["mint":.string(operation.mint),"unit":.string("sat"),"proofs":.array(keep.map(\.wire)),"del":.array(operation.destroyedTokenIDs.map(JSONValue.string))])))
        if let receipt=state?.pending?.outbox.first(where:{ $0.kind == 9321 }) {
            let receipts=Array(((state?.sentReceipts ?? [])+[receipt]).suffix(128));state?.sentReceipts=receipts
            if let trigger=operation.automaticTrigger { if state?.automaticReceipts == nil { state?.automaticReceipts=[:] };state?.automaticReceipts?[trigger]=receipt.id }
        }
        state?.redeemed.formUnion((operation.incoming ?? []).map(\.id));state?.pending=nil;try save();try await updateBalance(identity,version:version)
        status=operation.purpose == .tip ? "Sent 1 sat. Mint fee: \(operation.mintFee ?? 0) sat." : "Received \(operation.amount) sat. Mint fee: \(operation.mintFee ?? 0) sat."
    }
}
private extension WalletProof {
    func replacingWitness(_ witness:String) throws -> WalletProof { try WalletProof(wire.setting("witness",.string(witness))) }
}

extension WalletService {
    func configureAutomaticTips(enabled:Bool,recipient:String,maximumFee:Int,identity:IdentityService) throws {
        let account=identity.hex
        guard !account.isEmpty,(0...1_000_000).contains(maximumFee),!enabled || (recipient.hasPrefix("npub1") ? PublicKey(npub:recipient) : PublicKey(hex:recipient)) != nil else { throw WalletContract.Failure.invalidRecipient }
        var journal=try vault.automaticTips(owner:account);journal.configure(enabled:enabled,recipient:recipient,maximumFee:maximumFee);try vault.saveAutomaticTips(journal,owner:account);automatic=journal
    }
    func enqueueAutomaticTips(_ changes:[PracticeChange],identity:IdentityService,resuming:Bool = false) throws {
        guard !changes.isEmpty,!identity.hex.isEmpty,let wallet=try vault.load(owner:identity.hex) else { return }
        var journal=try vault.automaticTips(owner:identity.hex);guard journal.enabled else { automatic=journal;return }
        var available=0,seen=Set<String>()
        for mint in wallet.mints where seen.insert(try WalletContract.canonicalMint(mint)).inserted { available += try wallet.ledger.balance(mint:mint) }
        let eligible=resuming ? changes.filter { change in journal.enabledAt.map { change.date >= $0 } ?? false } : changes
        journal.enqueue(eligible,available:available);try vault.saveAutomaticTips(journal,owner:identity.hex);automatic=journal
    }
    @discardableResult func processAutomaticTip(identity:IdentityService) async throws -> Bool {
        var progressed=false
        try await run(identity) { version in
            var journal=try self.vault.automaticTips(owner:self.owner);self.automatic=journal
            guard journal.enabled,let intent=journal.queue.first else { return }
            if self.state?.automaticReceipts?[intent.id] != nil { journal.complete(intent.id);try self.vault.saveAutomaticTips(journal,owner:self.owner);self.automatic=journal;progressed=true;return }
            if let pending=self.state?.pending {
                guard pending.automaticTrigger == intent.id else { return }
                try await self.recoverSwap(identity,version:version)
            } else {
                do { try await self.prepareTip(intent.recipient,maximumFee:intent.maximumFee,trigger:intent.id,identity:identity,version:version) }
                catch WalletContract.Failure.insufficientBalance {
                    journal=try self.vault.automaticTips(owner:self.owner);journal.clearQueue();try self.vault.saveAutomaticTips(journal,owner:self.owner);self.automatic=journal;progressed=true;return
                }
                catch WalletContract.Failure.feeChanged {
                    journal=try self.vault.automaticTips(owner:self.owner);journal.pause("Automatic tips paused: the mint fee exceeds your approved limit.");try self.vault.saveAutomaticTips(journal,owner:self.owner);self.automatic=journal;return
                }
                catch WalletContract.Failure.invalidRecipient {
                    journal=try self.vault.automaticTips(owner:self.owner);journal.pause("Automatic tips paused: the recipient's receiving setup could not be verified.");try self.vault.saveAutomaticTips(journal,owner:self.owner);self.automatic=journal;return
                }
            }
            try self.check(identity,version)
            guard self.state?.automaticReceipts?[intent.id] != nil else { return }
            journal=try self.vault.automaticTips(owner:self.owner);journal.complete(intent.id);try self.vault.saveAutomaticTips(journal,owner:self.owner);self.automatic=journal;progressed=true
        }
        return progressed
    }
}

extension WalletService {
    func refreshAutomaticPreferences(identity:IdentityService) throws { guard !identity.hex.isEmpty else { return };automatic=try vault.automaticTips(owner:identity.hex) }
    func hasAutomaticWork(identity:IdentityService) -> Bool {
        guard !identity.hex.isEmpty,let journal=try? vault.automaticTips(owner:identity.hex),journal.enabled,let first=journal.queue.first,let wallet=try? vault.load(owner:identity.hex) else { return false }
        return wallet.pending == nil || wallet.pending?.automaticTrigger == first.id
    }
}

extension WalletService {
    func restoreBrowserWallet(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard var wallet=self.state,wallet.legacySource != nil,!wallet.configurationPublished,wallet.pending == nil,let current=Keypair(hex:wallet.walletPrivateKey) else { throw WalletContract.Failure.pending }
            if current.publicKey.hex == self.owner {
                guard let fresh=Keypair() else { throw WalletContract.Failure.invalidProof }
                wallet.additionalReceivingKeys=Array(Set((wallet.additionalReceivingKeys ?? [])+[wallet.walletPrivateKey]));wallet.walletPrivateKey=fresh.privateKey.hex
            }
            self.state=wallet;try self.save();try await self.publishConfiguration(identity,version:version);self.status="Browser wallet restored. Existing keys and proofs were preserved."
        }
    }
}

extension WalletService {
    func publishReceivingInformation(identity:IdentityService) async throws {
        try await run(identity) { version in
            guard let wallet=self.state,wallet.configurationPublished,let key=Keypair(hex:wallet.walletPrivateKey),key.publicKey.hex != self.owner else { throw AppError.message("Restore a separate wallet receiving key before publishing payment information.") }
            let tags=[["pubkey",key.publicKey.hex]]+wallet.mints.map { ["mint",$0,"sat"] }+wallet.relays.map { ["relay",$0] }
            let event=try await identity.signEvent(kind:10019,tags:tags,content:"",expectedAuthor:self.owner);try self.check(identity,version)
            self.state?.configurationOutbox.append(event);try self.save();try await self.publishConfiguration(identity,version:version);self.status="Receiving information published. Existing wallet keys and proofs were preserved."
        }
    }
}

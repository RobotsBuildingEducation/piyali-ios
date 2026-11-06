import Foundation
import Combine
import CryptoKit

struct JourneyRecordingPresentation:Identifiable {let id=UUID();let controller:VoiceJourneyController;let milestone:Int;let account:String;let target:String}

@MainActor final class VoiceJourneyController:ObservableObject {
    @Published private(set) var data:JSONValue = .object([:])
    @Published private(set) var loading=true
    @Published private(set) var failed=false
    @Published private(set) var busy=false
    @Published private(set) var selected:Int?
    @Published private(set) var current:JSONValue?
    @Published private(set) var first:JSONValue?
    @Published private(set) var errorKey:String?
    private let injected:(any VoiceJourneyStoring)?
    private var store:(any VoiceJourneyStoring)?,updates:AnyCancellable?,epoch=UUID(),scope=""
    init(store:(any VoiceJourneyStoring)?=nil){injected=store}
    func bind(_ app:AppModel)async {
        close();scope=app.identity.npub+":"+app.learner.target;let token=epoch,account=app.identity.npub,target=app.learner.target
        store=injected ?? MemoryDrawerFixture.journeyStore() ?? VoiceJourneyStore()
        loading=true;failed=false;data = .object([:])
        do {
            if injected == nil && !MemoryDrawerFixture.enabled{try await FirebaseIdentityService.shared.ensure(app.identity)}
            guard !Task.isCancelled,epoch == token else{return}
            updates=try store?.watch(account:account,target:target,onData:{[weak self] value in guard let self,self.epoch == token else{return};self.data=value;self.loading=false;self.failed=false},onError:{[weak self] in guard let self,self.epoch == token else{return};self.failed=true;self.loading=false})
        }catch{if epoch == token{loading=false;failed=true}}
    }
    private func valid(_ app:AppModel,_ token:UUID)->Bool {epoch == token && scope == app.identity.npub+":"+app.learner.target && !Task.isCancelled}
    private func payload(_ envelope:JourneyEnvelope,_ app:AppModel,_ milestone:Int)async throws->JSONValue {
        let account=app.identity.npub,target=app.learner.target,author=app.identity.hex,key=try JourneyCryptography.key(await app.identity.decryptWallet(envelope.wrappedKey,expectedAuthor:author))
        let result=try JourneyCryptography.open(envelope,key:key,account:account,target:target,milestone:milestone);_ = try JourneyCryptography.validate(result);return result
    }
    func listen(_ milestone:Int,_ app:AppModel)async {
        if selected == milestone,current != nil {selected=nil;current=nil;first=nil;return}
        let token=epoch;selected=milestone;current=nil;first=nil;errorKey=nil;busy=true;defer{if epoch == token{busy=false}}
        do {
            guard let store else{throw CancellationError()};let envelope=try await store.load(account:app.identity.npub,target:app.learner.target,milestone:milestone),clip=try await payload(envelope,app,milestone)
            let baseline=VoiceJourneyModel.baseline(data);var original:JSONValue?
            if let baseline,baseline != milestone {original=try await payload(store.load(account:app.identity.npub,target:app.learner.target,milestone:baseline),app,baseline)}
            guard valid(app,token),selected == milestone else{return};current=clip;first=original
        }catch{if valid(app,token){errorKey="error"}}
    }
    func save(audio:Data,mime:String,duration:Double,prompt:String,support:String,milestone:Int,app:AppModel)async->Bool {
        guard !busy else{return false};guard VoiceJourneyModel.canRecord(data,milestone) else{errorKey="error";return false};let token=epoch,account=app.identity.npub,target=app.learner.target,author=app.identity.hex;busy=true;errorKey=nil;defer{if epoch == token{busy=false}}
        do {
            let clean=prompt.trimmingCharacters(in:.whitespacesAndNewlines),payload:JSONValue = .object(["audio":.string(audio.base64EncodedString()),"mimeType":.string(mime),"duration":.number(duration),"prompt":.string(clean.isEmpty ? "Voice Journey":clean),"support":.string(support == "hints" ? "hints":"independent")]);_=try JourneyCryptography.validate(payload)
            let key=SymmetricKey(size:.bits256).withUnsafeBytes{Data($0)},nonce=AES.GCM.Nonce().withUnsafeBytes{Data($0)},cipher=try JourneyCryptography.seal(payload,key:key,nonce:nonce,account:account,target:target,milestone:milestone),wrapped=try await app.identity.encryptWallet(JourneyCryptography.hex(key),expectedAuthor:author)
            guard valid(app,token),let store else{throw CancellationError()};try await store.save(.init(wrappedKey:wrapped,iv:nonce,ciphertext:cipher),account:account,target:target,milestone:milestone)
            return valid(app,token)
        }catch{if valid(app,token){errorKey="error"};return false}
    }
    func remove(_ milestone:Int,_ app:AppModel)async {
        guard !busy,let store else{return};let token=epoch;busy=true;errorKey=nil;defer{if epoch == token{busy=false}}
        do {try await store.delete(account:app.identity.npub,target:app.learner.target,milestone:milestone);guard valid(app,token) else{return};selected=nil;current=nil;first=nil}catch{if valid(app,token){errorKey="error"}}
    }
    func acknowledge(_ milestone:Int,_ app:AppModel)async {
        guard valid(app,epoch),let store else{return};try? await store.acknowledge(account:app.identity.npub,target:app.learner.target,milestone:milestone)
    }
    func clearSelection(){selected=nil;current=nil;first=nil;errorKey=nil}
    func close(){updates?.cancel();updates=nil;epoch=UUID();selected=nil;current=nil;first=nil;busy=false;errorKey=nil}
}

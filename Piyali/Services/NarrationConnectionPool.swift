import Foundation
import FirebaseAuth

struct NarrationWarmRules:Decodable {
    let idleMilliseconds:Int,connectTimeoutMilliseconds:Int,retryMilliseconds:Int,defaultVoice:String
    static func load()throws->Self{guard let url=Bundle.main.url(forResource:"narration-warm-rules",withExtension:"json")else{throw PracticeRecipeFailure.unavailable};return try JSONDecoder().decode(Self.self,from:Data(contentsOf:url))}
}
@MainActor final class NarrationWarmPolicy {
    private let engine:PracticeAssistancePolicy
    init()throws{guard let url=Bundle.main.url(forResource:"narration-warm-policy",withExtension:"js")else{throw PracticeRecipeFailure.unavailable};engine=try PracticeAssistancePolicy(source:String(contentsOf:url,encoding:.utf8))}
    func voice(_ value:String)throws->JSONValue{try engine.runPolicy("voice",.object(["voice":.string(value)]))}
}

/// One unused, silent receive-only connection. Claims are exclusive and never returned after speech.
@MainActor final class NarrationConnectionPool {
    struct Lease{let client:RealtimeVoiceTransport,voice:String}
    @MainActor private final class Entry{
        let id=UUID(),account:String,client:RealtimeVoiceTransport,voice:String,expires:Date
        var open=false,ready=false,closed=false,claimed=false
        var task:Task<Void,Never>?,expiry:Task<Void,Never>?
        private var result:Bool?,waiters:[CheckedContinuation<Bool,Never>]=[]
        func resolve(_ value:Bool){guard result == nil else{return};result=value;let pending=waiters;waiters=[];pending.forEach{$0.resume(returning:value)}}
        func wait()async->Bool{if let result{return result};return await withCheckedContinuation{waiters.append($0)}}
        init(account:String,client:RealtimeVoiceTransport,voice:String,expires:Date){self.account=account;self.client=client;self.voice=voice;self.expires=expires}
        func close(){guard !closed else{return};closed=true;resolve(false);task?.cancel();expiry?.cancel();client.onOpen=nil;client.onEvent=nil;client.onFailure=nil;client.close()}
    }
    static let shared=NarrationConnectionPool()
    private let factory:()->RealtimeVoiceTransport,authorized:(String)->Bool,now:()->Date
    private let rules:NarrationWarmRules?
    private var idle:Entry?,account="",active=false,retryAt=Date.distantPast
    init(factory:(()->RealtimeVoiceTransport)?=nil,rules:NarrationWarmRules?=nil,now:@escaping()->Date={Date()},authorized:((String)->Bool)?=nil){
        self.factory=factory ?? {RealtimeRTCTransport(capturesMicrophone:false,activatesPlayback:false,purpose:.narration,recordsNarration:true)};self.rules=rules ?? (try? NarrationWarmRules.load());self.now=now;self.authorized=authorized ?? {account in FirebaseService.shared.configured && Auth.auth().currentUser?.uid == account}
    }
    var automaticRefill=false
    var usable:Bool{active && !account.isEmpty && authorized(account)}
    var idleCount:Int{idle == nil ? 0:1}
    var prepared:Bool{idle?.ready == true && idle?.closed == false}
    func configure(account:String,active:Bool){let changed=self.account != account;self.account=account;self.active=active;if changed || !active{clear(resetBackoff:changed)}}
    func clear(resetBackoff:Bool=false){let entry=idle;idle=nil;if let entry,!entry.ready,!entry.claimed,let rules{retryAt=now().addingTimeInterval(Double(rules.retryMilliseconds)/1000)};entry?.close();if resetBackoff{retryAt = .distantPast}}
    func warm(session:JSONValue,force:Bool=false)async->Bool{
        guard usable,let rules,session["provider"].string != "gemini" else{return false}
        if let entry=idle,entry.expires<=now() || entry.closed{idle=nil;entry.close()}
        if idle == nil{
            guard force || now()>=retryAt else{return false}
            let entry=Entry(account:account,client:factory(),voice:rules.defaultVoice,expires:now().addingTimeInterval(Double(rules.idleMilliseconds)/1000));idle=entry;entry.client.setMicrophoneEnabled(false)
            let output=session["audio"]["output"].setting("voice",.string(rules.defaultVoice)),warmSession=session.setting("audio",session["audio"].setting("output",output))
            entry.client.onOpen={[weak entry] in entry?.open=true}
            entry.client.onFailure={[weak self,weak entry] _ in guard let self,let entry else{return};self.failed(entry)}
            entry.client.onEvent={[weak self,weak entry] event in if ["response.created","output_audio_buffer.started","response.done","error"].contains(event["type"].string),let self,let entry{self.failed(entry)}}
            entry.expiry=Task{[weak self,weak entry] in try? await Task.sleep(for:.milliseconds(rules.idleMilliseconds));guard !Task.isCancelled,let self,let entry else{return};if self.idle?.id == entry.id{self.idle=nil};entry.close()}
            entry.task=Task{[weak self] in
                let deadline=Task{[weak self,weak entry] in try? await Task.sleep(for:.milliseconds(rules.connectTimeoutMilliseconds));guard !Task.isCancelled,let self,let entry,!entry.ready else{return};self.failed(entry)};defer{deadline.cancel()}
                do{try await entry.client.connect(session:warmSession);while !entry.closed && !(entry.open && entry.client.narrationReceiverReady){try Task.checkCancellation();try await Task.sleep(for:.milliseconds(10))};guard !entry.closed,!Task.isCancelled else{entry.resolve(false);return};entry.ready=true;entry.resolve(true)}catch{self?.failed(entry);entry.resolve(false)}
            }
        }
        guard let entry=idle else{return false};let ready=await entry.wait();return ready && !entry.closed && usable && entry.account == account
    }
    func take()async->Lease?{
        guard usable,let entry=idle else{return nil};idle=nil;entry.claimed=true;entry.expiry?.cancel()
        return await withTaskCancellationHandler{
            let ready=await entry.wait()
            guard ready,!entry.closed,!Task.isCancelled,entry.expires>now(),usable,entry.account == account else{entry.close();return nil}
            entry.client.onOpen=nil;entry.client.onEvent=nil;entry.client.onFailure=nil
            return Lease(client:entry.client,voice:entry.voice)
        }onCancel:{Task{@MainActor in entry.close()}}
    }
    private func failed(_ entry:Entry){if !entry.claimed,let rules{retryAt=now().addingTimeInterval(Double(rules.retryMilliseconds)/1000)};if idle?.id == entry.id{idle=nil};entry.close()}
}

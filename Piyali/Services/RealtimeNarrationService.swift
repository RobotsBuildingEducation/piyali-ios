import Foundation

/// Source narration instructions and output-buffer completion, on receive-only native WebRTC.
@MainActor final class RealtimeNarrationService:ObservableObject {
    @Published private(set) var loading=false
    @Published private(set) var playing=false
    @Published private(set) var error:String?
    private(set) var failureDetail:String?
    private static weak var owner:RealtimeNarrationService?
    private let factory:()->RealtimeVoiceTransport
    private var client:RealtimeVoiceTransport?,epoch=UUID(),work:Task<Void,Never>?,startup:Task<Void,Never>?,hardDeadline:Task<Void,Never>?,drain:Task<Void,Never>?
    private var responseSucceeded=false,bufferStopped=false
    private var started:(()->Void)?,failed:(()->Void)?,finished:(()->Void)?
    private let cache:NarrationAudioCache?,makeReplay:()->NarrationReplay
    private let pool:NarrationConnectionPool?
    private var warmPolicy:NarrationWarmPolicy?
    private(set) var usedPreparedConnection=false
    private var cachePolicy:NarrationCachePolicy?,cacheKey:String?,replay:NarrationReplay?
    private(set) var playbackSource:String?,lastCapturedBytes=0
    init(factory:(()->RealtimeVoiceTransport)?=nil,cache:NarrationAudioCache?=nil,cacheEnabled:Bool=true,replayFactory:(()->NarrationReplay)?=nil,pool:NarrationConnectionPool?=nil){self.pool=pool ?? (factory == nil ? .shared:nil);self.factory=factory ?? {RealtimeRTCTransport(capturesMicrophone:false,purpose:.narration,recordsNarration:true)};self.cache=cacheEnabled ? (cache ?? (factory == nil ? .shared:nil)):nil;makeReplay=replayFactory ?? {NarrationReplayPlayer()}}
    func play(_ text:String,language:String,engine:CompanionQuestPolicy?,voice:String="ash",sessionOverride:JSONValue?=nil,cacheRequest:JSONValue?=nil,startupMilliseconds:Int=20000,onStarted:(()->Void)?=nil,onFailed:(()->Void)?=nil,onFinished:(()->Void)?=nil){
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return}
        Self.owner?.stopAll();stopAll();Self.owner=self;loading=true;error=nil;failureDetail=nil;playbackSource=nil;usedPreparedConnection=false;lastCapturedBytes=0;started=onStarted;failed=onFailed;finished=onFinished;let token=epoch
        work=Task{do {
            let session:JSONValue
            if let sessionOverride{session=sessionOverride}else{guard let engine else{throw PracticeRecipeFailure.unavailable};session=try engine.run("ph_tts",.object(["language":.string(language),"voice":.string(voice)]))}
            if let cache{
                if cachePolicy == nil{cachePolicy=try? NarrationCachePolicy()}
                cacheKey=try? cachePolicy?.key(text:text,language:language,voice:voice,session:session,request:cacheRequest)
                if let key=cacheKey,let hit=await cached(cache,key:key){
                    guard epoch == token,!Task.isCancelled else{return}
                    do{let player=makeReplay();replay=player
                        player.onFinished={[weak self] in guard let self,self.epoch == token else{return};let callback=self.finished;self.stopAll();callback?()}
                        player.onFailed={[weak self] in guard let self,self.epoch == token else{return};Task{await cache.remove(key)};self.fail("cached-playback")}
                        try player.play(hit.wav);loading=false;playing=true;playbackSource=hit.source;let callback=started;started=nil;callback?();return
                    }catch{replay?.stop();replay=nil;await cache.remove(key)}
                }
                guard epoch == token,!Task.isCancelled else{return}
            }
            let lease=await pool?.take();guard epoch == token,!Task.isCancelled else{lease?.client.close();return};usedPreparedConnection=lease != nil;playbackSource=lease == nil ? "network":"prepared"
            let client=lease?.client ?? factory(),preparedVoice=lease?.voice;self.client=client
            client.onOpen={ [weak self,weak client] in guard let self,self.epoch == token else{return};client?.setMicrophoneEnabled(false);client?.setRemoteAudioEnabled(true)
                if let preparedVoice,preparedVoice != session["audio"]["output"]["voice"].string {do{if self.warmPolicy == nil{self.warmPolicy=try NarrationWarmPolicy()};guard let event=try self.warmPolicy?.voice(session["audio"]["output"]["voice"].string),client?.send(event) == true else{self.fail("prepared-voice");return}}catch{self.fail("prepared-voice");return}}
                let item:JSONValue = .object(["type":.string("conversation.item.create"),"item":.object(["type":.string("message"),"role":.string("user"),"content":.array([.object(["type":.string("input_text"),"text":.string("[NARRATE THIS TEXT EXACTLY]: "+text)])])])])
                guard (session["provider"].string == "gemini" || client?.send(item) == true),client?.send(.object(["type":.string("response.create"),"response":.object(["output_modalities":.array([.string("audio")]),"instructions":session["provider"].string == "gemini" ? session["previewPrompt"]:session["instructions"]])])) == true else{self.fail("send");return}
            }
            client.onEvent={ [weak self] event in guard let self,self.epoch == token else{return};self.receive(event)}
            client.onFailure={ [weak self] detail in guard let self,self.epoch == token else{return};self.fail("transport: "+detail)}
            startup=Task{try? await Task.sleep(for:.milliseconds(startupMilliseconds));if !Task.isCancelled,self.epoch == token,self.loading{self.fail("startup")}}
            hardDeadline=Task{try? await Task.sleep(for:.milliseconds(max(45000,text.count*180+10000)));if !Task.isCancelled,self.epoch == token{self.fail("deadline")}}
            if lease != nil{try client.activateNarrationOutput();client.onOpen?()}else{try await client.connect(session:session)};try Task.checkCancellation()
            if let pool,pool.automaticRefill{Task{_=await pool.warm(session:session)}}
        }catch is CancellationError{}catch{if epoch == token{fail("connection: "+error.localizedDescription)}}}
    }
    func warm(language:String,engine:CompanionQuestPolicy?)async->Bool{guard let pool,let engine,let session=try? engine.run("ph_tts",.object(["language":.string(language),"voice":.string("ash")]))else{return false};return await pool.warm(session:session)}
    func receive(_ event:JSONValue){
        switch event["type"].string {
        case "output_audio_buffer.started":startup?.cancel();loading=false;playing=true;let callback=started;started=nil;callback?()
        case "response.done":guard event["response"]["status"].string == "completed" else{fail("response: "+event["response"]["status"].string);return};startup?.cancel();responseSucceeded=true;finishAfterDrain()
        case "output_audio_buffer.stopped":bufferStopped=true;finishAfterDrain()
        case "error":fail("provider: "+event["error"]["code"].string+" "+event["error"]["message"].string)
        case "output_audio_buffer.cleared":fail("buffer-cleared")
        default:break
        }
    }
    private func finishAfterDrain(){
        guard responseSucceeded,bufferStopped,drain == nil else{return};let token=epoch
        drain=Task{let delay=await client?.playbackDrainMilliseconds() ?? 1000;try? await Task.sleep(for:.milliseconds(Int(delay)));guard !Task.isCancelled,epoch == token else{return}
            if let cache,let key=cacheKey,let rules=cachePolicy?.rules,let recording=client?.completedNarrationRecording(){lastCapturedBytes=recording.pcm16.count;await cache.complete(key,recording:recording,rules:rules)}
            guard epoch == token,!Task.isCancelled else{return};let callback=finished;stopAll();callback?()}
    }
    private func cached(_ cache:NarrationAudioCache,key:String)async->NarrationAudioCache.Hit?{
        await withCheckedContinuation{continuation in var resumed=false
            let lookup=Task{let hit=await cache.load(key);guard !resumed else{return};resumed=true;continuation.resume(returning:hit)}
            Task{try? await Task.sleep(for:.milliseconds(1500));guard !resumed else{return};resumed=true;lookup.cancel();continuation.resume(returning:nil)}
        }
    }
    func stopAll(){epoch=UUID();work?.cancel();startup?.cancel();hardDeadline?.cancel();drain?.cancel();drain=nil;client?.close();client=nil;replay?.stop();replay=nil;cacheKey=nil;loading=false;playing=false;responseSucceeded=false;bufferStopped=false;started=nil;failed=nil;finished=nil;if Self.owner === self {Self.owner=nil}}
    private func fail(_ detail:String){let callback=failed;stopAll();failureDetail=String(detail.prefix(500));error="Narration could not play. Try again.";callback?()}
}

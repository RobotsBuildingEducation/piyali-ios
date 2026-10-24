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
    private var finished:(()->Void)?
    init(factory:(()->RealtimeVoiceTransport)?=nil){self.factory=factory ?? {RealtimeRTCTransport(capturesMicrophone:false,purpose:.narration)}}
    func play(_ text:String,language:String,engine:CompanionQuestPolicy?,voice:String="ash",onFinished:(()->Void)?=nil){
        guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else{return}
        Self.owner?.stopAll();stopAll();Self.owner=self;loading=true;error=nil;failureDetail=nil;finished=onFinished;let token=epoch
        work=Task{do {
            guard let engine else{throw PracticeRecipeFailure.unavailable}
            let session=try engine.run("ph_tts",.object(["language":.string(language),"voice":.string(voice)])),client=factory();self.client=client
            client.onOpen={ [weak self,weak client] in guard let self,self.epoch == token else{return};client?.setMicrophoneEnabled(false);client?.setRemoteAudioEnabled(true)
                let item:JSONValue = .object(["type":.string("conversation.item.create"),"item":.object(["type":.string("message"),"role":.string("user"),"content":.array([.object(["type":.string("input_text"),"text":.string("[NARRATE THIS TEXT EXACTLY]: "+text)])])])])
                guard client?.send(item) == true,client?.send(.object(["type":.string("response.create"),"response":.object(["output_modalities":.array([.string("audio")]),"instructions":session["instructions"]])])) == true else{self.fail("send");return}
            }
            client.onEvent={ [weak self] event in guard let self,self.epoch == token else{return};self.receive(event)}
            client.onFailure={ [weak self] detail in guard let self,self.epoch == token else{return};self.fail("transport: "+detail)}
            startup=Task{try? await Task.sleep(for:.seconds(20));if !Task.isCancelled,self.epoch == token,self.loading{self.fail("startup")}}
            hardDeadline=Task{try? await Task.sleep(for:.milliseconds(max(45000,text.count*180+10000)));if !Task.isCancelled,self.epoch == token{self.fail("deadline")}}
            try await client.connect(session:session);try Task.checkCancellation()
        }catch is CancellationError{}catch{if epoch == token{fail("connection: "+error.localizedDescription)}}}
    }
    func receive(_ event:JSONValue){
        switch event["type"].string {
        case "output_audio_buffer.started":startup?.cancel();loading=false;playing=true
        case "response.done":guard event["response"]["status"].string == "completed" else{fail("response: "+event["response"]["status"].string);return};startup?.cancel();responseSucceeded=true;finishAfterDrain()
        case "output_audio_buffer.stopped":bufferStopped=true;finishAfterDrain()
        case "error":fail("provider: "+event["error"]["code"].string+" "+event["error"]["message"].string)
        case "output_audio_buffer.cleared":fail("buffer-cleared")
        default:break
        }
    }
    private func finishAfterDrain(){
        guard responseSucceeded,bufferStopped,drain == nil else{return};let token=epoch
        drain=Task{let delay=await client?.playbackDrainMilliseconds() ?? 1000;try? await Task.sleep(for:.milliseconds(Int(delay)));guard !Task.isCancelled,epoch == token else{return};let callback=finished;stopAll();callback?()}
    }
    func stopAll(){epoch=UUID();work?.cancel();startup?.cancel();hardDeadline?.cancel();drain?.cancel();drain=nil;client?.close();client=nil;loading=false;playing=false;responseSucceeded=false;bufferStopped=false;finished=nil;if Self.owner === self {Self.owner=nil}}
    private func fail(_ detail:String){stopAll();failureDetail=String(detail.prefix(500));error="Narration could not play. Try again."}
}

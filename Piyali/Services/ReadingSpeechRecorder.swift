import Foundation
import AVFoundation
import Speech

enum ReadingRecognitionEvent { case result(String),ended,failed(String) }
struct ReadingRecognitionIssue:Error { let code:String }
@MainActor struct ReadingRecognitionClient {
    var authorize:()async throws->Void
    var begin:(Int,String,@escaping @MainActor (ReadingRecognitionEvent)->Void)throws->Void
    var finish:(Int)->Void
    var abort:(Int)->Void
    var release:()->Void
    var prepare:()->Void = {}
}
@MainActor final class ReadingSpeechRecorder:ObservableObject {
    @Published private(set) var capture=ReadingSpeechCapture()
    private let client:ReadingRecognitionClient
    private var timers:[ReadingSpeechCapture.Timer:Task<Void,Never>]=[:]
    private var starting:Task<Void,Never>?
    private var language="es"
    init(client:ReadingRecognitionClient?=nil) {
        if let client { self.client=client;return }
        #if DEBUG
        if ReadingService.fixture,ProcessInfo.processInfo.environment["PIYALI_READING_SPEECH_FIXTURE"] == "1" { self.client=FixtureReadingRecognition().client;return }
        #endif
        self.client=AppleReadingRecognition().client
    }
    var transcript:String { capture.transcript }
    var phase:ReadingSpeechCapture.Phase { capture.phase }
    var issue:String? { capture.issue }
    func restore(_ text:String) { change { $0.restore(text);return [] } }
    func start(language:String) { cancel();self.language=language;client.prepare();change { $0.start() } }
    func stop() { change { $0.stop() } }
    func cancel() { starting?.cancel();starting=nil;change { $0.cancel() };client.release() }
    private func change(_ transition:(inout ReadingSpeechCapture)->[ReadingSpeechCapture.Effect]) {
        var next=capture;let effects=transition(&next);if capture != next { capture=next }
        for effect in effects { apply(effect) }
        if capture.phase == .idle { client.release() }
    }
    private func apply(_ effect:ReadingSpeechCapture.Effect) {
        switch effect {
        case .begin(let id):
            let client=self.client,language=self.language
            starting?.cancel();starting=Task { @MainActor [weak self] in
                do {
                    try await client.authorize();guard let self,!Task.isCancelled,self.capture.session == id,self.capture.phase == .listening else { return }
                    try client.begin(id,language) { [weak self] event in self?.receive(event,session:id) }
                } catch { guard let self,!Task.isCancelled,self.capture.session == id else { return };self.receive(.failed((error as? ReadingRecognitionIssue)?.code ?? "recording-failed"),session:id) }
            }
        case .finish(let id):starting?.cancel();client.finish(id)
        case .abort(let id):starting?.cancel();client.abort(id)
        case .cancel(let key):timers.removeValue(forKey:key)?.cancel()
        case .schedule(let key,let token,let milliseconds):
            timers.removeValue(forKey:key)?.cancel();timers[key]=Task { @MainActor [weak self] in
                do { try await Task.sleep(for:.milliseconds(milliseconds));guard !Task.isCancelled else { return };self?.change { $0.fired(key,token:token) } } catch { }
            }
        }
    }
    private func receive(_ event:ReadingRecognitionEvent,session:Int) {
        change { state in switch event { case .result(let text):return state.result(session:session,text:text);case .ended:return state.ended(session:session);case .failed(let code):return state.failed(session:session,code:code) } }
    }
}

/// Stop ends microphone input, then lets Speech finish already-buffered audio.
@MainActor final class AppleReadingRecognition {
    private var engine:AVAudioEngine?,recognizer:SFSpeechRecognizer?,request:SFSpeechAudioBufferRecognitionRequest?,task:SFSpeechRecognitionTask?
    private var session:Int?,tap=false
    private var ownsAudioSession=false
    var client:ReadingRecognitionClient { .init(authorize:{ try await self.authorize() },begin:{ try self.begin($0,language:$1,callback:$2) },finish:{ self.finish($0) },abort:{ self.abort($0) },release:{ self.release() }) }
    private func authorize() async throws {
        let status:SFSpeechRecognizerAuthorizationStatus
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined { status=await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning:$0) } } }
        else { status=SFSpeechRecognizer.authorizationStatus() }
        try Task.checkCancellation();guard status == .authorized else { throw ReadingRecognitionIssue(code:"mic-denied") }
        let mic=await AVAudioApplication.requestRecordPermission();try Task.checkCancellation();guard mic else { throw ReadingRecognitionIssue(code:"mic-denied") }
    }
    private func begin(_ id:Int,language:String,callback:@escaping @MainActor (ReadingRecognitionEvent)->Void)throws {
        guard session == nil else { throw ReadingRecognitionIssue(code:"recording-failed") }
        guard let recognizer=SFSpeechRecognizer(locale:Locale(identifier:LearningLanguages.locales[language] ?? "es-MX")),recognizer.isAvailable else { throw ReadingRecognitionIssue(code:"recording-failed") }
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode:.measurement,options:[.defaultToSpeaker,.allowBluetoothHFP]);try AVAudioSession.sharedInstance().setActive(true)
        ownsAudioSession=true
        let engine=AVAudioEngine(),request=SFSpeechAudioBufferRecognitionRequest(),input=engine.inputNode,format=input.outputFormat(forBus:0)
        guard format.sampleRate > 0,format.channelCount > 0 else { throw ReadingRecognitionIssue(code:"recording-failed") }
        request.shouldReportPartialResults=true;request.taskHint = .dictation
        self.engine=engine;self.request=request;self.recognizer=recognizer;session=id
        input.installTap(onBus:0,bufferSize:1024,format:format) { buffer,_ in request.append(buffer) };tap=true
        task=recognizer.recognitionTask(with:request) { [weak self] result,error in
            let text=result?.bestTranscription.formattedString,final=result?.isFinal == true,errorCode=error.map { Self.code($0 as NSError) }
            Task { @MainActor [weak self] in
                guard let self,self.session == id else { return }
                if let text { callback(.result(text)) }
                if final || errorCode != nil {
                    self.retire();if let errorCode { callback(.failed(errorCode)) };callback(.ended)
                }
            }
        }
        do { engine.prepare();try engine.start() } catch { abort(id);throw error }
    }
    private func stopInput() { engine?.stop();if tap { engine?.inputNode.removeTap(onBus:0);tap=false };request?.endAudio() }
    private func finish(_ id:Int) { guard session == id else { return };stopInput();task?.finish() }
    private func abort(_ id:Int) { guard session == id else { return };session=nil;stopInput();task?.cancel();task=nil;request=nil;recognizer=nil;engine=nil }
    private func retire() { session=nil;stopInput();task=nil;request=nil;recognizer=nil;engine=nil }
    private func release() { if let session { abort(session) };guard ownsAudioSession else { return };ownsAudioSession=false;try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
    // Apple's documented task-error table; IPC/service failures are not Internet failures.
    nonisolated static func code(_ error:NSError)->String {
        if error.domain == "kAFAssistantErrorDomain",error.code == 1110 { return "no-speech" }
        if error.domain == "kAFAssistantErrorDomain",error.code == 1700 { return "mic-denied" }
        if error.domain == "kLSRErrorDomain",error.code == 201 { return "mic-denied" }
        if error.domain == "kLSRErrorDomain",error.code == 301 { return "aborted" }
        if error.domain == NSURLErrorDomain {
            if error.code == NSURLErrorCancelled { return "aborted" }
            if [NSURLErrorTimedOut,NSURLErrorCannotFindHost,NSURLErrorCannotConnectToHost,NSURLErrorNetworkConnectionLost,NSURLErrorNotConnectedToInternet].contains(error.code) { return "network" }
        }
        return "recording-failed"
    }
}

#if DEBUG
/// The real coordinator with isolated synthetic utterances, never a UI-only shortcut.
@MainActor private final class FixtureReadingRecognition {
    private var count=0,pending:Task<Void,Never>?
    var client:ReadingRecognitionClient { .init(authorize:{ if ProcessInfo.processInfo.environment["PIYALI_READING_CAPTURE_DENIED"] == "1" { throw ReadingRecognitionIssue(code:"mic-denied") } },begin:{ _,_,callback in
        self.count += 1
        if self.count == 1 { callback(.result("Mi libreta verde"));callback(.ended) }
        else { callback(.result("está cerca de"));self.callback=callback }
    },finish:{ _ in
        guard ProcessInfo.processInfo.environment["PIYALI_READING_CAPTURE_NO_END"] != "1" else { return }
        self.pending=Task { @MainActor in try? await Task.sleep(for:.milliseconds(100));guard !Task.isCancelled else { return };self.callback?(.result("está cerca de la ventana."));self.callback?(.ended) }
    },abort:{ _ in self.pending?.cancel() },release:{ self.pending?.cancel() },prepare:{ self.count=0;self.callback=nil }) }
    private var callback:(@MainActor (ReadingRecognitionEvent)->Void)?
}
#endif

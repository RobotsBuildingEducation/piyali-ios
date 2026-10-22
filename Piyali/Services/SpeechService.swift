import Foundation
import AVFoundation
import Speech

private final class SpeechSamples:@unchecked Sendable {
    private let lock=NSLock()
    private var count=0,squares=0.0,crossings=0,rate=0.0,previous:Float?
    func append(_ buffer:AVAudioPCMBuffer) {
        guard let data=buffer.floatChannelData?.pointee else { return }
        lock.lock();defer { lock.unlock() };rate=buffer.format.sampleRate
        for i in 0..<Int(buffer.frameLength) { let value=data[i];squares += Double(value*value);if let previous,(value >= 0) != (previous >= 0) { crossings += 1 };previous=value;count += 1 }
    }
    func metrics() -> SpeechAudioMetrics? { lock.lock();defer { lock.unlock() };guard count > 0,rate > 0 else { return nil };return .init(duration:Double(count)/rate,rms:sqrt(squares/Double(count)),zeroCrossings:crossings) }
}
@MainActor final class SpeechService: NSObject,ObservableObject,AVSpeechSynthesizerDelegate {
    @Published var transcript = ""
    @Published var recording = false
    @Published var error: String?
    @Published var confidence=0.0
    @Published var audioMetrics:SpeechAudioMetrics?
    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine:AVAudioEngine?
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var tapInstalled = false
    private var generation=UUID()
    private var samples=SpeechSamples()
    private var playback:[String]=[]
    private var playbackLanguage=""
    private var playbackStarted:(()->Void)?
    private var playbackInterrupted:(()->Void)?
    private var playbackFinished:(()->Void)?
    private var activeUtterance:AVSpeechUtterance?
    override init() { super.init();synthesizer.delegate=self }
    func speak(_ text: String, language: String) {
        speakSeries([text],language:language,onFinished:{})
    }
    func speakSeries(_ texts:[String],language:String,onStarted:(()->Void)?=nil,onInterrupted:(()->Void)?=nil,onFinished:@escaping ()->Void) {
        stopAll();playback=texts.filter { !$0.isEmpty };playbackLanguage=language;playbackStarted=onStarted;playbackInterrupted=onInterrupted;playbackFinished=onFinished
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio); try AVAudioSession.sharedInstance().setActive(true) } catch { self.error = error.localizedDescription;let interrupted=playbackInterrupted;playbackInterrupted=nil;playbackStarted=nil;playbackFinished=nil;playback=[];interrupted?();return }
        nextUtterance()
    }
    private func nextUtterance() {
        guard !playback.isEmpty else { let completion=playbackFinished;playbackFinished=nil;activeUtterance=nil;completion?();return }
        let utterance = AVSpeechUtterance(string: playback.removeFirst())
        utterance.voice = AVSpeechSynthesisVoice(language: LearningLanguages.locales[playbackLanguage] ?? "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        activeUtterance=utterance
        synthesizer.speak(utterance)
    }
    nonisolated func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didStart utterance:AVSpeechUtterance) { Task { @MainActor [weak self] in guard let self,self.activeUtterance === utterance else { return };let started=self.playbackStarted;self.playbackStarted=nil;started?() } }
    nonisolated func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didCancel utterance:AVSpeechUtterance) { Task { @MainActor [weak self] in guard let self,self.activeUtterance === utterance else { return };let interrupted=self.playbackInterrupted;self.playbackInterrupted=nil;self.playbackStarted=nil;self.playbackFinished=nil;self.playback=[];self.activeUtterance=nil;interrupted?() } }
    nonisolated func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didFinish utterance:AVSpeechUtterance) { Task { @MainActor [weak self] in guard let self,self.activeUtterance === utterance else { return };self.nextUtterance() } }
    func start(language: String) async {
        stopAll();transcript="";confidence=0;audioMetrics=nil;samples=SpeechSamples();let token=generation
        let status = await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) } }
        guard generation == token,!Task.isCancelled else { return }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard generation == token,!Task.isCancelled else { return }
        guard status == .authorized, mic else { error = "Enable microphone and speech recognition in Settings to practice aloud."; return }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: LearningLanguages.locales[language] ?? "en-US")), recognizer.isAvailable else { error = "Speech recognition is unavailable for this language. Please try again later."; return }
        do {
            let engine=audioEngine ?? AVAudioEngine();audioEngine=engine
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try AVAudioSession.sharedInstance().setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest(); request.shouldReportPartialResults = true
            self.request = request
            let node = engine.inputNode
            let statistics=samples
            node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { buffer, _ in statistics.append(buffer);request.append(buffer) }
            tapInstalled = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self,self.generation == token else { return }
                    if let result { self.transcript=result.bestTranscription.formattedString;let values=result.bestTranscription.segments.map { Double($0.confidence) };self.confidence=values.isEmpty ? 0 : values.reduce(0,+)/Double(values.count) }
                    if error != nil || result?.isFinal == true { self.stop() }
                }
            }
            engine.prepare(); try engine.start(); recording = true
        } catch { stop(); self.error = error.localizedDescription }
    }
    func stop() {
        generation=UUID()
        audioEngine?.stop()
        if tapInstalled { audioEngine?.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); task?.cancel(); task = nil; request = nil; recording = false
        audioMetrics=samples.metrics()
    }
    func stopAll() { stop();playback=[];playbackStarted=nil;playbackInterrupted=nil;playbackFinished=nil;activeUtterance=nil;synthesizer.stopSpeaking(at: .immediate) }
}

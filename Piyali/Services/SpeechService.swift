import Foundation
import AVFoundation
import Speech

@MainActor final class SpeechService: ObservableObject {
    @Published var transcript = ""
    @Published var recording = false
    @Published var error: String?
    private let synthesizer = AVSpeechSynthesizer()
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var tapInstalled = false
    func speak(_ text: String, language: String) {
        stop(); synthesizer.stopSpeaking(at: .immediate)
        do { try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio); try AVAudioSession.sharedInstance().setActive(true) } catch { self.error = error.localizedDescription; return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: LearningLanguages.locales[language] ?? "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        synthesizer.speak(utterance)
    }
    func start(language: String) async {
        stop(); synthesizer.stopSpeaking(at: .immediate); transcript = ""
        let status = await withCheckedContinuation { continuation in SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) } }
        let mic = await AVAudioApplication.requestRecordPermission()
        guard status == .authorized, mic else { error = "Enable microphone and speech recognition in Settings to practice aloud."; return }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: LearningLanguages.locales[language] ?? "en-US")), recognizer.isAvailable else { error = "Speech recognition is unavailable for this language. You can type your answer."; return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try AVAudioSession.sharedInstance().setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest(); request.shouldReportPartialResults = true
            self.request = request
            let node = engine.inputNode
            node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { buffer, _ in request.append(buffer) }
            tapInstalled = true
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result { self?.transcript = result.bestTranscription.formattedString }
                    if error != nil || result?.isFinal == true { self?.stop() }
                }
            }
            engine.prepare(); try engine.start(); recording = true
        } catch { stop(); self.error = error.localizedDescription }
    }
    func stop() {
        engine.stop()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); task?.cancel(); task = nil; request = nil; recording = false
    }
    func stopAll() { stop(); synthesizer.stopSpeaking(at: .immediate) }
}

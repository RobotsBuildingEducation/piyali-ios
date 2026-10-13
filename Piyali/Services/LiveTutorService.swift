import Foundation
import AVFoundation
import FirebaseAILogic

@MainActor final class LiveTutorService: ObservableObject {
    @Published var connected = false
    @Published var connecting = false
    @Published var transcript = ""
    @Published var error: String?
    private var session: LiveSession?
    private var receiver: Task<Void, Never>?
    private var sender: Task<Void, Never>?
    private var audioContinuation: AsyncStream<Data>.Continuation?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var tapped = false
    private var generation = UUID()
    private let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false)!
    static let openingPrompt = "Speak aloud now. Greet me briefly in my target language and start practicing my goal."
    static func model(for learner: LearnerState, configuration config: AppConfiguration = AppConfiguration()) -> LiveGenerativeModel {
        let instruction = "You are Piyali, a patient language tutor. Teach \(LearningLanguages.names[learner.target] ?? learner.target) at \(learner.level). Use \(LearningLanguages.names[learner.support] ?? learner.support) for brief explanations. Goal: \(learner.goal). Speak in short turns, correct mistakes kindly, and invite the learner to respond."
        return FirebaseAI.firebaseAI(backend:config.geminiBackend(live:true)).liveModel(
            modelName:config.string("GeminiLiveModel",default:"gemini-2.5-flash-native-audio-preview-12-2025"),
            generationConfig:LiveGenerationConfig(responseModalities:[.audio],inputAudioTranscription:AudioTranscriptionConfig(),outputAudioTranscription:AudioTranscriptionConfig()),
            systemInstruction:ModelContent(role:"system",parts:[TextPart(instruction)])
        )
    }
    func start(learner: LearnerState) async {
        guard !connected && !connecting else { return }
        guard FirebaseService.shared.configured else { error = "Add the iOS Firebase configuration and App Check registration to use live audio."; return }
        connecting = true; error = nil; transcript = ""
        let currentGeneration = UUID(); generation = currentGeneration
        defer { connecting = false }
        guard await AVAudioApplication.requestRecordPermission() else { error = "Enable the microphone in Settings to use live audio."; return }
        guard generation == currentGeneration else { return }
        do {
            let model = Self.model(for:learner)
            let newSession = try await model.connect()
            guard generation == currentGeneration else { await newSession.close(); return }
            session = newSession
            try setupAudio(session: newSession)
            connected = true
            receiver = Task { [weak self] in
                do {
                    for try await message in newSession.responses {
                        guard let self, self.generation == currentGeneration, !Task.isCancelled else { break }
                        if case .content(let content) = message.payload {
                            if content.wasInterrupted { self.player.stop(); self.player.play() }
                            if let input = content.inputAudioTranscription { self.transcript += "You: " + (input.text ?? "") + "\n" }
                            if let output = content.outputAudioTranscription { self.transcript += output.text ?? "" }
                            if self.transcript.count > 16000 { self.transcript = String(self.transcript.suffix(16000)) }
                            for part in content.modelTurn?.parts ?? [] {
                                if let audio = part as? InlineDataPart, audio.mimeType.hasPrefix("audio/pcm") { self.play(audio.data) }
                            }
                            if content.isTurnComplete { self.transcript += "\n" }
                        }
                    }
                } catch { if !Task.isCancelled { self?.error = error.localizedDescription } }
                if self?.generation == currentGeneration { await self?.stop() }
            }
            await newSession.sendTextRealtime(Self.openingPrompt)
        } catch { self.error = error.localizedDescription; await stop() }
    }
    private func setupAudio(session: LiveSession) throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try AVAudioSession.sharedInstance().setActive(true)
        if player.engine == nil { engine.attach(player) }
        engine.connect(player, to: engine.mainMixerNode, format: outputFormat)
        let input = engine.inputNode
        try input.setVoiceProcessingEnabled(true)
        let sourceFormat = input.outputFormat(forBus: 0)
        guard sourceFormat.sampleRate > 0,
              let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else { throw AppError.message("Microphone audio format is unavailable.") }
        let stream = AsyncStream<Data>(bufferingPolicy: .bufferingNewest(20)) { audioContinuation = $0 }
        let continuation = audioContinuation
        input.installTap(onBus: 0, bufferSize: 2048, format: sourceFormat) { buffer, _ in
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * 16000 / sourceFormat.sampleRate) + 1
            guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
            var consumed = false, conversionError: NSError?
            converter.convert(to: output, error: &conversionError) { _, status in
                if consumed { status.pointee = .noDataNow; return nil }
                consumed = true; status.pointee = .haveData; return buffer
            }
            if conversionError == nil, let samples = output.int16ChannelData?[0], output.frameLength > 0 {
                continuation?.yield(Data(bytes: samples, count: Int(output.frameLength) * 2))
            }
        }
        tapped = true
        sender = Task {
            for await bytes in stream { guard !Task.isCancelled else { break }; await session.sendAudioRealtime(bytes) }
        }
        engine.prepare(); try engine.start(); player.play()
    }
    private func play(_ data: Data) {
        let samples = data.count / 2
        guard samples > 0, let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(samples)), let output = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(samples)
        data.withUnsafeBytes { bytes in
            for index in 0..<samples {
                let value = Int16(littleEndian: bytes.loadUnaligned(fromByteOffset: index * 2, as: Int16.self))
                output[index] = Float(value) / 32768
            }
        }
        player.scheduleBuffer(buffer)
    }
    func stop() async {
        generation = UUID(); connected = false
        engine.stop(); player.stop()
        if tapped { engine.inputNode.removeTap(onBus: 0); tapped = false }
        audioContinuation?.finish(); audioContinuation = nil
        sender?.cancel(); sender = nil; receiver?.cancel(); receiver = nil
        let oldSession = session; session = nil
        await oldSession?.close()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

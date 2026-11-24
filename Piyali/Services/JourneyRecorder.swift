import Foundation
import AVFoundation

/// A private draft. Saving to Journey is explicit and encrypts the audio first.
@MainActor final class JourneyRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var recording = false
    @Published private(set) var starting = false
    @Published private(set) var seconds: Double = 0
    @Published private(set) var draft: Data?
    @Published private(set) var mime = "audio/mp4"
    @Published private(set) var errorKey: String?

    private let authorize: () async -> Bool
    private var recorder: AVAudioRecorder?
    private var url: URL?
    private var ownsAudioSession = false
    private var started = ProcessInfo.processInfo.systemUptime
    private var timer: Task<Void, Never>?
    private var epoch = UUID()

    init(authorize: (() async -> Bool)? = nil) {
        self.authorize = authorize ?? {
            if MemoryDrawerFixture.enabled { return true }
            return await AVAudioApplication.requestRecordPermission()
        }
    }

    func start() async {
        guard !recording, !starting else { return }
        clear()
        let token = epoch
        starting = true
        defer { if epoch == token { starting = false } }
        let granted = await authorize()
        guard epoch == token, !Task.isCancelled else { return }
        guard granted else { errorKey = "micError"; return }

        let fixture = MemoryDrawerFixture.enabled
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("piyali-journey-\(UUID().uuidString)")
            .appendingPathExtension(fixture ? "wav" : "m4a")
        url = file
        mime = fixture ? "audio/wav" : "audio/mp4"
        do {
            if fixture {
                try MemoryDrawerFixture.audio().write(to: file)
            } else {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
                try session.setActive(true)
                ownsAudioSession = true
                let recorder = try AVAudioRecorder(url: file, settings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 16_000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 48_000,
                ])
                recorder.delegate = self
                self.recorder = recorder
                guard recorder.record(forDuration: Double(VoiceJourneyModel.maxSeconds)) else {
                    clear()
                    errorKey = "micError"
                    return
                }
            }
            try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: file.path)
            started = ProcessInfo.processInfo.systemUptime
            recording = true
            timer = Task { [weak self] in
                while !Task.isCancelled, self?.tick(token) == true {
                    try? await Task.sleep(for: .milliseconds(100))
                }
            }
        } catch {
            clear()
            errorKey = "micError"
        }
    }

    private func tick(_ token: UUID) -> Bool {
        guard epoch == token, recording else { return false }
        let limit = Double(VoiceJourneyModel.maxSeconds)
        seconds = min(limit, ProcessInfo.processInfo.systemUptime - started)
        if seconds >= limit { stop() }
        return recording
    }

    func stop() {
        guard recording, let file = url else { return }
        finish(file, succeeded: true)
    }

    func interrupt() {
        if starting { clear() }
        else { stop() }
    }

    func audioSessionInterrupted(_ notification: Notification) {
        guard notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == AVAudioSession.InterruptionType.began.rawValue else { return }
        interrupt()
    }

    func audioRouteChanged(_ notification: Notification) {
        let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
        guard raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
                || raw == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue else { return }
        stop()
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let file = recorder.url
        Task { @MainActor [weak self] in self?.finish(file, succeeded: flag) }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        let file = recorder.url
        Task { @MainActor [weak self] in self?.finish(file, succeeded: false) }
    }

    private func finish(_ file: URL, succeeded: Bool) {
        guard file == url else { return }
        // stop() closes the file. An iOS audio interruption can omit the delegate callback.
        releaseCapture()
        defer { try? FileManager.default.removeItem(at: file) }
        guard succeeded, let data = try? Data(contentsOf: file),
              !data.isEmpty, data.count <= VoiceJourneyModel.maxBytes,
              let audio = try? AVAudioPlayer(data: data), audio.duration >= 1,
              audio.duration <= Double(VoiceJourneyModel.maxSeconds + 2) else {
            seconds = 0
            errorKey = "error"
            return
        }
        seconds = min(Double(VoiceJourneyModel.maxSeconds), audio.duration)
        draft = data
    }

    private func releaseCapture() {
        url = nil
        timer?.cancel()
        timer = nil
        recorder?.delegate = nil
        recorder?.stop()
        recorder = nil
        if ownsAudioSession {
            ownsAudioSession = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
        recording = false
        starting = false
    }

    func clear() {
        epoch = UUID()
        let file = url
        releaseCapture()
        if let file { try? FileManager.default.removeItem(at: file) }
        draft = nil
        seconds = 0
        errorKey = nil
    }
}

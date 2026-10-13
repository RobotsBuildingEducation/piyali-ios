import Foundation
import AVFoundation

@MainActor final class JourneyRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var recording = false
    @Published var error: String?
    @Published var savedFile: String?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    func record(account: String, milestone: Int, language: String) async {
        guard await AVAudioApplication.requestRecordPermission() else { error = "Enable microphone access in Settings."; return }
        do {
            let root = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali/Recordings/\(account)")
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true,attributes:[.protectionKey:FileProtectionType.complete])
            let filename = "\(language)-milestone-\(milestone).m4a"
            let url = root.appendingPathComponent(filename)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode:.spokenAudio,options:[.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            let recording = try AVAudioRecorder(url:url,settings:[AVFormatIDKey:kAudioFormatMPEG4AAC,AVSampleRateKey:16000,AVNumberOfChannelsKey:1,AVEncoderBitRateKey:64000])
            recording.delegate = self; recorder = recording; savedFile = nil
            guard recording.record(forDuration:45) else { throw AppError.message("Could not start recording.") }
            self.recording = true
        } catch { self.error = error.localizedDescription }
    }
    func stop() { recorder?.stop(); recording = false }
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let filename = recorder.url.lastPathComponent
        Task { @MainActor in
            recording = false
            if flag { savedFile = filename } else { error = "Recording failed. Please try again." }
        }
    }
    func play(account: String, file: String) {
        let root = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Piyali/Recordings/\(account)")
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,mode:.spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf:root.appendingPathComponent(file)); player?.play()
        } catch { self.error = error.localizedDescription }
    }
    func stopAll() { stop(); player?.stop() }
}

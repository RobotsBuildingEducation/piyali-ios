import Foundation
import AVFoundation

/// A private draft. Saving to Journey is explicit and encrypts the audio first.
@MainActor final class JourneyRecorder:NSObject,ObservableObject,AVAudioRecorderDelegate {
    @Published private(set) var recording=false
    @Published private(set) var starting=false
    @Published private(set) var stopping=false
    @Published private(set) var seconds:Double=0
    @Published private(set) var draft:Data?
    @Published private(set) var mime="audio/mp4"
    @Published private(set) var errorKey:String?
    private var recorder:AVAudioRecorder?,url:URL?,started=Date(),timer:Task<Void,Never>?,epoch=UUID()
    func start()async {
        guard !recording,!starting,!stopping else{return};clear();let token=epoch;starting=true;errorKey=nil
        defer{if epoch == token{starting=false}}
        if MemoryDrawerFixture.enabled {mime="audio/wav";recording=true;started=Date();tick(token);return}
        guard await AVAudioApplication.requestRecordPermission(),epoch == token else{if epoch == token{errorKey="micError"};return}
        do {
            let url=FileManager.default.temporaryDirectory.appendingPathComponent("piyali-journey-\(UUID().uuidString).m4a");self.url=url
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord,mode:.spokenAudio,options:[.defaultToSpeaker]);try AVAudioSession.sharedInstance().setActive(true)
            let recorder=try AVAudioRecorder(url:url,settings:[AVFormatIDKey:kAudioFormatMPEG4AAC,AVSampleRateKey:16000,AVNumberOfChannelsKey:1,AVEncoderBitRateKey:48000]);try? FileManager.default.setAttributes([.protectionKey:FileProtectionType.complete],ofItemAtPath:url.path)
            recorder.delegate=self;self.recorder=recorder;guard recorder.record(forDuration:45) else{throw AppError.message("Recording failed")};recording=true;started=Date();tick(token)
        }catch{clear();errorKey="micError"}
    }
    private func tick(_ token:UUID){timer=Task{while !Task.isCancelled,epoch == token,recording{seconds=min(45,Date().timeIntervalSince(started));if seconds>=45{stop();break};try? await Task.sleep(for:.milliseconds(100))}}}
    func stop(){
        guard recording else{return};seconds=min(45,Date().timeIntervalSince(started));recording=false;timer?.cancel()
        if MemoryDrawerFixture.enabled {draft=MemoryDrawerFixture.audio();seconds=1.5;return}
        stopping=true;recorder?.stop()
    }
    nonisolated func audioRecorderDidFinishRecording(_ recorder:AVAudioRecorder,successfully flag:Bool){let file=recorder.url;Task{@MainActor in guard file == url else{return};recording=false;stopping=false;timer?.cancel();if flag,let data=try? Data(contentsOf:file),seconds>=1,data.count<=VoiceJourneyModel.maxBytes{draft=data}else{errorKey="error"};try? FileManager.default.removeItem(at:file);url=nil;self.recorder=nil}}
    func clear(){epoch=UUID();timer?.cancel();recorder?.delegate=nil;recorder?.stop();recorder=nil;if let url{try? FileManager.default.removeItem(at:url)};url=nil;recording=false;starting=false;stopping=false;draft=nil;seconds=0}
}

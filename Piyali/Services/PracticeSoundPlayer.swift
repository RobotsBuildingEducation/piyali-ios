import AVFoundation

/// Short exported source quest sounds. Playback uses the existing session so
/// it cannot change a live activity's microphone category or route.
@MainActor final class PracticeSoundPlayer:NSObject,AVAudioPlayerDelegate {
    private var player:AVAudioPlayer?
    func play(_ name:String,enabled:Bool=true){
        guard enabled else{return}
        guard ["questComplete","questCleared"].contains(name),let url=Bundle.main.url(forResource:name,withExtension:"wav") else{return}
        player=try? AVAudioPlayer(contentsOf:url);player?.delegate=self;player?.play()
    }
    func stop(){player?.stop();player=nil}
}

import AVFoundation

/// Short exported source quest sounds. Playback uses the existing session so
/// it cannot change a live activity's microphone category or route.
@MainActor final class PracticeSoundPlayer:NSObject,AVAudioPlayerDelegate {
    private var player:AVAudioPlayer?
    func play(_ name:String,enabled:Bool=true,volume:Double=100){
        guard enabled else{return}
        guard ["questComplete","questCleared","companionUnlock","rpgStep","rpgDialogueOpen","rpgDialogueSelect"].contains(name),let url=Bundle.main.url(forResource:name,withExtension:"wav") else{return}
        player=try? AVAudioPlayer(contentsOf:url);player?.delegate=self;player?.volume=Float(max(0,min(100,volume))/100);player?.play()
    }
    func stop(){player?.stop();player=nil}
}

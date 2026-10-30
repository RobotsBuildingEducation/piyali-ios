import Foundation
import AVFoundation
@MainActor final class RPGMusicPlayer:ObservableObject {
    private var player:AVAudioPlayer?
    func apply(_ enabled:Bool){guard enabled else{stop();return};do{if player == nil,let url=Bundle.main.url(forResource:"RPGWalk",withExtension:"mp3"){player=try AVAudioPlayer(contentsOf:url);player?.numberOfLoops = -1;player?.volume=0.02};player?.play()}catch{stop()}}
    func stop(){player?.stop();player=nil}
}

import Foundation
import AVFoundation

@MainActor protocol NarrationReplay:AnyObject {
    var onFinished:(()->Void)?{get set};var onFailed:(()->Void)?{get set}
    func play(_ wav:Data)throws
    func stop()
}
@MainActor final class NarrationReplayPlayer:NSObject,NarrationReplay,AVAudioPlayerDelegate {
    var onFinished:(()->Void)?,onFailed:(()->Void)?
    private let volume:Float,managesAudioSession:Bool
    init(volume:Double=1,managesAudioSession:Bool=true){self.volume=Float(max(0,min(1,volume)));self.managesAudioSession=managesAudioSession;super.init()}
    private let audioLease=UUID()
    private var player:AVAudioPlayer?,interruption:NSObjectProtocol?,active=false
    func play(_ wav:Data)throws{
        if managesAudioSession || NativeVoiceAudioLease.hasOwners{try NativeVoiceAudioLease.acquire(audioLease,playbackOnly:true);active=true}
        do{let player=try AVAudioPlayer(data:wav);self.player=player;player.volume=volume;player.delegate=self;guard player.prepareToPlay(),player.play()else{throw AppError.message("Cached narration could not play.")}
            interruption=NotificationCenter.default.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main){[weak self] notification in guard let type=notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,type==AVAudioSession.InterruptionType.began.rawValue else{return};Task{@MainActor [weak self] in self?.onFailed?()}}
        }catch{stop();throw error}
    }
    func stop(){player?.delegate=nil;player?.stop();player=nil;if let interruption{NotificationCenter.default.removeObserver(interruption)};interruption=nil;onFinished=nil;onFailed=nil;if active{NativeVoiceAudioLease.release(audioLease);active=false}}
    nonisolated func audioPlayerDidFinishPlaying(_ player:AVAudioPlayer,successfully flag:Bool){Task{@MainActor [weak self] in guard let self,self.player === player else{return};if flag{self.onFinished?()}else{self.onFailed?()}}}
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player:AVAudioPlayer,error:Error?){Task{@MainActor [weak self] in guard let self,self.player === player else{return};self.onFailed?()}}
}

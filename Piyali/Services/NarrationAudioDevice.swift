import Foundation
import AVFoundation
import WebRTC

/// Receive-only ADM: polls WebRTC playout into the speaker and a bounded local PCM recording.
/// No input node or microphone data is opened. Conversation transports keep the default ADM.
final class NarrationAudioDevice:NSObject,RTCAudioDevice {
    private weak var delegate:RTCAudioDeviceDelegate?
    private var engine:AVAudioEngine?,source:AVAudioSourceNode?
    private var initialized=false,ready=false,playing=false
    private let lock=NSLock(),capacity=48000*180
    private let capture:UnsafeMutablePointer<Int16>,scratch:UnsafeMutablePointer<Int16>
    private var count=0,overflow=false,recording=true,gain:Float=1
    private var observers:[NSObjectProtocol]=[]
    override init(){capture = .allocate(capacity:capacity);scratch = .allocate(capacity:32768);super.init()}
    deinit{observers.forEach(NotificationCenter.default.removeObserver);capture.deallocate();scratch.deallocate()}
    var deviceInputSampleRate:Double{48000};var inputIOBufferDuration:TimeInterval{0.01};var inputNumberOfChannels:Int{1};var inputLatency:TimeInterval{0}
    var deviceOutputSampleRate:Double{48000};var outputIOBufferDuration:TimeInterval{AVAudioSession.sharedInstance().ioBufferDuration};var outputNumberOfChannels:Int{1};var outputLatency:TimeInterval{AVAudioSession.sharedInstance().outputLatency}
    var isInitialized:Bool{initialized};var isPlayoutInitialized:Bool{ready};var isPlaying:Bool{playing}
    var isRecordingInitialized:Bool{false};var isRecording:Bool{false}
    func initialize(with delegate:RTCAudioDeviceDelegate)->Bool{
        self.delegate=delegate;initialized=true
        observers.append(NotificationCenter.default.addObserver(forName:AVAudioSession.routeChangeNotification,object:nil,queue:nil){[weak self] _ in guard let self,let delegate=self.delegate else{return};delegate.dispatchAsync{[weak self] in guard let self,self.initialized else{return};let resume=self.playing;_=self.stopPlayout();delegate.notifyAudioOutputInterrupted();delegate.notifyAudioOutputParametersChange();if resume{_=self.startPlayout()}}})
        return true
    }
    func terminateDevice()->Bool{_=stopPlayout();initialized=false;ready=false;delegate=nil;observers.forEach(NotificationCenter.default.removeObserver);observers=[];return true}
    func initializePlayout()->Bool{ready=initialized;return ready}
    func startPlayout()->Bool{
        guard initialized,let delegate else{return false};if playing{return true}
        do{let engine=AVAudioEngine(),format=AVAudioFormat(standardFormatWithSampleRate:48000,channels:1)!
            let source=AVAudioSourceNode(format:format){[weak self,weak delegate] flags,time,frames,buffers in
                guard let self,let delegate,frames<=32768 else{return kAudioUnitErr_TooManyFramesToProcess}
                var pcm=AudioBufferList(mNumberBuffers:1,mBuffers:AudioBuffer(mNumberChannels:1,mDataByteSize:frames*2,mData:self.scratch))
                var renderFlags=AudioUnitRenderActionFlags();flags.pointee=false;let status=delegate.getPlayoutData(&renderFlags,time,0,frames,&pcm)
                if status != noErr{for buffer in UnsafeMutableAudioBufferListPointer(buffers){if let data=buffer.mData{memset(data,0,Int(buffer.mDataByteSize))}};return status}
                self.lock.lock();if self.recording{if self.count+Int(frames)<=self.capacity{self.capture.advanced(by:self.count).update(from:self.scratch,count:Int(frames));self.count+=Int(frames)}else{self.overflow=true}};self.lock.unlock()
                for buffer in UnsafeMutableAudioBufferListPointer(buffers){guard let raw=buffer.mData else{continue};let output=raw.assumingMemoryBound(to:Float.self);for i in 0..<Int(frames){output[i]=Float(self.scratch[i])/32768}}
                return noErr
            }
            lock.lock();engine.mainMixerNode.outputVolume=gain;lock.unlock();engine.attach(source);engine.connect(source,to:engine.mainMixerNode,format:format);engine.prepare();try engine.start();self.engine=engine;self.source=source;playing=true;ready=true;return true
        }catch{return false}
    }
    func stopPlayout()->Bool{engine?.stop();engine=nil;source=nil;playing=false;return true}
    func initializeRecording()->Bool{false};func startRecording()->Bool{false};func stopRecording()->Bool{true}
    func completedRecording()->NarrationRecording?{lock.lock();defer{lock.unlock()};recording=false;guard !overflow,count>0 else{return nil};return .init(pcm16:Data(bytes:capture,count:count*2),sampleRate:48000,channels:1)}
    func setGain(_ value:Double){lock.lock();gain=Float(max(0,min(1,value)));let value=gain;lock.unlock();delegate?.dispatchAsync{[weak self] in self?.engine?.mainMixerNode.outputVolume=value}}
    func shutdown(){lock.lock();recording=false;lock.unlock();delegate?.dispatchSync{[weak self] in _=self?.stopPlayout()}}
}

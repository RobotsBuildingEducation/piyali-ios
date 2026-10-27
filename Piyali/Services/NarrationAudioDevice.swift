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
    private var count=0,overflow=false,recording=true,gain:Float=1,outputEnabled=true
    private var silent:SilentNarrationDrain?
    private var idleFrames=0
    private var observers:[NSObjectProtocol]=[]
    init(deferred:Bool=false){outputEnabled = !deferred;recording = !deferred;capture = .allocate(capacity:capacity);scratch = .allocate(capacity:32768);super.init()}
    deinit{_=silent?.stop();observers.forEach(NotificationCenter.default.removeObserver);capture.deallocate();scratch.deallocate()}
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
        lock.lock();let enabled=outputEnabled;lock.unlock()
        if !enabled{
            silent=SilentNarrationDrain{[weak self,weak delegate] sampleTime in
                guard let self,let delegate else{return false};var timestamp=AudioTimeStamp();timestamp.mSampleTime=sampleTime;timestamp.mHostTime=mach_absolute_time();timestamp.mFlags=[.sampleTimeValid,.hostTimeValid];var flags=AudioUnitRenderActionFlags(),buffer=AudioBufferList(mNumberBuffers:1,mBuffers:AudioBuffer(mNumberChannels:1,mDataByteSize:960,mData:self.scratch))
                let status=delegate.getPlayoutData(&flags,&timestamp,0,480,&buffer);if status==noErr{self.lock.lock();self.idleFrames+=480;self.lock.unlock()};return status==noErr
            };playing=true;ready=true;return true
        }
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
    func stopPlayout()->Bool{let stopped=silent?.stop() ?? true;if stopped{silent=nil};engine?.stop();engine=nil;source=nil;playing=false;return stopped}
    func initializeRecording()->Bool{false};func startRecording()->Bool{false};func stopRecording()->Bool{true}
    func completedRecording()->NarrationRecording?{lock.lock();defer{lock.unlock()};recording=false;guard !overflow,count>0 else{return nil};return .init(pcm16:Data(bytes:capture,count:count*2),sampleRate:48000,channels:1)}
    func setGain(_ value:Double){lock.lock();gain=Float(max(0,min(1,value)));let value=gain;lock.unlock();delegate?.dispatchAsync{[weak self] in self?.engine?.mainMixerNode.outputVolume=value}}
    func activateOutput()->Bool{
        lock.lock();let enabled=outputEnabled;lock.unlock();if enabled{return true}
        var result=true
        let activate={[self] in let resume=playing;guard stopPlayout()else{result=false;return};delegate?.notifyAudioOutputInterrupted();lock.lock();outputEnabled=true;recording=true;count=0;overflow=false;lock.unlock();if resume{result=startPlayout()}}
        if let delegate{delegate.dispatchSync(activate)}else{activate()};return result
    }
    func idleDrainedFrames()->Int{lock.lock();defer{lock.unlock()};return idleFrames}
    func shutdown(){lock.lock();recording=false;lock.unlock();delegate?.dispatchSync{[weak self] in _=self?.stopPlayout()}}
}

/// One OS thread drains idle RTP without opening an audio session. The SDK requires a stable
/// playout thread until notifyAudioOutputInterrupted is sent during the speaker handoff.
private final class SilentNarrationDrain {
    private let lock=NSLock(),finished=DispatchSemaphore(value:0)
    private var cancelled=false,thread:Thread?
    init(pull:@escaping(Double)->Bool){
        let thread=Thread{[self] in defer{finished.signal()};var sampleTime=0.0
            while true{lock.lock();let stop=cancelled;lock.unlock();if stop{break};let okay=autoreleasepool{pull(sampleTime)};if !okay{break};sampleTime+=480;Thread.sleep(forTimeInterval:0.01)}
        };thread.name="Piyali silent narration receiver";thread.qualityOfService = .userInitiated;self.thread=thread;thread.start()
    }
    func stop()->Bool{lock.lock();cancelled=true;let current=thread;lock.unlock();guard let current else{return true};guard current !== Thread.current else{return false};let done=finished.wait(timeout:.now()+0.5)==.success;if done{lock.lock();thread=nil;lock.unlock()};return done}
}

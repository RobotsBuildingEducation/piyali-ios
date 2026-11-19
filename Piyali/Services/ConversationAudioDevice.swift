import AVFoundation
import WebRTC

/// Full-duplex WebRTC audio device. Replay captures only the remote PCM handed
/// to the speaker. Microphone inputs go directly to WebRTC and are never cached.
final class ConversationAudioDevice: NSObject, RTCAudioDevice {
    private static let framesPerSlice = 8192
    private static let maximumReplySeconds = 180
    private weak var delegate: RTCAudioDeviceDelegate?
    private let inputEnabled: Bool
    private var unit: AudioUnit?
    private var observers: [NSObjectProtocol] = []
    private var initialized = false
    private var playoutReady = false
    private var recordingReady = false
    private var running = false
    private var interrupted = false
    private var sampleRate: Double = 48_000

    private let lock = NSLock()
    private var failureHandler: (() -> Void)?
    var onUnavailable: (() -> Void)? {
        get { lock.withLock { failureHandler } }
        set { lock.withLock { failureHandler = newValue } }
    }
    private var playing = false
    private var recording = false
    private var microphoneEnabled = false
    private var gain: Float = 1
    private let microphone = UnsafeMutablePointer<Int16>.allocate(capacity: framesPerSlice)
    private let reply = UnsafeMutablePointer<Int16>.allocate(capacity: 48_000 * maximumReplySeconds)
    private var replyID = ""
    private var replyRate: Double = 48_000
    private var sampleCount = 0
    private var loudSampleCount = 0
    private var lastLoudSample = 0
    private var overflow = false

    init(inputEnabled: Bool) {
        self.inputEnabled = inputEnabled
        super.init()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        disposeUnit()
        microphone.deallocate()
        reply.deallocate()
    }

    var deviceInputSampleRate: Double { sampleRate }
    var inputIOBufferDuration: TimeInterval { AVAudioSession.sharedInstance().ioBufferDuration }
    var inputNumberOfChannels: Int { 1 }
    var inputLatency: TimeInterval { AVAudioSession.sharedInstance().inputLatency }
    var deviceOutputSampleRate: Double { sampleRate }
    var outputIOBufferDuration: TimeInterval { AVAudioSession.sharedInstance().ioBufferDuration }
    var outputNumberOfChannels: Int { 1 }
    var outputLatency: TimeInterval { AVAudioSession.sharedInstance().outputLatency }
    var isInitialized: Bool { initialized }
    var isPlayoutInitialized: Bool { playoutReady }
    var isRecordingInitialized: Bool { recordingReady }
    var isPlaying: Bool { lock.withLock { playing } }
    var isRecording: Bool { lock.withLock { recording } }

    func initialize(with delegate: RTCAudioDeviceDelegate) -> Bool {
        self.delegate = delegate
        initialized = true
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self, let delegate = self.delegate,
                  let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) != .categoryChange else { return }
            delegate.dispatchAsync { [weak self] in self?.restartAudio() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self, let delegate = self.delegate,
                  let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let phase = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            delegate.dispatchAsync { [weak self] in
                guard let self, self.initialized else { return }
                self.interrupted = phase == .began
                self.restartAudio()
            }
        })
        return true
    }

    func terminateDevice() -> Bool {
        disposeUnit()
        lock.withLock { playing = false; recording = false }
        initialized = false
        playoutReady = false
        recordingReady = false
        delegate = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        return true
    }

    func initializePlayout() -> Bool { playoutReady = initialized; return playoutReady }
    func initializeRecording() -> Bool { recordingReady = initialized && inputEnabled; return recordingReady }
    func startPlayout() -> Bool { setActive(playout: true) }
    func stopPlayout() -> Bool { setActive(playout: false) }
    func startRecording() -> Bool { inputEnabled && setActive(input: true) }
    func stopRecording() -> Bool { setActive(input: false) }

    private func setActive(playout: Bool? = nil, input: Bool? = nil) -> Bool {
        lock.withLock {
            if let playout { playing = playout }
            if let input { recording = input }
        }
        if updateUnit() { return true }
        lock.withLock {
            if playout == true { playing = false }
            if input == true { recording = false }
        }
        return false
    }

    private func restartAudio() {
        guard initialized else { return }
        disposeUnit()
        delegate?.notifyAudioInputInterrupted()
        delegate?.notifyAudioOutputInterrupted()
        _ = updateUnit()
    }

    private func updateUnit() -> Bool {
        guard !interrupted, lock.withLock({ playing || recording }) else {
            disposeUnit()
            return true
        }
        if running { return true }
        guard openUnit(), let unit, AudioOutputUnitStart(unit) == noErr else {
            disposeUnit()
            onUnavailable?()
            return false
        }
        running = true
        return true
    }

    private func openUnit() -> Bool {
        var description = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_VoiceProcessingIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        guard let component = AudioComponentFindNext(nil, &description) else { return false }
        var instance: AudioUnit?
        guard AudioComponentInstanceNew(component, &instance) == noErr, let instance else { return false }
        unit = instance
        let sessionRate = AVAudioSession.sharedInstance().sampleRate
        lock.withLock {
            sampleRate = sessionRate >= 8_000 && sessionRate <= 48_000 ? sessionRate : 48_000
            if sampleCount == 0 { replyRate = sampleRate }
        }
        var format = AudioStreamBasicDescription(mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked, mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2, mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
        var enabled: UInt32 = inputEnabled ? 1 : 0
        guard AudioUnitSetProperty(instance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enabled, 4) == noErr,
              AudioUnitSetProperty(instance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, UInt32(MemoryLayout.size(ofValue: format))) == noErr else { return false }

        let context = Unmanaged.passUnretained(self).toOpaque()
        var output = AURenderCallbackStruct(inputProc: { context, flags, time, bus, frames, data in
            Unmanaged<ConversationAudioDevice>.fromOpaque(context).takeUnretainedValue().render(flags, time, bus, frames, data)
        }, inputProcRefCon: context)
        guard AudioUnitSetProperty(instance, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &output, UInt32(MemoryLayout.size(ofValue: output))) == noErr else { return false }

        if inputEnabled {
            var input = AURenderCallbackStruct(inputProc: { context, flags, time, bus, frames, _ in
                Unmanaged<ConversationAudioDevice>.fromOpaque(context).takeUnretainedValue().captureMicrophone(flags, time, bus, frames)
            }, inputProcRefCon: context)
            guard AudioUnitSetProperty(instance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, UInt32(MemoryLayout.size(ofValue: format))) == noErr,
                  AudioUnitSetProperty(instance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &input, UInt32(MemoryLayout.size(ofValue: input))) == noErr else { return false }
        }

        delegate?.notifyAudioInputParametersChange()
        delegate?.notifyAudioOutputParametersChange()
        return AudioUnitInitialize(instance) == noErr
    }

    private func disposeUnit() {
        guard let unit else { return }
        if running { AudioOutputUnitStop(unit) }
        AudioUnitUninitialize(unit)
        AudioComponentInstanceDispose(unit)
        self.unit = nil
        running = false
    }

    private func render(_ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, _ time: UnsafePointer<AudioTimeStamp>, _ bus: UInt32, _ frames: UInt32, _ buffers: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
        guard let buffers else { return kAudioUnitErr_InvalidParameter }
        guard isPlaying, let delegate else {
            for buffer in UnsafeMutableAudioBufferListPointer(buffers) {
                if let data = buffer.mData { memset(data, 0, Int(buffer.mDataByteSize)) }
            }
            flags.pointee.insert(.unitRenderAction_OutputIsSilence)
            return noErr
        }
        let status = delegate.getPlayoutData(flags, time, Int(bus), frames, buffers)
        guard status == noErr, let raw = buffers.pointee.mBuffers.mData,
              buffers.pointee.mNumberBuffers == 1,
              buffers.pointee.mBuffers.mDataByteSize >= frames * 2 else { return status }
        let pcm = raw.assumingMemoryBound(to: Int16.self)
        lock.withLock {
            recordReply(pcm, frames: Int(frames))
            if gain != 1 {
                for index in 0..<Int(frames) { pcm[index] = Int16(Float(pcm[index]) * gain) }
            }
        }
        return status
    }

    private func captureMicrophone(_ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, _ time: UnsafePointer<AudioTimeStamp>, _ bus: UInt32, _ frames: UInt32) -> OSStatus {
        guard frames <= Self.framesPerSlice, let unit, let delegate else { return noErr }
        var buffer = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 1, mDataByteSize: frames * 2, mData: microphone))
        let status = AudioUnitRender(unit, flags, time, bus, frames, &buffer)
        guard status == noErr, lock.withLock({ recording && microphoneEnabled }) else { return status }
        return delegate.deliverRecordedData(flags, time, Int(bus), frames, &buffer, nil, nil)
    }

    func setMicrophoneEnabled(_ enabled: Bool) { lock.withLock { microphoneEnabled = enabled } }
    func setGain(_ volume: Double) { lock.withLock { gain = volume.isFinite ? Float(max(0, min(1, volume))) : 1 } }

    func beginReply(_ id: String) {
        lock.withLock {
            replyID = id
            replyRate = sampleRate
            sampleCount = 0
            loudSampleCount = 0
            lastLoudSample = 0
            overflow = false
        }
    }

    /// Called under the render lock with samples from getPlayoutData only.
    private func recordReply(_ pcm: UnsafePointer<Int16>, frames: Int) {
        guard !replyID.isEmpty, !overflow, replyRate == sampleRate else { return }
        guard sampleCount + frames <= Int(sampleRate) * Self.maximumReplySeconds else { overflow = true; return }
        var power: Int64 = 0
        for sample in UnsafeBufferPointer(start: pcm, count: frames) {
            let amplitude = Int64(sample)
            power += amplitude * amplitude
        }
        let loud = power >= Int64(frames) * 38_655
        if loud { loudSampleCount += frames; lastLoudSample = sampleCount + frames }
        if loudSampleCount > 0 {
            reply.advanced(by: sampleCount).update(from: pcm, count: frames)
            sampleCount += frames
        }
    }

    func replyIsQuiet(_ id: String) -> Bool {
        lock.withLock {
            replyID == id && loudSampleCount > 0 && Double(sampleCount - lastLoudSample) >= sampleRate * 0.9
        }
    }

    func takeReply(_ id: String) -> NarrationRecording? {
        lock.withLock {
            guard !id.isEmpty, id == replyID else { return nil }
            defer { replyID = ""; sampleCount = 0 }
            guard !overflow, loudSampleCount > 0, lastLoudSample > 0 else { return nil }
            return NarrationRecording(pcm16: Data(bytes: reply, count: lastLoudSample * 2), sampleRate: Int(replyRate), channels: 1)
        }
    }
}

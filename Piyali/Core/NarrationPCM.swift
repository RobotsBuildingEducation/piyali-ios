import Foundation

struct NarrationPCM:Sendable {
    let sampleRate:Int,channels:Int
    let samples:[Float]
    var frames:Int{samples.count/max(1,channels)}
    struct Rules:Decodable,Sendable {
        let LEAD_IN_SECONDS,LEAD_OUT_SECONDS,MIN_TRIM_SECONDS,SOUND_THRESHOLD,MIN_PEAK_AMPLITUDE,MIN_SPEECH_DURATION_SECONDS,MIN_RMS_AMPLITUDE:Double
    }
    struct Analysis:Equatable,Sendable{let audible:Bool,start:Int,end:Int}
    func analyze(_ rules:Rules)->Analysis{
        guard channels>0,sampleRate>0,frames>0,samples.count%channels == 0 else{return .init(audible:false,start:0,end:0)}
        var peak=0.0,squares=0.0,audible=0,first:Int?,last:Int?
        for frame in 0..<frames{for channel in 0..<channels{let x=Double(samples[frame*channels+channel]);guard x.isFinite else{return .init(audible:false,start:0,end:0)};let value=abs(x);peak=max(peak,value);squares+=x*x;if value>=0.01{audible+=1};if value>=rules.SOUND_THRESHOLD{if first == nil{first=frame};last=frame}}}
        let start=first.map{max(0,$0-Int(ceil(Double(sampleRate)*rules.LEAD_IN_SECONDS)))} ?? 0,end=last.map{min(frames,$0+Int(ceil(Double(sampleRate)*rules.LEAD_OUT_SECONDS)))} ?? 0
        return .init(audible:peak>=rules.MIN_PEAK_AMPLITUDE && Double(audible)/Double(sampleRate*channels)>=rules.MIN_SPEECH_DURATION_SECONDS && sqrt(squares/Double(samples.count))>=rules.MIN_RMS_AMPLITUDE,start:Double(start)>=Double(sampleRate)*rules.MIN_TRIM_SECONDS ? start:0,end:Double(frames-end)>=Double(sampleRate)*rules.MIN_TRIM_SECONDS ? end:frames)
    }
    func wav(start:Int,end:Int)->Data{
        let lo=max(0,min(frames,start)),hi=max(lo,min(frames,end)),count=(hi-lo)*channels*2;var data=Data()
        func text(_ s:String){data.append(contentsOf:s.utf8)}
        func u16(_ n:UInt16){var value=n.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}}
        func u32(_ n:UInt32){var value=n.littleEndian;withUnsafeBytes(of:&value){data.append(contentsOf:$0)}}
        text("RIFF");u32(UInt32(36+count));text("WAVEfmt ");u32(16);u16(1);u16(UInt16(channels));u32(UInt32(sampleRate));u32(UInt32(sampleRate*channels*2));u16(UInt16(channels*2));u16(16);text("data");u32(UInt32(count))
        for index in lo*channels..<hi*channels{let sample=max(-1,min(1,Double(samples[index]))),value=Int16(max(-32768,min(32767,floor(sample*(sample<0 ? 32768:32767)+0.5))));u16(UInt16(bitPattern:value))}
        return data
    }
}

struct NarrationRecording:Sendable{let pcm16:Data,sampleRate:Int,channels:Int}

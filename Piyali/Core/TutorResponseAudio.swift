import Foundation

/// Keeps played PCM attached to its response, including a played prefix when
/// a turn is interrupted. Queued buffers never become a saved reply.
struct TutorResponseAudio {
    private(set) var responseID=""
    private var bytes=Data(),overflow=false
    private let limit:Int
    init(limit:Int=16*1024*1024){self.limit=limit}
    mutating func begin(_ id:String){responseID=id;bytes=Data();overflow=false}
    mutating func played(_ pcm:Data,response:String,gain:Double=1){
        guard !response.isEmpty,response == responseID,!overflow,pcm.count%2 == 0 else{return}
        guard bytes.count+pcm.count<=limit else{bytes=Data();overflow=true;return}
        let gain=gain.isFinite ? max(0,min(1,gain)):1
        if gain == 1{bytes.append(pcm);return}
        var adjusted=Data(capacity:pcm.count)
        pcm.withUnsafeBytes{raw in for offset in stride(from:0,to:pcm.count,by:2){let sample=raw.loadUnaligned(fromByteOffset:offset,as:Int16.self).littleEndian;var value=Int16((Double(sample)*gain).rounded()).littleEndian;withUnsafeBytes(of:&value){adjusted.append(contentsOf:$0)}}}
        bytes.append(adjusted)
    }
    mutating func take(_ id:String)->NarrationRecording?{
        guard !id.isEmpty,id == responseID else{return nil}
        defer{responseID="";bytes=Data();overflow=false}
        guard !overflow,!bytes.isEmpty else{return nil}
        return .init(pcm16:bytes,sampleRate:24000,channels:1)
    }
}

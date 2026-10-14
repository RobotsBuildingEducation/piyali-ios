import Foundation

public struct SpeechAudioMetrics:Codable,Equatable,Sendable {
    public let duration:Double
    public let rms:Double
    public let zeroCrossings:Int
    public init(duration:Double,rms:Double,zeroCrossings:Int) { self.duration=duration;self.rms=rms;self.zeroCrossings=zeroCrossings }
}
public struct StorySpeechResult:Codable,Equatable,Sendable {
    public let pass:Bool
    public let score:Int
    public let reasons:[String]
    public let charSim:Double
    public let f1:Double
    public let langLike:Double
    public let confidence:Double
}
public enum StorySpeech {
    private static let config=StorySpeechRules.configuration
    private static func normalize(_ text:String) -> String {
        text.decomposedStringWithCanonicalMapping.replacingOccurrences(of:"\\p{Diacritic}",with:"",options:.regularExpression).lowercased().replacingOccurrences(of:"[^\\p{L}\\p{N}ʼ' -]",with:" ",options:.regularExpression).replacingOccurrences(of:"\\s+",with:" ",options:.regularExpression).trimmingCharacters(in:.whitespacesAndNewlines)
    }
    public static func evaluate(recognized:String,target:String,lang:String,confidence:Double = 0,audio:SpeechAudioMetrics? = nil) -> StorySpeechResult {
        let cfg=config["thresholds"][lang] == .null ? config["thresholds"]["default"] : config["thresholds"][lang]
        let a=normalize(String(recognized.prefix(8000))),b=normalize(String(target.prefix(8000))),rec=a.split(separator:" ").map(String.init),tgt=b.split(separator:" ").map(String.init)
        let stop=Set((config["stopwords"][lang] == .null ? config["stopwords"]["en"] : config["stopwords"][lang]).array.map(\.string))
        let rw=rec.filter { !stop.contains($0) },tw=tgt.filter { !stop.contains($0) }
        var counts:[String:Int]=[:];for word in rw { counts[word,default:0] += 1 };var hit=0;for word in tw where counts[word,default:0] > 0 { hit += 1;counts[word,default:0] -= 1 }
        let precision=rw.isEmpty ? 0 : Double(hit)/Double(rw.count),recall=tw.isEmpty ? 0 : Double(hit)/Double(tw.count),f1=precision+recall == 0 ? 0 : 2*precision*recall/(precision+recall)
        let A=Array(a.utf16),B=Array(b.utf16);var distance=Array(0...B.count)
        for i in A.indices { var previous=distance[0];distance[0]=i+1;for j in B.indices { let temp=distance[j+1];distance[j+1]=A[i] == B[j] ? previous : 1+min(previous,distance[j],distance[j+1]);previous=temp } }
        let charSim=1-Double(distance.last!)/Double(max(1,max(A.count,B.count)))
        let letters=rec.filter { $0.range(of:"^[a-zñáéíóúü]+$",options:[.regularExpression,.caseInsensitive]) != nil }.count,stops=rec.filter { stop.contains($0) }.count
        var langLike=rec.isEmpty ? 0 : 0.8*Double(letters)/Double(rec.count)+0.2*Double(stops)/Double(max(2,rec.count))
        // The browser helper's Latin-only likelihood rejects every correctly spoken non-Latin line.
        if ["ar","el","hi","ja","ru","zh"].contains(lang),!rec.isEmpty,StoryEpisode.compatible([target],target:lang) { langLike=StoryEpisode.compatible([recognized],target:lang) ? 1 : 0 }
        var reasons:[String]=[]
        if let audio {
            let expected=max(cfg["MIN_SPEECH_SEC"].number,Double(target.utf16.count)*cfg["DURATION_PER_CHAR_SEC"].number),ratio=audio.duration/expected,zps=audio.duration > 0 ? Double(audio.zeroCrossings)/audio.duration : 0
            if !audio.duration.isFinite || audio.duration < cfg["MIN_SPEECH_SEC"].number || !audio.rms.isFinite || audio.rms < cfg["MIN_RMS"].number || zps < cfg["MIN_ZCR_PSEC"].number || zps > cfg["MAX_ZCR_PSEC"].number || ratio < cfg["DURATION_TOLERANCE"].array[0].number || ratio > cfg["DURATION_TOLERANCE"].array[1].number { reasons.append("speech-quality") }
        }
        if langLike < cfg["MIN_LANG_LIKE"].number { reasons.append("not-target-lang") }
        if charSim < cfg["MIN_CHAR_SIM"].number { reasons.append("low-char-sim") }
        if f1 < cfg["MIN_WORD_F1"].number { reasons.append("low-word-f1") }
        if confidence > 0,confidence < cfg["MIN_CONFIDENCE"].number { reasons.append("low-confidence") }
        let score=Int(max(0,min(100,charSim*60+f1*35+langLike*20+max(confidence == 0 ? 0.55 : confidence,0.55)*15)).rounded())
        return .init(pass:reasons.isEmpty,score:score,reasons:reasons,charSim:charSim,f1:f1,langLike:langLike,confidence:confidence)
    }
}

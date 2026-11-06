import Foundation

public enum GeminiTutorWire {
    public static func setup(_ config:JSONValue,modelResource:String)->JSONValue {
        let system=[config["instructions"].string,config["responseInstructionsSuffix"].string].filter{!$0.isEmpty}.joined(separator:"\n\n")
        var fields:[String:JSONValue]=["model":.string(modelResource),"generationConfig":.object(["responseModalities":.array([.string("AUDIO")]),"speechConfig":.object(["voiceConfig":.object(["prebuiltVoiceConfig":.object(["voiceName":config["voice"]])])])]),"inputAudioTranscription":config["inputLanguageCodes"].array.isEmpty ? .object([:]):.object(["languageCodes":config["inputLanguageCodes"]]),"outputAudioTranscription":.object([:])]
        if config["includeTranscriptions"] == .bool(false){fields.removeValue(forKey:"inputAudioTranscription");fields.removeValue(forKey:"outputAudioTranscription")}
        if !system.isEmpty{fields["systemInstruction"] = .object(["parts":.array([.object(["text":.string(system)])])])}
        return .object(["setup":.object(fields)])
    }
    public static func text(_ text:String)->JSONValue{.object(["clientContent":.object(["turns":.array([.object(["role":.string("user"),"parts":.array([.object(["text":.string(text)])])])]),"turnComplete":.bool(true)])])}
    public static func input(_ bytes:Data)->JSONValue{.object(["realtimeInput":.object(["audio":.object(["mimeType":.string("audio/pcm;rate=16000"),"data":.string(bytes.base64EncodedString())])])])}
    public static func packet(_ raw:JSONValue)->JSONValue {
        if raw["toolCall"] != .null{return raw["toolCall"].setting("type",.string("toolCall"))}
        if raw["toolCallCancellation"] != .null{return raw["toolCallCancellation"].setting("type",.string("toolCallCancellation"))}
        return raw
    }
}

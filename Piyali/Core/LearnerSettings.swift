import Foundation

public struct SettingsChange:Codable,Identifiable,Sendable {
    public var id=UUID()
    public let date:Date
    public let provider:String?
    public let partial:JSONValue
    public init(partial:JSONValue,date:Date=Date(),provider:String?=nil){self.partial=partial;self.date=date;self.provider=provider}
}
public enum LearnerSettings {
    public static let progressKeys:Set<String>=["tutorVoice","tutorVoicePersona","pauseMs","showTranslations","helpRequest","practicePronunciation"]
    public static let rootKeys:Set<String>=["companionUnlocksCelebrated","dailyGoalPetName","dailyGoalPetType","tutorialBitcoinModalShown","identity","createdWallet","themeMode","allowPosts","soundEnabled","soundVolume","tutorVolume","rpgMusicEnabled","rpgMusicPreferenceVersion"]
    public static let directKeys:Set<String>=["companionUnlocksCelebrated","dailyGoalPetName","dailyGoalPetType","tutorialBitcoinModalShown","identity","createdWallet","allowPosts","soundEnabled","soundVolume","tutorVolume","rpgMusicEnabled","rpgMusicPreferenceVersion"]
    public static func sourceUser(_ fields:[String:Any])->JSONValue {
        let p=(fields["progress"] as? [String:Any] ?? [:]).filter{progressKeys.union(["targetLang","supportLang","level","voice","voicePersona"]).contains($0.key)}
        return PhonicsProgress.document(fields.filter{rootKeys.contains($0.key)}.merging(["progress":p]){_,new in new})
    }
    public static func snapshot(_ fields:JSONValue)->JSONValue {
        var root=fields.object.filter{rootKeys.contains($0.key)}
        root["progress"] = .object(fields["progress"].object.filter{progressKeys.contains($0.key)})
        return .object(root)
    }
    public static func applying(_ change:SettingsChange,to original:JSONValue)->JSONValue {
        var data=original
        for (key,value) in change.partial.object {
            if progressKeys.contains(key){data=data.setting("progress",data["progress"].setting(key,value))}
            else if key == "companionUnlocksCelebrated"{var map=data[key].object;for(type,flag)in value.object where CompanionTypes.ordered.contains(type)&&NostrAchievementCollection.truthy(flag){map[type] = .bool(true)};data=data.setting(key,.object(map))}
            else if rootKeys.contains(key){data=data.setting(key,value)}
        }
        return data
    }
    /// The source normalizer reads the latest canonical progress. Only settings
    /// fields are returned, so XP, course counters and unknown values retain their types.
    public static func patch(_ change:SettingsChange,fields:JSONValue,policy:SettingsSourcePolicy)throws->JSONValue {
        var partial=change.partial.object.filter{progressKeys.union(rootKeys).contains($0.key)}
        if let flags=partial["companionUnlocksCelebrated"]{let valid=flags.object.filter{CompanionTypes.ordered.contains($0.key)&&NostrAchievementCollection.truthy($0.value)}.mapValues{_ in JSONValue.bool(true)};if valid.isEmpty{partial.removeValue(forKey:"companionUnlocksCelebrated")}else{partial["companionUnlocksCelebrated"] = .object(valid)}}
        if Set(partial.keys).isSubset(of:directKeys){return .object(partial)}
        let normalized=try policy.run("normalize",.object(["user":fields,"partial":.object(partial),"provider":.string(change.provider == "gemini" ? "gemini":"openai")]))
        var patch: [String:JSONValue] = ["progress":.object(normalized["progress"].object.filter{progressKeys.contains($0.key)}),"themeMode":normalized["themeMode"],"appLanguage":normalized["appLanguage"],"helpRequest":normalized["helpRequest"],"practicePronunciation":normalized["practicePronunciation"]]
        for key in ["companionUnlocksCelebrated","dailyGoalPetName","dailyGoalPetType","tutorialBitcoinModalShown","identity","createdWallet"]{if let value=partial[key]{patch[key]=value}}
        return .object(patch)
    }
}
public extension LearnerState {
    var settingsSnapshot:JSONValue {userSettings ?? .object([:])}
    var tutorPauseMilliseconds:Int {let n=settingsSnapshot["progress"]["pauseMs"].number;return n.isFinite && n>=200 ? Int(min(4000,n)):1200}
    var soundEffectsEnabled:Bool {settingsSnapshot["soundEnabled"] != .bool(false)}
    var automaticPostsEnabled:Bool {settingsSnapshot["allowPosts"] != .bool(false)}
    mutating func changeSettings(_ partial:JSONValue,now:Date=Date(),provider:String?=nil) {
        let known=partial.object.filter{LearnerSettings.progressKeys.union(LearnerSettings.rootKeys).contains($0.key)}
        guard !known.isEmpty else{return}
        let change=SettingsChange(partial:.object(known),date:now,provider:provider)
        userSettings=LearnerSettings.applying(change,to:settingsSnapshot)
        if pendingSettingsChanges == nil{pendingSettingsChanges=[]};pendingSettingsChanges?.append(change)
    }
}

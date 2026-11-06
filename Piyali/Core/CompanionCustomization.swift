import Foundation
import CryptoKit

public enum CompanionCustomization {
    private static let trimSet=CharacterSet(charactersIn:"\u{0009}\u{000A}\u{000B}\u{000C}\u{000D}\u{0020}\u{00A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}\u{FEFF}")
    public static func draft(_ name:String)->String{String(decoding:Array(name.utf16.prefix(24)),as:UTF16.self)}
    public static func name(_ value:String)->String{draft(value.trimmingCharacters(in:trimSet))}
    static func migrationID(partial:JSONValue,date:Date)->UUID{
        let input=JSONValue.array([.string("companion-customization-v1"),partial,.string(WebProgressContract.iso(date))]).canonicalJSON
        let hex=SHA256.hash(data:Data(input.utf8)).map{String(format:"%02x",$0)}.joined(),a=Array(hex.prefix(32));let value=String(a[0..<8])+"-"+String(a[8..<12])+"-"+String(a[12..<16])+"-"+String(a[16..<20])+"-"+String(a[20..<32]);return UUID(uuidString:value)!
    }
    public static func partial(name:String,type:String,level:Int)->JSONValue{.object(["dailyGoalPetName":.string(Self.name(name)),"dailyGoalPetType":.string(CompanionTypes.effective(type,level:level))])}
}
public extension LearnerState {
    mutating func customizeCompanion(name:String,type:String,now:Date=Date()){
        let partial=CompanionCustomization.partial(name:name,type:type,level:companionLevel)
        companionName=partial["dailyGoalPetName"].string;companionType=partial["dailyGoalPetType"].string
        companionCustomizationVersion=1;changeSettings(partial,now:now)
    }
    /// Old snapshots had one pending timestamp for the entire preference form.
    /// Preserve that existing write intent once while moving to partial receipts.
    mutating func migrateCompanionCustomization(){
        guard companionCustomizationVersion != 1 else{return};companionCustomizationVersion=1
        if let date=preferencesModifiedAt,!(pendingSettingsChanges ?? []).contains(where:{$0.partial["dailyGoalPetName"] != .null || $0.partial["dailyGoalPetType"] != .null}){
            customizeCompanion(name:companionName,type:companionType,now:date)
            if var changes=pendingSettingsChanges,let i=changes.indices.last{changes[i].id=CompanionCustomization.migrationID(partial:changes[i].partial,date:date);pendingSettingsChanges=changes}
        }
    }
    mutating func restoreCompanionCustomization(){
        if settingsSnapshot["dailyGoalPetName"] != .null{companionName=settingsSnapshot["dailyGoalPetName"].string}
        if settingsSnapshot["dailyGoalPetType"] != .null{companionType=settingsSnapshot["dailyGoalPetType"].string}
    }
}

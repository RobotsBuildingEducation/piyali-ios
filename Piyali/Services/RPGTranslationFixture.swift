#if DEBUG
import Foundation
@MainActor enum RPGTranslationFixture {
    static func stream(_ prompt:String,update:@escaping @MainActor(String)->Void)async throws->Bool{
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,let mode=e["PIYALI_RPG_TRANSLATION_FIXTURE"],["stream","failure"].contains(mode)else{return false}
        guard let url=Bundle.main.url(forResource:"rpg-dialogue-fixture",withExtension:"json")else{throw URLError(.fileDoesNotExist)}
        let table=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))[prompt.contains("Arabic") ? "ar":"en"],entries=prompt.components(separatedBy:"\nEntries:\n").last?.components(separatedBy:.newlines) ?? []
        let lines=entries.enumerated().map{index,entry in let text=entry.replacingOccurrences(of:"^\\d+\\. ",with:"",options:.regularExpression),translated=table[text].string;return "\(index+1). "+(translated.isEmpty ? text:translated)}
        guard let first=lines.first else{return true};update(first+"\n")
        // A deliberate uncooperative late chunk exercises native scope fencing.
        try? await Task.sleep(for:.seconds(4))
        if mode == "failure"{throw URLError(.networkConnectionLost)}
        update(lines.dropFirst().joined(separator:"\n"));return true
    }
}
#endif

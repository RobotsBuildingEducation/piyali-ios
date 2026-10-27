#if DEBUG
import Foundation

/// Explicit public provider fixtures for real UI journeys; no alternate renderer.
enum RPGPreparationFixture {
    private static var mode:String?{
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,["prepared","cache-only"].contains(e["PIYALI_RPG_PREPARED_FIXTURE"] ?? "")else{return nil}
        return e["PIYALI_RPG_PREPARED_FIXTURE"]
    }
    static func preparedResponse()throws->String?{
        guard let mode else{return nil};guard mode == "prepared"else{throw URLError(.notConnectedToInternet)}
        guard let url=Bundle.main.url(forResource:"rpg-prepared-fixture",withExtension:"json")else{throw URLError(.fileDoesNotExist)};return try String(contentsOf:url,encoding:.utf8)
    }
    static func speechResponse()async throws->String?{
        guard mode != nil else{return nil}
        if let raw=ProcessInfo.processInfo.environment["PIYALI_RPG_SPEECH_DELAY_MS"],let milliseconds=Int(raw),(0...5000).contains(milliseconds){try await Task.sleep(for:.milliseconds(milliseconds))}
        return "```json\n{\"grade\":\"full\",\"reply\":\"¡Gracias por ayudar!\",\"tip\":\"\"}\n```"
    }
}
#endif

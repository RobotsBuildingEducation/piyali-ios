#if DEBUG
import Foundation

/// Explicit public provider fixtures for real UI journeys; no alternate renderer.
enum RPGPreparationFixture {
    @MainActor private static var didFailLibraryLoad=false
    private static var mode:String?{
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,["prepared","cache-only"].contains(e["PIYALI_RPG_PREPARED_FIXTURE"] ?? "")else{return nil}
        return e["PIYALI_RPG_PREPARED_FIXTURE"]
    }
    static var useTutorialPlazaReplies:Bool {
        mode != nil && ProcessInfo.processInfo.environment["PIYALI_LEGACY_TUTORIAL_FIXTURE"] == "1"
    }
    static var useTutorialDialogue:Bool {
        useTutorialPlazaReplies && ProcessInfo.processInfo.environment["PIYALI_LEGACY_TUTORIAL_DIALOGUE"] == "1"
    }
    static func tutorialGeneratedMap()throws->String {
        let width=18,height=14
        var tiles=(0..<height).flatMap { y in
            (0..<width).map { x in x == 0 || x == width-1 || y == 0 || y == height-1 ? 2 : 0 }
        }
        tiles[3*width+5]=3
        tiles[4*width+2]=4
        tiles[2*width+4]=6
        let data=try JSONSerialization.data(withJSONObject:[
            "mapWidth":width,"mapHeight":height,"mapData":tiles,"playerStart":["x":3,"y":3],
            "npcs":[["name":"Ada","tx":4,"ty":4],["name":"Bruno","tx":8,"ty":6]],
        ])
        return String(decoding:data,as:UTF8.self)
    }
    @MainActor private static var tutorialChoiceRequests=0
    @MainActor static func tutorialDialogue(_ prompt:String)async throws->String {
        if prompt.contains("writing branching dialogue") {
            tutorialChoiceRequests+=1
            let request=tutorialChoiceRequests
            try await Task.sleep(for:.milliseconds(request == 1 ? 4400 : 900))
            if request == 1 { return "{}" }
            return """
            [{"text":"Hola, quiero presentarme.","reply":"(Sonríe.) Claro, adelante."},
            {"text":"¿Podemos practicar?","reply":"Sí, dime tu nombre."},
            {"text":"Buenas tardes.","reply":"Buenas tardes. ¿Qué tal?"}]
            """
        }
        if prompt.contains("walking up to") {
            guard prompt.contains("Player: Hola, quiero presentarme."),prompt.contains("Claro, adelante.") else { return "" }
            return "Vengo a practicar mi presentación."
        }
        if prompt.contains("The player arrives and says:") {
            guard prompt.contains("Vengo a practicar mi presentación.") else { return "" }
            return "¡Bienvenida! Dime cómo te llamas."
        }
        if prompt.contains("<<<PLAYER_DIALOGUE>>>") {
            guard prompt.contains("Me llamo Sol."),prompt.contains("¡Bienvenida! Dime cómo te llamas.") else { return "" }
            return "Mucho gusto, Sol. Me alegra conocerte."
        }
        return ""
    }
    static func preparedResponse()async throws->String?{
        guard let mode else{return nil};guard mode == "prepared"else{throw URLError(.notConnectedToInternet)}
        if let ms=Int(ProcessInfo.processInfo.environment["PIYALI_RPG_PREPARED_DELAY_MS"] ?? ""),(0...15000).contains(ms){try await Task.sleep(for:.milliseconds(ms))}
        guard let url=Bundle.main.url(forResource:"rpg-prepared-fixture",withExtension:"json")else{throw URLError(.fileDoesNotExist)};return try String(contentsOf:url,encoding:.utf8)
    }
    static func speechResponse()async throws->String?{
        guard mode != nil else{return nil}
        if let raw=ProcessInfo.processInfo.environment["PIYALI_RPG_SPEECH_DELAY_MS"],let milliseconds=Int(raw),(0...5000).contains(milliseconds){try await Task.sleep(for:.milliseconds(milliseconds))}
        return "```json\n{\"grade\":\"full\",\"reply\":\"¡Gracias por ayudar!\",\"tip\":\"\"}\n```"
    }
    @MainActor static func checkLibraryLoad()throws {
        guard mode != nil,ProcessInfo.processInfo.environment["PIYALI_RPG_FAIL_FIRST_LIBRARY_LOAD"] == "1",!didFailLibraryLoad else{return}
        didFailLibraryLoad=true
        throw CocoaError(.fileReadNoSuchFile)
    }
}
#endif

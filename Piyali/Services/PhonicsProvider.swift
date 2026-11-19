import Foundation

@MainActor struct PhonicsProvider {
    var judge:(String)async throws->String
    var quote:(JSONValue,LearnerState)async throws->JSONValue
    static func native(_ ai:AIService)->Self {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        if env["PIYALI_OFFLINE_TESTS"] == "1",env["PIYALI_LIVE_API_TESTS"] != "1",env["PIYALI_PHONICS_FIXTURE"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil {
            return .init(judge:{prompt in try await Task.sleep(for:.milliseconds(150));if prompt.contains("optional continuation deck"){let units=["gato","perro","luna","sol","mesa","libro"].enumerated().map{index,word in ["grapheme":String(word.prefix(1)),"exampleWord":word,"sound":"A clear sound", "tip":"Say it clearly", "meaning":"Meaning \(index)"]};return String(decoding:try JSONEncoder().encode(units),as:UTF8.self)};return prompt.contains("WRONG_FIXTURE") ? "NO":"YES | 2"},quote:{card,state in try GeneratedQuestionWorth.fallback(level:card["cefrLevel"].string,learner:state,recipes:PracticeRecipes())})
        }
        #endif
        return .init(judge:{try await ai.responsesText($0)},quote:{card,state in try await GeneratedQuestionWorth.assess(question:.object(["letter":card["letter"],"phoneme":card["phoneme"],"practiceWord":card["practiceWord"],"task":.string("Pronounce the practice word")]),level:card["cefrLevel"].string,mode:"phonics",learner:state,recipes:PracticeRecipes(),ai:ai)})
    }
}

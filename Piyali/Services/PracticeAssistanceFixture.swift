#if DEBUG
import Foundation
@MainActor enum PracticeAssistanceFixture {
    static func write(_ prompt:String,update:@escaping @MainActor(String)->Void)async throws->String? {
        let e=ProcessInfo.processInfo.environment
        guard e["PIYALI_OFFLINE_TESTS"] == "1",e["PIYALI_LIVE_API_TESTS"] != "1",UUID(uuidString:e["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil,e["PIYALI_QUESTION_HELP_FIXTURE"] == "stream" else{return nil}
        if prompt.contains("A student tried to translate"){try await Task.sleep(for:.milliseconds(200));return "Say **Hola** to greet someone."}
        if prompt.contains("A student answered an exercise incorrectly") {try await Task.sleep(for:.milliseconds(200));return "Use **soy** with **yo**. Say **Yo soy Ana.**"}
        update("Use **Sounds weird**.");try await Task.sleep(for:.milliseconds(2500));let text="Use **Sounds weird**. The correct sentence is **Yo soy Ana.**";update(text);return text
    }
}
#endif

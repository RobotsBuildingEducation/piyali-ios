import XCTest
@testable import PiyaliCore

final class MemorySourcePolicyTests:XCTestCase {
    @MainActor func testOriginalMemoryCopyPromptsParsersLanguageGuardsAndJourneyRules()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/memory-policy.json.gz")),policy=try MemorySourcePolicy(source:root.appendingPathComponent("Piyali/Resources/memory-policy.js"))
        XCTAssertEqual(rows.count,55)
        for row in rows{XCTAssertEqual(try policy.inspect(row["operation"].string,row["input"]),row["expected"],row["operation"].string+row["input"]["language"].string)}
    }
    func testLocalizationPreservesLifecycleAndForeignFieldsAndRejectsStaleCapture()throws {
        let now=Date();var note=MemoryContract.capture(target:"es",support:"en",level:"A1",mode:"grammar",concept:"hola",answer:"ola",expected:"hola",feedback:"Missing h",now:now);note.fields["webOwned"] = .string("keep");note.fields["status"] = .string("reinforced");note.fields["severity"] = .number(3)
        var state=LearnerState();state.companionMemory=["es":[note]];state.localizeMemory(note,fields:.object(["mistake":.string("Falta h"),"tip":.string("Recuerda la h")]),support:"es",now:now)
        let saved=try XCTUnwrap(state.companionMemory?["es"]?.first);XCTAssertEqual(saved.text("status"),"reinforced");XCTAssertEqual(saved.severity,3);XCTAssertEqual(saved.text("webOwned"),"keep");XCTAssertEqual(saved.text("supportLang"),"es");XCTAssertEqual(saved.text("tip"),"Recuerda la h")
        var newer=note;newer.fields["createdAt"] = .number((now.timeIntervalSince1970+1)*1000);state.companionMemory=["es":[newer]];state.localizeMemory(note,fields:.object(["tip":.string("stale")]),support:"fr",now:now);XCTAssertEqual(state.companionMemory?["es"]?.first?.text("supportLang"),"en")
    }
}

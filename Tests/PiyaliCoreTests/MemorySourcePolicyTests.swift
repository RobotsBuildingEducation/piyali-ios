import XCTest
@testable import PiyaliCore

final class MemorySourcePolicyTests:XCTestCase {
    @MainActor func testOriginalMemoryCopyPromptsParsersLanguageGuardsAndJourneyRules()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/memory-policy.json.gz")),policy=try MemorySourcePolicy(source:root.appendingPathComponent("Piyali/Resources/memory-policy.js"))
        XCTAssertEqual(rows.count,267)
        for row in rows{var actual=try policy.inspect(row["operation"].string,row["input"]);if row["operation"].string == "captureNote"{var fields=actual["value"].object;fields.removeValue(forKey:"id");actual=actual.setting("value",.object(fields))};XCTAssertEqual(actual,row["expected"],row["operation"].string+row["input"]["language"].string)}
    }
    func testLocalizationPreservesLifecycleAndForeignFieldsAndRejectsStaleCapture()throws {
        let now=Date();var note=MemoryContract.capture(target:"es",support:"en",level:"A1",mode:"grammar",concept:"hola",answer:"ola",expected:"hola",feedback:"Missing h",now:now);note.fields["webOwned"] = .string("keep");note.fields["status"] = .string("reinforced");note.fields["severity"] = .number(3)
        var state=LearnerState();state.companionMemory=["es":[note]];state.localizeMemory(note,fields:.object(["mistake":.string("Falta h"),"tip":.string("Recuerda la h")]),support:"es",now:now)
        let saved=try XCTUnwrap(state.companionMemory?["es"]?.first);XCTAssertEqual(saved.text("status"),"reinforced");XCTAssertEqual(saved.severity,3);XCTAssertEqual(saved.text("webOwned"),"keep");XCTAssertEqual(saved.text("supportLang"),"es");XCTAssertEqual(saved.text("tip"),"Recuerda la h")
        var newer=note;newer.fields["createdAt"] = .number((now.timeIntervalSince1970+1)*1000);state.companionMemory=["es":[newer]];state.localizeMemory(note,fields:.object(["tip":.string("stale")]),support:"fr",now:now);XCTAssertEqual(state.companionMemory?["es"]?.first?.text("supportLang"),"en")
    }
}

extension MemorySourcePolicyTests {
    @MainActor func testRepeatedSourceTutorCaptureKeepsFirstCorrectionAndLocalizesPendingSummary()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try MemorySourcePolicy(source:root.appendingPathComponent("Piyali/Resources/memory-policy.js")),now=Date()
        func note(_ support:String,_ answer:String,_ expected:String,_ at:Date)throws->MemoryNote {
            MemoryNote(fields:try policy.value("captureNote",.object(["targetLang":.string("es"),"supportLang":.string(support),"sourceMode":.string("tutor"),"sourceContext":.string("tutor"),"concept":.string("hola"),"userAnswer":.string(answer),"expectedAnswer":.string(expected),"now":.string(WebProgressContract.iso(at))])).object)
        }
        var state=LearnerState();let initial=try XCTUnwrap(state.captureMemory(try note("en","first attempt","HOLA",now),now:now))
        state.localizeMemory(initial,fields:.object(["mistake":.string("Old diagnosis"),"correction":.string("HOLA"),"tip":.string("Old tip")]),support:"en",now:now)
        state.reinforceMemory(id:initial.id,now:now);state.companionMemory?["es"]?[0].fields["foreignField"] = .string("keep")
        state.support="es";let repeated=try XCTUnwrap(state.captureMemory(try note("es","","new correction",now.addingTimeInterval(1)),now:now.addingTimeInterval(1)))
        XCTAssertEqual(repeated.id,initial.id);XCTAssertEqual(repeated.severity,2);XCTAssertEqual(repeated.text("expectedAnswer"),"HOLA");XCTAssertEqual(repeated.text("correction"),"HOLA");XCTAssertEqual(repeated.text("userAnswer"),"first attempt");XCTAssertEqual(repeated.text("companionSummary"),"Guardado para mañana: hola");XCTAssertEqual(repeated.text("supportLang"),"es");XCTAssertTrue(repeated.text("mistake").isEmpty);XCTAssertTrue(repeated.text("tip").isEmpty);XCTAssertEqual(repeated.fields["enriched"],.bool(false));XCTAssertEqual(repeated.text("status"),"reinforced");XCTAssertEqual(repeated.text("foreignField"),"keep");XCTAssertEqual(state.totalXP,0);XCTAssertNil(state.gradedByLanguage)
    }
}


extension MemorySourcePolicyTests {
    @MainActor func testNativeDuplicateMergeMatchesCompleteOriginalCaptureCases()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/memory-policy.json.gz")),policy=try MemorySourcePolicy(source:root.appendingPathComponent("Piyali/Resources/memory-policy.js"))
        let captures=rows.filter{$0["operation"].string == "capturePlan"};XCTAssertEqual(captures.count,203)
        for row in captures {
            let p=row["input"],date=Date(timeIntervalSince1970:p["now"].number/1000),original=p["notes"].array.map{MemoryNote(fields:$0.object)},fields=try policy.value("captureNote",p),note=MemoryNote(fields:fields.object)
            let change=MemoryChange(action:.capture,target:"es",date:date,dayKey:CalendarDay.key(date),note:note,captureConcept:p["concept"].string),actual=MemoryContract.applying(change,to:original,today:CalendarDay.key(date)),expected=row["expected"]["value"]
            XCTAssertEqual(actual.map{JSONValue.object($0.fields)},expected == .null ? p["notes"].array:expected["notes"].array,p.canonicalJSON)
            let built=MemoryContract.capture(target:"es",support:p["supportLang"].string,level:"C1",mode:p["sourceMode"].string,concept:p["concept"].string,answer:p["userAnswer"].string,expected:p["expectedAnswer"].string,feedback:"",context:p["sourceContext"].string,now:date)
            for key in ["concept","supportLang","companionSummary"] {XCTAssertEqual(built.fields[key],fields[key],key+" "+p["supportLang"].string)}
        }
    }
    func testFullCaptureConceptSurvivesPrivateSerializationAndOldChangesStillDecode()throws {
        let now=Date(),concept=String(repeating:"x",count:241),note=MemoryContract.capture(target:"es",support:"en",level:"A1",mode:"tutor",concept:concept,answer:"first",expected:"first correction",feedback:"",now:now)
        var state=LearnerState();_ = state.captureMemory(note,concept:concept,now:now)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.pendingMemoryChanges?.first?.captureConcept,concept)
        var next=restored;var later=note;later.fields["id"] = .string("different-public-id");later.fields["createdAt"] = .number(now.addingTimeInterval(1).timeIntervalSince1970*1000);_ = next.captureMemory(later,concept:concept,now:now.addingTimeInterval(1));XCTAssertEqual(next.companionMemory?["es"]?.count,2)
        let encoded=try JSONEncoder().encode(try XCTUnwrap(state.pendingMemoryChanges?.first));var raw=try XCTUnwrap(JSONSerialization.jsonObject(with:encoded) as? [String:Any]);raw.removeValue(forKey:"captureConcept");let legacy=try JSONDecoder().decode(MemoryChange.self,from:JSONSerialization.data(withJSONObject:raw));XCTAssertNil(legacy.captureConcept);XCTAssertEqual(legacy.note.id,note.id)
    }
}

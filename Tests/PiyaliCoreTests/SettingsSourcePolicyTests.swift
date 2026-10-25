import XCTest
@testable import PiyaliCore

final class SettingsSourcePolicyTests:XCTestCase {
    private var root:URL{URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()}
    private func policy()throws->SettingsSourcePolicy {try SettingsSourcePolicy(url:root.appendingPathComponent("Piyali/Resources/settings-policy.js"))}
    func testOriginalSettingsNormalizerVoiceProfilesPersonasAndPreviewRequests()throws {
        let rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/settings-policy.json.gz")),p=try policy();XCTAssertEqual(rows.count,274)
        for row in rows{XCTAssertEqual(try p.run(row["operation"].string,row["input"]),row["expected"],row["operation"].string+" "+row["input"].canonicalJSON)}
    }
    func testSettingsPatchRetainsForeignProgressAndProviderVoiceOnUnrelatedSave()throws {
        let p=try policy(),fields:JSONValue = .object(["themeMode":.string("dark"),"patreonVerified":.bool(true),"progress":.object(["targetLang":.string("fr"),"supportLang":.string("es"),"tutorVoice":.string("Aoede"),"xp":.number(75),"foreign":.object(["keep":.bool(true)])])])
        let patch=try LearnerSettings.patch(.init(partial:.object(["pauseMs":.number(255)])),fields:fields,policy:p)
        XCTAssertEqual(patch["progress"]["pauseMs"],.number(300));XCTAssertEqual(patch["progress"]["tutorVoice"],.string("Aoede"));XCTAssertEqual(patch["themeMode"],.string("dark"));XCTAssertEqual(patch["appLanguage"],.string("es"));XCTAssertEqual(patch["progress"]["xp"],.null);XCTAssertEqual(patch["progress"]["foreign"],.null);XCTAssertEqual(patch["patreonVerified"],.null)
        let voice=try LearnerSettings.patch(.init(partial:.object(["tutorVoice":.string("ash")])),fields:fields,policy:p);XCTAssertEqual(voice["progress"]["tutorVoice"],.string("cedar"))
        let direct=try LearnerSettings.patch(.init(partial:.object(["soundEnabled":.bool(false)])),fields:fields,policy:p);XCTAssertEqual(direct,.object(["soundEnabled":.bool(false)]))
    }
    func testSettingsImportAndAcknowledgmentRetainNewerLocalEditsWithoutXP()throws {
        var current=LearnerState();current.changeSettings(.object(["tutorVoice":.string("cedar")]));let sent=current,id=try XCTUnwrap(sent.pendingSettingsChanges?.first?.id)
        current.changeSettings(.object(["pauseMs":.number(800)]))
        let cloud=WebProgressContract.imported(["progress":["tutorVoice":"cedar","pauseMs":1200],"soundEnabled":false,"iosRecentEventIDs":[id.uuidString]],native:sent)
        let final=LearnerState.rebased(current:current,sent:sent,acknowledged:cloud)
        XCTAssertEqual(final.pendingSettingsChanges?.count,1);XCTAssertEqual(final.settingsSnapshot["progress"]["pauseMs"],.number(800));XCTAssertEqual(final.settingsSnapshot["progress"]["tutorVoice"],.string("cedar"));XCTAssertFalse(final.soundEffectsEnabled);XCTAssertEqual(final.totalXP,0)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(final));XCTAssertEqual(restored.pendingSettingsChanges?.count,1)
    }
    func testOfflineGeminiVoiceKeepsItsProviderThroughEncodingAndLegacyEntriesRemainReadable()throws {
        let p=try policy(),fields:JSONValue = .object(["progress":.object(["targetLang":.string("es"),"supportLang":.string("en")])])
        let change=SettingsChange(partial:.object(["tutorVoice":.string("Charon")]),provider:"gemini"),restored=try JSONDecoder().decode(SettingsChange.self,from:JSONEncoder().encode(change))
        XCTAssertEqual(restored.provider,"gemini");XCTAssertEqual(try LearnerSettings.patch(restored,fields:fields,policy:p)["progress"]["tutorVoice"],.string("Charon"))
        var raw=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(change)) as? [String:Any]);raw.removeValue(forKey:"provider");let legacyData=try JSONSerialization.data(withJSONObject:raw)
        let legacy=try JSONDecoder().decode(SettingsChange.self,from:legacyData)
        XCTAssertNil(legacy.provider);XCTAssertEqual(try LearnerSettings.patch(legacy,fields:fields,policy:p)["progress"]["tutorVoice"],.string("marin"))
    }

}

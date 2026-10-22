import XCTest
@testable import PiyaliCore

final class StoryTests:XCTestCase {
    private func fixtures() throws -> JSONValue { try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/stories.json"))) }
    func testReferenceEpisodeValidationIncludingInvalidAndWrongLanguageStories() throws {
        let cases=try fixtures()["cases"].array;XCTAssertEqual(cases.count,28)
        for item in cases {
            if item["valid"].boolean { XCTAssertNoThrow(try StoryEpisode.parse(item["raw"],target:item["target"].string,prepare:item["prepare"].boolean),item.json) }
            else { XCTAssertThrowsError(try StoryEpisode.parse(item["raw"],target:item["target"].string,prepare:item["prepare"].boolean),item.json) }
        }
    }
    func testReferenceCheckpointAnswersTreatSelectionAsSetsAndOrderingAsSequence() throws {
        let cases=try fixtures()["answers"].array;XCTAssertEqual(cases.count,16)
        for item in cases {
            let question=try JSONDecoder().decode(StoryQuestion.self,from:JSONEncoder().encode(item["question"]))
            XCTAssertEqual(question.correct(item["selected"].array.map { Int($0.number) }),item["correct"].boolean)
        }
    }
    func testTilesKeepFullDialogueAndMergeDuplicateButtonsAcrossScripts() throws {
        for item in try fixtures()["tiles"].array {
            let tiles=StoryEpisode.tiles(item["text"].string)
            XCTAssertTrue((2...6).contains(tiles.options.count),item.json)
            XCTAssertEqual(Set(tiles.options.map(StoryEpisode.normalize)).count,tiles.options.count)
            XCTAssertTrue(StoryEpisode.matches(tiles.answer.map { tiles.options[$0] }.joined(separator:" "),item["text"].string),item.json)
            XCTAssertTrue(StoryEpisode.matches(tiles.answer.map { tiles.options[$0] }.joined(separator:" "),item["canonical"].string),item.json)
            XCTAssertNotEqual(tiles.answer,Array(tiles.options.indices))
        }
    }
    func testSourceAutomaticModeRotationRespectsTutorialAndExplicitPins() throws {
        for item in try fixtures()["modes"].array {
            XCTAssertEqual(StoryMode.choose(content:item["content"],random:item["random"].number).rawValue,item["selected"].string)
            XCTAssertEqual(StoryMode.speaking.next(content:item["content"],random:item["random"].number).rawValue,item["rotated"].string)
        }
    }
    func testSourceSpeechEvaluationAcrossSevenLanguagesAndRecognitionConfidence() throws {
        let cases=try fixtures()["speech"].array;XCTAssertEqual(cases.count,252)
        for item in cases {
            let input=item["input"],expected=item["expected"],result=StorySpeech.evaluate(recognized:input["recognizedText"].string,target:input["targetSentence"].string,lang:input["lang"].string,confidence:input["confidence"].number)
            XCTAssertEqual(result.pass,expected["pass"].boolean,input.json);XCTAssertEqual(result.score,Int(expected["score"].number),input.json)
            XCTAssertEqual(result.reasons,expected["reasons"].array.map(\.string),input.json)
            XCTAssertEqual(result.charSim,expected["charSim"].number,accuracy:1e-10);XCTAssertEqual(result.f1,expected["f1"].number,accuracy:1e-10)
        }
    }
    func testSpeechQualityAndNonLatinScriptsUseActualLanguageRatherThanLatinOnlyDetection() {
        for (language,text) in [("ar","هذا البيت جميل"),("el","Το σπίτι είναι όμορφο"),("hi","यह घर अच्छा है"),("ja","今日は母の誕生日です"),("ru","Этот дом красивый"),("zh","今天是她的生日")] {
            XCTAssertTrue(StorySpeech.evaluate(recognized:text,target:text,lang:language,confidence:0.9).pass,language)
            XCTAssertFalse(StorySpeech.evaluate(recognized:"These are English words",target:text,lang:language,confidence:0.9).pass)
        }
        let noisy=StorySpeech.evaluate(recognized:"Tengo flores rojas",target:"Tengo flores rojas",lang:"es",confidence:0.9,audio:.init(duration:0.1,rms:0,zeroCrossings:0))
        XCTAssertFalse(noisy.pass);XCTAssertTrue(noisy.reasons.contains("speech-quality"))
    }
    func testNativeCharacterIdentityAndPortraitPoolsMatchExecutedSource() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),appearance=StoryAppearance(try ContentLibrary.decode(JSONValue.self,url:root.appendingPathComponent("Piyali/Resources/story-ui.json.gz")))
        let cases=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/story-appearance.json.gz"))
        for sample in cases { XCTAssertEqual(StoryAppearance.isUser(sample["name"].string,learnerName:"Alicia"),sample["isUser"].boolean,sample["name"].string);XCTAssertEqual(appearance.portraitPool(sample["name"].string,learnerName:"Alicia"),sample["pool"].array.map(\.string),sample["name"].string) }
        XCTAssertEqual(appearance.portraitFile("33"),"story-portrait-33.webp");XCTAssertEqual(appearance.portraitFile("invalid"),appearance.portraitFile("35"))
    }
    func testCheckpointNeedsTheCompleteBoundedSelectionBeforeOneGrade() throws {
        var run=try episodeRun();run.heard.insert(0);run.select(1);XCTAssertFalse(run.readyToCheck);run.check();XCTAssertNil(run.result)
        run.select(2);XCTAssertTrue(run.readyToCheck);run.select(3);XCTAssertEqual(run.answers["0"],[1,2]);run.check();XCTAssertEqual(run.result,true)
        run.select(0);run.check();XCTAssertEqual(run.answers["0"],[1,2]);XCTAssertEqual(run.result,true)
    }
    func testStoryContextIsStableAcrossDictionaryOrderAndSnapshotRoundTrips() throws {
        let first:JSONValue = .object(["topic":.string("family"),"focus":.object(["a":.string("mamá"),"b":.string("papá")])]),second:JSONValue = .object(["focus":.object(["b":.string("papá"),"a":.string("mamá")]),"topic":.string("family")])
        let data=try StoryRun.contextData(content:first,agenda:.object(["x":.number(1),"y":.number(2)]),level:"A1")
        XCTAssertEqual(data,try StoryRun.contextData(content:second,agenda:.object(["y":.number(2),"x":.number(1)]),level:"A1"))
        let restored=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(second));XCTAssertEqual(data,try StoryRun.contextData(content:restored,agenda:.object(["x":.number(1),"y":.number(2)]),level:"A1"))
        XCTAssertNotEqual(data,try StoryRun.contextData(content:second.setting("topic",.string("a new topic")),agenda:.object(["x":.number(1),"y":.number(2)]),level:"A1"))
    }
    private func episodeRun() throws -> StoryRun {
        try StoryRun(payload:try fixtures()["cases"].array[0]["raw"],mode:.radio,target:"es",support:"en",level:"A1",lessonID:"unit-story",worth:.null)
    }
    func testComprehensionRequiresAllCheckpointsAndAwardsSixOnceEvenAfterMisses() throws {
        var state=LearnerState();state.saveStory(try episodeRun())
        XCTAssertEqual(state.finishStory(),0)
        while var run=state.story,!run.atEnd {
            XCTAssertNil(run.result);run.select(0);run.check();XCTAssertNil(run.result,"Listening or reading comes before grading")
            run.heard.insert(run.index);if let q=run.currentSegment?.question,q.answer.count > 1 { for i in 1..<q.answer.count { run.select(i) } };run.check();XCTAssertNotNil(run.result);run.advance();state.saveStory(run)
        }
        XCTAssertEqual(state.finishStory(),6);XCTAssertEqual(state.finishStory(),0);XCTAssertEqual(state.totalXP,6)
        XCTAssertNil(state.gradedByLanguage?["es"]);XCTAssertTrue(state.practicedModes.contains(state.modeKey("unit-story","Stories")))
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertTrue(restored.story!.completed);XCTAssertEqual(restored.story?.earnedXP,6)
        XCTAssertEqual(state.pendingChanges?.filter { $0.source == .storyCompletion }.count,1)
    }
    func testSpeakingLineHasOneTwoXPRewardQuotedScoreAndZeroXPForMissOrFinalization() throws {
        let raw=try fixtures()["cases"].array[0]["raw"],lines=raw["segments"].array.flatMap { $0["turns"].array }
        let run=try StoryRun(payload:.object(["title":raw["title"],"sentences":.array(lines+lines)]),mode:.speaking,target:"es",support:"en",level:"A1",lessonID:nil,worth:ConversationPractice.worth(rating:800,level:"A1"))
        var state=LearnerState();state.saveStory(run)
        XCTAssertEqual(state.practiceStoryLine(words:"wrong phrase",typed:true),0);XCTAssertNil(state.gradedByLanguage?["es"]);XCTAssertEqual(state.activeMemories.count,1)
        var retry=state.story!;retry.speechResult=nil;state.saveStory(retry)
        XCTAssertEqual(state.practiceStoryLine(words:run.sentences[0].target,typed:true),2)
        XCTAssertEqual(state.practiceStoryLine(words:run.sentences[0].target,typed:true),0);XCTAssertEqual(state.totalXP,2);XCTAssertEqual(state.gradedByLanguage?["es"],1)
        let change=try XCTUnwrap(state.pendingChanges?.first { $0.source == .storyTurn });XCTAssertEqual(change.contentID,run.contentID("line-0"));XCTAssertEqual(change.storyProof?["method"],.string("typed"))
        var finishing=state.story!;while !finishing.atEnd { finishing.advance() };state.saveStory(finishing)
        XCTAssertEqual(state.finishStory(),0);XCTAssertTrue(state.story!.completed);XCTAssertEqual(state.totalXP,2)
        let patch=WebProgressContract.rootPatch(fields:[:],month:[:],change:change)
        let intelligence=JSONValue.foundation(patch.root["learningIntelligence"] ?? [:]);XCTAssertEqual(intelligence["es"]["performanceSummary"]["lastMode"],.string("story"))
    }
    func testStoryDraftsAreLanguageScopedBoundedAndSurviveInFlightSync() throws {
        let sent=LearnerState();var current=sent;current.saveStory(try episodeRun());var advanced=current.story!;advanced.heard.insert(0);advanced.select(1);current.saveStory(advanced)
        let merged=LearnerState.rebased(current:current,sent:sent,acknowledged:sent);XCTAssertEqual(merged.story?.answers["0"],[1])
        var switched=current;switched.target="fr";XCTAssertNil(switched.story);switched.target="es";XCTAssertEqual(switched.story?.id,current.story?.id)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(current));XCTAssertEqual(restored.story?.id,current.story?.id)
    }
}

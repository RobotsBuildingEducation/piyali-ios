import XCTest
@testable import PiyaliCore

@MainActor final class StoryGenerationTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private func recipes()throws->PracticeRecipes { try .init(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js")) }
    func testPreparationAndBatchQuotesMatchExecutedOriginalSource()throws {
        struct Fixture:Decodable { let operation:String;let parameters:JSONValue;let expected:JSONValue }
        let samples=try ContentLibrary.decode([Fixture].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/story-policies.json.gz")),engine=try recipes()
        XCTAssertEqual(samples.count,96)
        for sample in samples { XCTAssertEqual(try engine.story(sample.operation,parameters:sample.parameters),sample.expected,sample.operation) }
    }
    func testActualFamilyAndAdvancedTutorialKeepAuthoredScopeInOriginalPreparation()throws {
        let engine=try recipes(),library=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-es.json.gz")),unit=try XCTUnwrap(library["Pre-A1"]?.first),lesson=try XCTUnwrap(unit.lessons.first { $0.content["stories"] != .null })
        var state=LearnerState();state.target="es";state.support="en";state.goal="Unrelated free practice"
        let parameters=try StoryGeneration.parameters(state:state,lesson:lesson,unit:unit,mode:.speaking,account:"fixture",level:"A1",user:.object([:]),recipes:engine)
        XCTAssertEqual(parameters["lessonContent"]["curriculumContext"]["lessonId"].string,lesson.id)
        XCTAssertEqual(parameters["lessonContent"]["topic"],lesson.content["stories"]["topic"])
        let prepared=try engine.story("prepareSpeak",parameters:parameters)
        XCTAssertTrue(prepared["prompt"].string.contains("Identify extended family members"));XCTAssertFalse(prepared["prompt"].string.contains("Unrelated free practice"));XCTAssertEqual(prepared["metadata"]["storyPlan"]["lessonId"].string,lesson.id)
        let integrated=try XCTUnwrap(unit.lessons.first { $0.id.contains("integrated-practice") })
        let integratedParameters=try StoryGeneration.parameters(state:state,lesson:integrated,unit:unit,mode:.speaking,account:"fixture",level:"A1",user:.object([:]),recipes:engine)
        let integratedPrepared=try engine.story("prepareSpeak",parameters:integratedParameters)
        XCTAssertTrue(integratedPrepared["prompt"].string.contains("mamá"));XCTAssertTrue(integratedPrepared["prompt"].string.contains("People & Family"))
        let intro=try ContentLibrary.decode(IntroLibrary.self,url:root.appendingPathComponent("Piyali/Resources/intro-es.json.gz")),advanced=try XCTUnwrap(intro.units["B2"]?.lessons.first)
        let advancedParameters=try StoryGeneration.parameters(state:state,lesson:advanced,unit:intro.units["B2"],mode:.speaking,account:"fixture",level:"B2",user:.object([:]),recipes:engine)
        XCTAssertEqual(advancedParameters["lessonContent"]["tutorialPracticeLevel"].string,"B2")
        let advancedPrepared=try engine.story("prepareSpeak",parameters:advancedParameters)
        XCTAssertTrue(advancedPrepared["metadata"]["storyPlan"]["isTutorial"].boolean);XCTAssertTrue(advancedPrepared["prompt"].string.contains("2–3 dialogue lines total, with natural CEFR B2"))
    }
    func testSpeakingProtocolRequiresOfficialCastCompleteCountsAndDone()throws {
        let engine=try recipes()
        func raw(_ names:[String]=["Sheilfer","You"],count:Int=2,done:Bool=true)->String {
            let lines=(0..<count).map { JSONValue.object(["type":.string("sentence"),"character":.string(names[$0%names.count]),"gender":.string("female"),"tgt":.string($0%2 == 0 ? "Hola, buenos días." : "Hola, mucho gusto.")]) }
            return (lines+(done ? [.object(["type":.string("done")])] : [])).map(\.json).joined(separator:"\n")
        }
        let payload=try StoryGeneration.payload(raw(),mode:.speaking,target:"es",tutorial:true,title:"Welcome",recipes:engine)
        let run=try StoryRun(payload:payload,mode:.speaking,target:"es",support:"en",level:"Pre-A1",lessonID:nil,worth:.null,tutorial:true)
        XCTAssertEqual(run.sentences.map(\.speaker),["Sheilfer","You"]);XCTAssertEqual(run.sentences[0].gender,"female");XCTAssertEqual(run.sentences[0].support,"")
        XCTAssertThrowsError(try StoryGeneration.payload(raw(["Ana","Luis"]),mode:.speaking,target:"es",tutorial:true,title:"Welcome",recipes:engine))
        XCTAssertThrowsError(try StoryGeneration.payload(raw(done:false),mode:.speaking,target:"es",tutorial:true,title:"Welcome",recipes:engine))
        XCTAssertThrowsError(try StoryGeneration.payload(raw(count:1),mode:.speaking,target:"es",tutorial:true,title:"Welcome",recipes:engine))
        XCTAssertThrowsError(try StoryGeneration.payload(raw(),mode:.speaking,target:"es",tutorial:false,title:"Welcome",recipes:engine))
        XCTAssertNoThrow(try StoryGeneration.payload(raw(count:8),mode:.speaking,target:"es",tutorial:false,title:"Welcome",recipes:engine))
    }
    func testSessionProtocolRejectsMissingDoneAndUnsafeSegmentAndPreservesTiles()throws {
        let engine=try recipes(),episode=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/stories.json")))["cases"].array[0]["raw"]
        var records:[JSONValue]=[.object(["type":.string("title"),"title":episode["title"]])]
        for (index,segment) in episode["segments"].array.enumerated() {
            records += segment["turns"].array.map { $0.setting("type",.string("turn")).setting("segment",.number(Double(index))) }
            records.append(.object(["type":.string("question"),"segment":.number(Double(index)),"question":segment["question"]]))
        }
        let partial=records.map(\.json).joined(separator:"\n")
        XCTAssertThrowsError(try StoryGeneration.payload(partial,mode:.radio,target:"es",tutorial:false,title:"",recipes:engine))
        records.append(.object(["type":.string("done")]))
        let payload=try StoryGeneration.payload(records.map(\.json).joined(separator:"\n"),mode:.radio,target:"es",tutorial:false,title:"",recipes:engine)
        let run=try StoryRun(payload:payload,mode:.radio,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null)
        XCTAssertEqual(run.count,2);XCTAssertEqual(run.episode?.segments[1].question.answer.count,3)
        XCTAssertThrowsError(try StoryGeneration.payload(#"{"type":"turn","segment":99999999,"target":"Hola"}"#+"\n"+#"{"type":"done"}"#,mode:.radio,target:"es",tutorial:false,title:"",recipes:engine))
    }
    func testEachSavedLineUsesItsOwnGeneratedQuoteAfterRatingChangesAndRelaunch()throws {
        let engine=try recipes(),user:JSONValue = .object(["learningIntelligence":.object(["es":.object(["elo":.object(["rating":.number(800),"scaleVersion":.number(4)])])])])
        let questions=(0..<2).map { _ in JSONValue.object(["sentence":.string("Hola."),"task":.string("Understand and pronounce this sentence")]) }
        let quotes=try engine.story("batchWorth",parameters:.object(["user":user,"targetLang":.string("es"),"questionLevel":.string("A1"),"questions":.array(questions),"raw":.string(#"{"difficultyScores":[0,100]}"#)])).array
        XCTAssertEqual(quotes.count,2);XCTAssertNotEqual(quotes[0],quotes[1]);XCTAssertEqual(quotes[1]["difficultySource"].string,"model_assessment")
        let payload:JSONValue = .object(["title":.string("Welcome"),"sentences":.array([.object(["speaker":.string("Sheilfer"),"target":.string("Hola.")]),.object(["speaker":.string("You"),"target":.string("Buenos días.")])])])
        var run=try StoryRun(payload:payload,mode:.speaking,target:"es",support:"en",level:"A1",lessonID:nil,worth:.null,tutorial:true);run.sentenceWorths=quotes
        var state=LearnerState();state.saveStory(run)
        XCTAssertEqual(state.practiceStoryLine(words:"Hola.",confidence:0.9),2);XCTAssertEqual(state.pendingChanges?.last?.conversationWorth,quotes[0])
        var current=state.story!;current.advance();state.saveStory(current)
        state=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(state.story?.currentSentenceWorth,quotes[1]);XCTAssertEqual(state.practiceStoryLine(words:"Buenos días.",confidence:0.9),2)
        XCTAssertEqual(state.pendingChanges?.last?.conversationWorth,quotes[1]);XCTAssertEqual(state.totalXP,4);XCTAssertEqual(state.practiceStoryLine(words:"Buenos días.",confidence:0.9),0)
    }
}

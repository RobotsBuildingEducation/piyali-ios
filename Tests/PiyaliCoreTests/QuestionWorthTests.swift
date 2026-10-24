import XCTest
@testable import PiyaliCore

final class QuestionWorthTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    private let now=Date(timeIntervalSince1970:1_792_584_000)
    private func user(_ rating:Double)->JSONValue { .object(["learningIntelligence":.object(["es":.object(["elo":.object(["rating":.number(rating),"scaleVersion":.number(4)])])])]) }
    @MainActor func testQuotedNativeOutcomesAgreeWithOriginalSourceAcrossDifficultyAndHelp() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"));var count=0
        for rating in [800.0,821,1100,1800,2199,2200] { for level in LearningLanguages.levels { for difficulty:Double? in [nil,7,42,93] { for support in GoalPractice.supports { for correct in [false,true] {
            let independent=["independent","transferred"].contains(support)
            var p:JSONValue = .object(["user":user(rating),"targetLang":.string("es"),"questionLevel":.string(level)])
            if let difficulty { p=p.setting("assessment",.object(["difficultyScore":.number(difficulty)])) }
            let quote=try recipes.inspect("worth",parameters:p)
            let fields:JSONValue = .object(["elo":.object(["rating":.number(rating),"scaleVersion":.number(4),"totalGraded":.number(4)])])
            var event=PracticeChange(date:now,dayKey:CalendarDay.key(now),target:"es",level:level,amount:0,source:.assessment,correct:correct,independent:independent);event.gradedSupport=support;event.gradedWorth=quote;event.gradedConcept="family";event.gradedMode="grammar"
            let input:JSONValue = .object(["bucket":fields,"event":.object(["id":.string(event.id.uuidString),"questionLevel":.string(level),"worth":quote,"success":.bool(correct),"support":.string(support),"concept":.string("family"),"mode":.string("grammar")]),"fallbackLevel":.string(level),"now":.string(WebProgressContract.iso(now))])
            let expected=try recipes.inspect("graded",parameters:input),native=JSONValue.foundation(QuestionWorth.gradedBucket(fields.foundation,change:event))
            XCTAssertEqual(native,expected,"\(rating)/\(level)/\(String(describing:difficulty))/\(independent)/\(correct)");count += 1
        } } } } };XCTAssertEqual(count,1680)
    }
    @MainActor func testDifficultyParserUsesStrictSourceBoundsAndFallbackProvenance() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        for raw in [#"{"difficultyScore":-1}"#,#"{"difficultyScore":101}"#,#"{"difficultyScore":1.5}"#,#"{"difficultyScore":"30"}"#,"not JSON"] { XCTAssertEqual(try recipes.inspect("parseDifficulty",parameters:.object(["raw":.string(raw)])),.null) }
        XCTAssertEqual(try recipes.inspect("parseDifficulty",parameters:.object(["raw":.string("```json\n{\"difficultyScore\":30}\n```") ])),.number(30))
        let fallback=try recipes.inspect("worth",parameters:.object(["user":user(1100),"targetLang":.string("es"),"questionLevel":.string("B2")]))
        XCTAssertEqual(fallback["difficultySource"].string,"cefr_fallback");XCTAssertEqual(fallback["difficultyScore"],.null)
        let measured=try recipes.inspect("worth",parameters:.object(["user":user(1100),"targetLang":.string("es"),"questionLevel":.string("B2"),"assessment":.object(["difficultyScore":.number(10)])]))
        XCTAssertEqual(measured["assessedQuestionLevel"].string,"Pre-A1");XCTAssertEqual(measured["difficultySource"].string,"model_assessment")
        XCTAssertLessThan(QuestionWorth.rating(1100,level:"B2",correct:true,independent:false,worth:measured),QuestionWorth.rating(1100,level:"B2",correct:true,independent:true,worth:measured))
        XCTAssertNil(QuestionWorth.delta(level:"B2",correct:true,independent:true,worth:measured.setting("version",.number(99))))
    }
    @MainActor func testOneUnchangedMissCannotApplyTheQuoteTwiceAndBankEvidenceUsesTheActualOrder() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let quote=try recipes.inspect("worth",parameters:.object(["user":user(1100),"targetLang":.string("es"),"questionLevel":.string("A1"),"assessment":.object(["difficultyScore":.number(10)])]))
        var q=try PracticeQuestion(module:.grammar,kind:"translate",payload:.object(["sentence":.string("Hola"),"correctWords":.array([.string("Hello")]),"distractors":.array([.string("Bye")])]),options:.object(["cefrLevel":.string("A1")]),target:"es",support:"en");q.worth=quote
        let run=PracticeRun(question:q,lessonID:nil,lessonLevel:nil,response:.object(["indices":.array([.number(0)])]),bank:["Bye","Hello"])
        XCTAssertEqual(run.assessmentItem["wordBank"].array,[.string("Bye"),.string("Hello")]);XCTAssertEqual(run.difficultyMode,"grammar:translate")
        var state=LearnerState();state.ratingByLanguage=["es":1100];state.savePractice(run)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6));let afterMiss=state.rating
        XCTAssertFalse(state.answerPractice(key:run.key,questionID:q.id,correct:false,reward:6));XCTAssertEqual(state.rating,afterMiss);XCTAssertEqual(state.gradedByLanguage?["es"],1)
        var revised=try XCTUnwrap(state.practiceRuns?[run.key]);revised.response = .object(["indices":.array([.number(1)])]);state.savePractice(revised)
        XCTAssertTrue(state.answerPractice(key:run.key,questionID:q.id,correct:true,reward:6));XCTAssertEqual(state.gradedByLanguage?["es"],2);XCTAssertEqual(state.xp,6)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.practiceRuns?[run.key]?.question.worth,quote)
    }
    @MainActor func testPrivateSnapshotAndCloudAssessmentKeepTheSameSavedQuoteWithoutXP() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let quote=try recipes.inspect("worth",parameters:.object(["user":user(1100),"targetLang":.string("es"),"questionLevel":.string("B2"),"assessment":.object(["difficultyScore":.number(10)])]))
        var state=LearnerState();state.ratingByLanguage=["es":1100];state.assess(correct:false,independent:false,now:now,questionLevel:"B2",worth:quote,concept:"mamá",mode:"vocabulary")
        let event=try XCTUnwrap(state.pendingChanges?.last);XCTAssertEqual(event.gradedWorth,quote);XCTAssertEqual(event.amount,0);XCTAssertEqual(state.xp,0)
        let fields:[String:Any] = ["learningIntelligence":["es":["elo":["rating":1100,"scaleVersion":4]]]]
        let patched=WebProgressContract.rootPatch(fields:fields,month:[:],change:event,now:now),bucket=((patched.root["learningIntelligence"] as? [String:[String:Any]])?["es"] ?? [:])
        XCTAssertEqual(WebProgressContract.number((bucket["elo"] as? [String:Any])?["rating"]),state.rating,accuracy:1e-9)
        XCTAssertNotNil(((bucket["performanceSummary"] as? [String:Any])?["byLevel"] as? [String:Any])?["Pre-A1"])
        XCTAssertEqual(QuestionWorth.gradedBucket(bucket,change:event) as NSDictionary,bucket as NSDictionary,"Event retry cannot regrade")
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state));XCTAssertEqual(restored.pendingChanges?.last?.gradedWorth,quote);XCTAssertEqual(restored.rating,state.rating)
        XCTAssertEqual(restored.goalBucket["performanceSummary"]["weakConcepts"].array.first?["concept"].string,"mamá")
    }
}

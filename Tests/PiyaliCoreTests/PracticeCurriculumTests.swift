import XCTest
@testable import PiyaliCore

final class PracticeCurriculumTests:XCTestCase {
    private var root:URL { URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    @MainActor func testActualFamilyLessonUsesManualSourceObjectivesAndRejectsAnUnrelatedDraft() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let library=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-es.json.gz")),unit=try XCTUnwrap(library["Pre-A1"]?.first),lesson=try XCTUnwrap(unit.lessons.first)
        let context=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:"es",recipes:recipes)
        XCTAssertEqual(context["lessonId"].string,"lesson-pre-a1-1-1");XCTAssertEqual(context["agendaItems"].array.count,7)
        XCTAssertEqual(context["agendaItems"].array.first?["targetForms"].array.first?.string,"mamá")
        XCTAssertEqual(context["sourceLessonIds"].array,[.string(lesson.id)])
        XCTAssertTrue(try PracticeCurriculum.grounded(.object(["question":.string("Mi mamá se llama Ana.")]),mode:"vocabulary",context:context,recipes:recipes))
        XCTAssertFalse(try PracticeCurriculum.grounded(.object(["question":.string("The train leaves tomorrow.")]),mode:"vocabulary",context:context,recipes:recipes))
        let content=PracticeCurriculum.content(lesson,mode:"vocabulary",context:context)
        XCTAssertEqual(content["curriculumContext"],context)
        let prompt=try recipes.build(module:.vocabulary,kind:"mc",parameters:.object(["targetLang":.string("es"),"supportLang":.string("en"),"cefrLevel":.string("Pre-A1"),"appUILang":.string("en"),"lessonContent":content,"randomSeed":.number(1)]))
        XCTAssertTrue(prompt.contains("mamá"));XCTAssertTrue(prompt.contains("lesson-pre-a1-1-1"));XCTAssertFalse(prompt.contains("undefined"))
    }
    @MainActor func testOnlyGrammarMatchingUsesTheOriginalPairGroundingGuard() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let context:JSONValue = .object(["agendaItems":.array([.object(["kind":.string("grammar"),"targetConcept":.string("mamá"),"targetForms":.array([.string("mamá")]),"modes":.array([.string("grammar")])])])])
        let pairs:JSONValue = .object(["stem":.string("mamá"),"left":.array(["train","plane","bus"].map(JSONValue.string)),"right":.array(["station","airport","stop"].map(JSONValue.string)),"map":.array([0,1,2].map { .number(Double($0)) })])
        let grammar=try PracticeQuestion(module:.grammar,kind:"match",payload:pairs,options:.object([:]),target:"es",support:"en")
        XCTAssertFalse(try PracticeCurriculum.accepts(grammar,context:context,recipes:recipes),"The stem must not hide off-lesson matching pairs")
        let vocabulary=try PracticeQuestion(module:.vocabulary,kind:"match",payload:pairs,options:.object([:]),target:"es",support:"en")
        XCTAssertTrue(try PracticeCurriculum.accepts(vocabulary,context:context,recipes:recipes),"Do not introduce a filter absent from the source renderer")
    }
    @MainActor func testTargetAdapterTutorialLevelAndFocusedLessonsKeepTheirOwnScope() throws {
        let recipes=try PracticeRecipes(source:root.appendingPathComponent("Piyali/Resources/practice-recipes.js"))
        let japanese=try ContentLibrary.decode([String:[LearningUnit]].self,url:root.appendingPathComponent("Piyali/Resources/curriculum-ja.json.gz")),unit=try XCTUnwrap(japanese["A1"]?.first),lesson=try XCTUnwrap(unit.lessons.first)
        let context=try PracticeCurriculum.context(lesson:lesson,unit:unit,target:"ja",recipes:recipes)
        XCTAssertEqual(context["targetLang"].string,"ja");XCTAssertTrue(context["targetLanguageAdapted"].boolean);XCTAssertFalse(context["agendaItems"].array.isEmpty)
        let intro=try ContentLibrary.decode(IntroLibrary.self,url:root.appendingPathComponent("Piyali/Resources/intro-es.json.gz")),advanced=try XCTUnwrap(intro.units["B2"]?.lessons.first)
        let data=PracticeCurriculum.lessonData(advanced);XCTAssertTrue(data["isTutorial"].boolean);XCTAssertEqual(data["tutorialPracticeLevel"].string,"B2");XCTAssertFalse(data["isGame"].boolean)
        let adapted=try PracticeCurriculum.context(lesson:advanced,unit:intro.units["B2"],target:"es",recipes:recipes);XCTAssertEqual(adapted["tutorialPracticeLevel"].string,"B2")
        let focused=Lesson(id:"goal-private",title:.string("Personal goal"),description:.string(""),xpReward:0,modes:["vocabulary"],agenda:.object([:]),content:.object(["vocabulary":.object(["isGoal":.bool(true)])]))
        XCTAssertEqual(try PracticeCurriculum.context(lesson:focused,unit:nil,target:"es",recipes:recipes),.null)
        XCTAssertTrue(try PracticeCurriculum.grounded(.object(["question":.string("Any free practice")]),mode:"grammar",context:.null,recipes:recipes))
    }
}

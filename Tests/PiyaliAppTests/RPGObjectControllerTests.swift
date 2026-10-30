import XCTest
@testable import Piyali

@MainActor final class RPGObjectControllerTests:XCTestCase {
    private var objects:[RPGObject]{[RPGObject(type:"counter",tx:4,ty:5),RPGObject(type:"plant",tx:8,ty:2)]}
    private func input(_ support:String="en")->JSONValue{.object(["map":.object(["id":.string("room"),"name":.string("Market")]),"target":.string("es"),"support":.string(support),"level":.string("Pre-A1"),"objects":.array(objects.map{.object(["type":.string($0.type),"tx":.number(Double($0.tx)),"ty":.number(Double($0.ty))])})])}
    private func wait(_ condition:()->Bool)async throws{for _ in 0..<100 where !condition(){try await Task.sleep(for:.milliseconds(10))};XCTAssertTrue(condition())}
    func testWholeAreaPreloadDeduplicatesTapsAndResolvesOnlyTheLatestObservation()async throws {
        let controller=RPGObjectController(displayMilliseconds:1000);var count=0,prompt="";var complete:CheckedContinuation<String,Never>?
        let generate:(String)async throws->String={value in count+=1;prompt=value;return await withCheckedContinuation{complete=$0}}
        controller.configure(scope:"learner:run:es:en",parameters:input(),objects:objects,generate:generate);try await wait{complete != nil}
        controller.examine(objects[0]);XCTAssertEqual(controller.observation?.fields["text"],.string("You notice counter."));XCTAssertEqual(controller.observation?.pending,true)
        controller.configure(scope:"learner:run:es:en",parameters:input(),objects:objects,generate:generate);controller.examine(objects[1]);XCTAssertEqual(count,1)
        XCTAssertTrue(prompt.contains("room:4,5:counter"));XCTAssertTrue(prompt.contains("room:8,2:plant"));XCTAssertTrue(prompt.contains("not dialogue and not a quiz"))
        complete?.resume(returning:"[{\"key\":\"room:8,2:plant\",\"name\":\"planta\",\"text\":\"Una planta.\",\"supportName\":\"plant\",\"supportText\":\"A plant.\"}]")
        try await wait{controller.observation?.pending == false};XCTAssertEqual(controller.observation?.key,"room:8,2:plant");XCTAssertEqual(controller.observation?.fields["text"],.string("Una planta."))
        controller.examine(objects[0]);XCTAssertEqual(controller.observation?.pending,false);XCTAssertEqual(controller.observation?.fields["text"],.string("You notice counter."));XCTAssertEqual(count,1);controller.cancel()
    }
    func testPendingHasNoExpiryThenEachCachedTapGetsItsOwnDismissalWindow()async throws {
        let controller=RPGObjectController(displayMilliseconds:100);var complete:CheckedContinuation<String,Never>?
        controller.configure(scope:"one",parameters:input(),objects:objects){_ in await withCheckedContinuation{complete=$0}};try await wait{complete != nil};controller.examine(objects[0])
        try await Task.sleep(for:.milliseconds(150));XCTAssertNotNil(controller.observation)
        complete?.resume(returning:"[]");try await wait{controller.observation?.pending == false};try await Task.sleep(for:.milliseconds(60));controller.examine(objects[1]);try await Task.sleep(for:.milliseconds(60));XCTAssertNotNil(controller.observation);try await wait{controller.observation == nil};controller.cancel()
    }
    func testFailedRequestKeepsOriginalLocalizedFallbackAndCancelRejectsLateAccountLanguageReplies()async throws {
        let controller=RPGObjectController(displayMilliseconds:500);var complete:CheckedContinuation<String,Never>?
        controller.configure(scope:"alice:es:en",parameters:input(),objects:objects){_ in await withCheckedContinuation{complete=$0}};try await wait{complete != nil};controller.examine(objects[0])
        controller.configure(scope:"bob:es:ar",parameters:input("ar"),objects:objects){_ in throw URLError(.notConnectedToInternet)}
        controller.examine(objects[0]);try await wait{controller.observation?.pending == false};let arabic=controller.observation?.fields
        XCTAssertEqual(arabic?["text"],.string("You notice counter."));XCTAssertFalse(arabic?["supportName"].string.isEmpty ?? true)
        complete?.resume(returning:"[{\"key\":\"room:4,5:counter\",\"text\":\"OLD ACCOUNT\"}]");try await Task.sleep(for:.milliseconds(40));XCTAssertEqual(controller.observation?.fields,arabic)
        controller.cancel();XCTAssertNil(controller.observation);XCTAssertNil(controller.hit(.init(x:4,y:5)))
    }
    func testPromptIncludesActualCoursePlacementAndSeparateTutorLevelWithoutIdentityFields()throws {
        var state=LearnerState();state.level="B1";state.tutorUnlockedLevels=["es":"B2"];state.placements=["es":.init(level:"A2",score:32,source:"self_report",selectedIDs:[],updatedAt:Date())]
        state.courseCompletion=["es":["skillTree":["Pre-A1":86],"flashcards":["Pre-A1":10000]]]
        let user=state.rpgObjectUser;XCTAssertEqual(user["progress"]["level"],.string("B1"));XCTAssertEqual(user["proficiencyPlacements"]["es"],.string("A2"));XCTAssertEqual(user["progress"]["tutorUnlockedLevels"]["es"],.string("B2"))
        let prompt=try RPGObjectPolicy().run("prompt",input().setting("user",user)).string
        XCTAssertTrue(prompt.contains("\"skillTree\":\"A2\""));XCTAssertTrue(prompt.contains("\"tutor\":\"B2\""));XCTAssertTrue(prompt.contains("\"curriculumCefrLevel\":\"B2\""));XCTAssertEqual(user["npub"],.null);XCTAssertEqual(user["privateKey"],.null)
    }

}

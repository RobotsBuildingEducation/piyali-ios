import XCTest
@testable import PiyaliCore
final class CommunityFeedTests:XCTestCase {
    func testSourceFilterAndQuestionFixtures() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/community-feed.json")
        let cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        XCTAssertEqual(cases.count,42)
        for item in cases {
            let actual=CommunityMilestone.parse(content:item["content"].string,tags:[],name:item["name"].string)
            XCTAssertEqual(actual != nil,item["visible"].boolean,item.json)
            if let actual { XCTAssertEqual(actual.question,item["question"] == .null ? nil : item["question"].number);XCTAssertEqual(actual.questionPercent,item["percent"] == .null ? nil : item["percent"].number) }
        }
    }
    func testMilestoneFilteringAndNumericBounds() throws {
        for name in ["data","TEST","hi","text","hii"] { XCTAssertNil(CommunityMilestone.parse(content:"question 5",tags:[],name:name)) }
        XCTAssertNil(CommunityMilestone.parse(content:"hello",tags:[],name:"Ada"));XCTAssertNil(CommunityMilestone.parse(content:"question 0",tags:[],name:"Ada"))
        XCTAssertEqual(CommunityMilestone.parse(content:"Finished QUESTION 180",tags:[],name:"Ada")?.questionPercent,100)
        XCTAssertNotNil(CommunityMilestone.parse(content:"A NEW SCHOLARSHIP",tags:[],name:"Ada"))
        let progress=try XCTUnwrap(CommunityMilestone.parse(content:"I just reached 12 XP",tags:[["total_xp","12"],["daily_goal_percent","-8"]],name:"Ada"))
        XCTAssertEqual(progress.totalXP,12);XCTAssertEqual(progress.goalPercent,0)
        XCTAssertNil(CommunityMilestone.parse(content:"I just reached",tags:[["total_xp","NaN"],["daily_goal_percent","Infinity"]],name:"Ada")?.totalXP)
    }
    func testPublisherUsesWebContentAndLowercaseTagWithoutPrivateState() {
        var state=LearnerState();state.xpByLanguage=["es":100];state.dailyXP=20;state.dailyGoal=30;state.target="es";state.name="Private Learner"
        let post=CommunityMilestone.progress(state)
        XCTAssertEqual(post.content,"I'm 67% through today's 30 XP goal (20/30 XP) and now have 100 XP total on https://piyali.app practicing Spanish! #LearnWithNostr")
        XCTAssertEqual(post.tags,[["t","learnwithnostr"],["purpose","nosaboProgress"],["total_xp","100"],["daily_goal_percent","67"],["daily_xp","20"],["daily_goal_target","30"]])
        XCTAssertFalse(post.content.contains(state.name));state.dailyGoal=0
        XCTAssertEqual(CommunityMilestone.progress(state).content,"I just reached 100 XP on https://piyali.app practicing Spanish! #LearnWithNostr")
    }
}

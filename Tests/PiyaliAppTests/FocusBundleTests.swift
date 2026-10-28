import XCTest
import UIKit
@testable import Piyali

final class FocusBundleTests:XCTestCase {
    func testHomeArtworkAndAllHealthAnimationsSurviveIPhoneBundling() throws {
        let frames=try ContentLibrary.load(JSONValue.self,name:"companion-stages"),ui=try ContentLibrary.load(JSONValue.self,name:"focus-ui")
        XCTAssertNotNil(UIImage(named:"Focus-pet-gamepad"));for scheme in ["green","teal","yellow","orange","red","gray"]{for key in ["background","color"]{XCTAssertTrue(ui["panelBadges"][scheme][key].string.hasPrefix("#"))}}
        let states=["happy","healthy","unhappy","stressed","unhealthy","dead"]
        for stage in states {
            XCTAssertFalse(ui["stages"][stage]["light"]["background"].string.isEmpty)
            XCTAssertFalse(ui["stages"][stage]["dark"]["background"].string.isEmpty)
            for pet in CompanionTypes.ordered {
                let animation=frames[stage][pet].array;XCTAssertEqual(animation.count,12,"\(stage):\(pet)");XCTAssertFalse(animation[0].array.isEmpty)
                XCTAssertNotEqual(animation,frames[stage == "happy" ? "unhealthy" : "happy"][pet].array,"Health must change the artwork, not just its caption.")
            }
        }
        for item in try ContentLibrary.load([JSONValue].self,name:"score-milestones") {XCTAssertNotNil(UIImage(named:"Focus-score-"+item["icon"].string))}
        for kind in DailyPlate.order {XCTAssertNotNil(UIImage(named:"Focus-course-"+kind))}
        for language in LearningLanguages.support {
            let copy=ui["copy"][language];for key in ["level","score","activity","companion","achievements"] {XCTAssertFalse(copy[key].string.isEmpty,"\(language):\(key)")}
            XCTAssertFalse(copy["customize"]["cancel"].string.isEmpty);XCTAssertFalse(copy["immersion"]["placementNeeded"].string.isEmpty);XCTAssertEqual(copy["immersion"]["encouragements"].array.count,20)
        }
    }
}

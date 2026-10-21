import XCTest
import UIKit
@testable import Piyali

@MainActor final class EntryBundleTests:XCTestCase {
    func testBundledOriginalRecipesBuildInTheIPhoneRuntime() throws {
        let recipes=try PracticeRecipes()
        let parameters:JSONValue = .object(["cefrLevel":.string("Pre-A1"),"targetLang":.string("es"),"supportLang":.string("en"),"appUILang":.string("en"),"showTranslations":.bool(true),"recentGood":.array([]),"randomSeed":.number(1)])
        let prompt=try recipes.build(module:.grammar,kind:"fill",parameters:parameters)
        XCTAssertTrue(prompt.contains("Create ONE short Spanish grammar fill-in-the-blank"));XCTAssertTrue(prompt.contains("\"type\":\"fill\""))
    }
    func testOriginalArtworkAndFontsDecodeFromTheBuiltApp() throws {
        for name in ["piyali-orb.png","onboarding-character.webp"] {
            let url=try XCTUnwrap(Bundle.main.url(forResource:name,withExtension:nil));let image=try XCTUnwrap(UIImage(contentsOfFile:url.path),name)
            XCTAssertGreaterThan(image.size.width,100);XCTAssertGreaterThan(image.size.height,100)
        }
        for name in ["LandingGlobe","LandingMission","LandingHuman","LandingCommunity","LandingTechnology"] { XCTAssertNotNil(UIImage(named:name),name) }
        XCTAssertEqual(LandingDemoService.course["turns"]["es"].array.count,6)
        XCTAssertTrue(LandingDemoService.course["instructions"]["ja"]["en"].string.contains("five-turn"))
        for name in ["DMSans-Regular","DMSans-Medium","DMSans-SemiBold","DMSans-Bold"] { XCTAssertNotNil(UIFont(name:name,size:16),name) }
    }
}

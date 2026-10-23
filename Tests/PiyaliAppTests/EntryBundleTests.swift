import XCTest
import UIKit
import SwiftUI
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
        for code in Set(LearningLanguages.support+LearningLanguages.practice) {XCTAssertNotNil(UIImage(named:"LanguageFlag-"+code),code)}
        XCTAssertEqual(LandingDemoService.course["turns"]["es"].array.count,6)
        XCTAssertTrue(LandingDemoService.course["instructions"]["ja"]["en"].string.contains("five-turn"))
        for name in ["DMSans-Regular","DMSans-Medium","DMSans-SemiBold","DMSans-Bold"] { XCTAssertNotNil(UIFont(name:name,size:16),name) }
    }
    func testSubtitleMatchesActualBrowserLineBoxAndStillScalesForAccessibility() throws {
        let data=try Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"entry-hero-layout",withExtension:"json"))),sample=try JSONDecoder().decode(JSONValue.self,from:data)["paragraph"],width=sample["rect"]["width"].number
        let subtitle=EntryLineText(text:sample["text"].string,size:11.2),normal=UIHostingController(rootView:subtitle.environment(\.dynamicTypeSize,.large)),accessible=UIHostingController(rootView:subtitle.environment(\.dynamicTypeSize,.accessibility2))
        let measured=normal.sizeThatFits(in:CGSize(width:width,height:2000)),larger=accessible.sizeThatFits(in:CGSize(width:width,height:2000))
        XCTAssertEqual(measured.height,sample["rect"]["height"].number,accuracy:0.8,"Original browser paragraph is three 17.92-point line boxes at 354 points wide.");XCTAssertGreaterThan(larger.height,measured.height)
    }
}

import XCTest
import UIKit
import CryptoKit
@testable import Piyali

@MainActor final class PaperPencilTests:XCTestCase {
    func testCurrentMangaCopyAndActionSoundAreBundled()throws{
        XCTAssertEqual(PaperPencilCopy.source["copy"].object.count,11);for(_,copy)in PaperPencilCopy.source["copy"].object{for key in ["title","subtitle","message","tip","understood"]{XCTAssertFalse(copy["paper_pencil_"+key].string.isEmpty)}}
        XCTAssertEqual(PaperPencilCopy.text("unknown","title"),PaperPencilCopy.text("en","title"));XCTAssertTrue(PaperPencilCopy.source["animations"].array.isEmpty)
        let url=try XCTUnwrap(Bundle.main.url(forResource:"paper-pencil-manga",withExtension:"webp")),data=try Data(contentsOf:url),image=try XCTUnwrap(UIImage(contentsOfFile:url.path));XCTAssertEqual(image.size,CGSize(width:960,height:448));XCTAssertEqual(SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined(),PaperPencilCopy.source["illustration"]["sha256"].string)
        let audio=try Data(contentsOf:try XCTUnwrap(Bundle.main.url(forResource:"submitAction",withExtension:"wav")));XCTAssertEqual(String(data:audio.prefix(4),encoding:.ascii),"RIFF");XCTAssertGreaterThan(audio.count,18000)
    }
    func testOriginalAppEntryCallbacksAcrossAcknowledgmentAndPlacementFlags()throws{
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"paper-pencil-entry",withExtension:"json")),cases=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url));XCTAssertEqual(cases.count,8)
        func expected(_ events:JSONValue)->FirstRunFlow.Step?{for row in events.array.reversed(){switch row.array.first?.string{case "paper" where row.array.last?.boolean == true:return .paperPencil;case "guidance":return .gettingStarted;case "placement":return .placement;default:break}};return nil}
        for row in cases{let p=row["input"];XCTAssertTrue(row["initialOpen"].boolean);XCTAssertEqual(row["onboardingClose"],.array([.array([.string("paper"),.bool(false)])]));var flow=FirstRunFlow();flow.request(scope:"public-account:es",shown:p["shown"].boolean,paperShown:p["paperShown"].boolean,hasPlacement:p["hasPlacement"].boolean);XCTAssertEqual(flow.step,expected(row["request"]));flow.presentInitialPaper(scope:"public-account:es");XCTAssertTrue(flow.acknowledgePaper(scope:"public-account:es",shown:p["shown"].boolean,hasPlacement:p["hasPlacement"].boolean));XCTAssertEqual(flow.step,expected(row["close"]))}
    }
    func testInitialPaperIgnoresPriorAcknowledgmentButUsesExistingProductContinuation(){
        var flow=FirstRunFlow();flow.presentInitialPaper(scope:"account:es");XCTAssertEqual(flow.step,.paperPencil)
        XCTAssertTrue(flow.acknowledgePaper(scope:"account:es",shown:true,hasPlacement:true));XCTAssertNil(flow.step)
        flow.presentInitialPaper(scope:"account:es");XCTAssertTrue(flow.acknowledgePaper(scope:"account:es",shown:false,hasPlacement:false));XCTAssertEqual(flow.step,.gettingStarted)
        XCTAssertFalse(flow.acknowledge(scope:"other:es",hasPlacement:false));XCTAssertEqual(flow.step,.gettingStarted)
    }
}

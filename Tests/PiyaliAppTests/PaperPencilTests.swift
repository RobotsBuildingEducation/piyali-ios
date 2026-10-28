import XCTest
import UIKit
@testable import Piyali

@MainActor final class PaperPencilTests:XCTestCase {
    func testOriginalWebKitAnimationMatricesAndDelayedOpacity()throws{
        let url=try XCTUnwrap(Bundle(for:Self.self).url(forResource:"paper-pencil-motion",withExtension:"json")),rows=try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:url))
        for row in rows{let time=row["time"].number;for layer in 0..<3{let style=row["styles"].array[layer],p=PaperPencilMotion.pulse(time,layer:layer),matrix=style["transform"].string.replacingOccurrences(of:"matrix(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap{Double($0.trimmingCharacters(in:.whitespaces))}
            if layer==0{XCTAssertEqual(matrix.count,6);XCTAssertEqual(matrix[4],-2*p,accuracy:0.00002);XCTAssertEqual(matrix[5],-3.5*p,accuracy:0.00002);XCTAssertEqual(matrix[0],cos(-1.2*p*Double.pi/180),accuracy:0.000002);XCTAssertEqual(matrix[1],sin(-1.2*p*Double.pi/180),accuracy:0.000002)}else{XCTAssertEqual(PaperPencilMotion.sparkleOpacity(time,layer:layer),style["opacity"].number,accuracy:0.00002);if !matrix.isEmpty{XCTAssertEqual(matrix[0],1-0.18*p,accuracy:0.00002)}}
        }}
    }
    func testAllAuthoredArtCopyAndActionSoundAreBundled()throws{
        XCTAssertEqual(PaperPencilCopy.source["copy"].object.count,11);for(_,copy)in PaperPencilCopy.source["copy"].object{for key in ["title","subtitle","message","tip","understood"]{XCTAssertFalse(copy["paper_pencil_"+key].string.isEmpty)}}
        XCTAssertEqual(PaperPencilCopy.text("unknown","title"),PaperPencilCopy.text("en","title"));XCTAssertNotNil(UIImage(named:"PaperPencil-header"));for theme in ["light","dark"]{for name in ["base","pencil","sparkle-left","sparkle-right","tail"]{XCTAssertNotNil(UIImage(named:"PaperPencil-"+theme+"-"+name))}}
        let audio=try Data(contentsOf:try XCTUnwrap(Bundle.main.url(forResource:"submitAction",withExtension:"wav")));XCTAssertEqual(String(data:audio.prefix(4),encoding:.ascii),"RIFF");XCTAssertGreaterThan(audio.count,18000)
    }
}

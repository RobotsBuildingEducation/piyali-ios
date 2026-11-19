import XCTest
@testable import PiyaliCore
final class DelightInteractionTests:XCTestCase {
    func testOriginalSortingForgeAndDetectiveHandlersAndUnicodeWordOrder()throws {
        struct Sample:Decodable{let variant:String,input:JSONValue,expected:JSONValue}
        struct Order:Decodable{let words:[String],expected:[String]}
        struct Fixture:Decodable{let samples:[Sample],orders:[Order]}
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/delight-interactions.json"),fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:url))
        XCTAssertEqual(fixture.samples.count,132);XCTAssertEqual(fixture.orders.count,17)
        for sample in fixture.samples {
            let p=sample.input,q=p["question"],r=p["response"],locked=p["locked"].boolean;let result:JSONValue
            switch sample.variant {
            case "word_neighborhoods":
                if p["action"].string == "drag" {let d=p["drag"],destination=d["destination"]["droppableId"].string,source=d["source"]["droppableId"].string;result=source == destination ? r:DelightInteraction.neighborhood(question:q,response:r,word:d["draggableId"].string,group:destination == "bank" ? nil:Int(destination.replacingOccurrences(of:"group-",with:"")),locked:locked)}
                else{result=DelightInteraction.neighborhood(question:q,response:r,word:p["word"].string,group:p["action"].string == "return" ? nil:Int(p["group"].number),locked:locked)}
            case "morphology_forge":
                if p["action"].string == "drag"{let d=p["drag"],destination=d["destination"]["droppableId"].string,source=d["source"]["droppableId"].string;result=source == destination ? r:DelightInteraction.forge(question:q,response:r,piece:Int(d["draggableId"].string.replacingOccurrences(of:"piece-",with:""))!,toForge:destination == "forge",locked:locked)}
                else{result=DelightInteraction.forge(question:q,response:r,piece:Int(p["piece"].number),toForge:p["action"].string == "add",locked:locked)}
            default:result=p["action"].string == "token" ? DelightInteraction.detective(question:q,response:r,index:Int(p["index"].number),locked:locked):DelightInteraction.repair(question:q,response:r,word:p["word"].string,locked:locked)
            }
            XCTAssertEqual(result,sample.expected,"\(sample.variant) \(p["action"].string)")
        }
        for order in fixture.orders{XCTAssertEqual(DelightInteraction.wordOrder(order.words),order.expected)}
    }
    func testForeignItemsAndMissingPiecesCannotChangeAResponse() {
        let q:JSONValue = .object(["groups":.array([.object(["items":.array([.string("casa")])])]),"pieces":.array([.string("habl"),.string("o")])]),r:JSONValue = .object(["assignments":.object([:]),"pieceIndices":.array([.number(0)])])
        XCTAssertEqual(DelightInteraction.neighborhood(question:q,response:r,word:"foreign",group:0,locked:false),r)
        XCTAssertEqual(DelightInteraction.neighborhood(question:q,response:r,word:"casa",group:9,locked:false),r)
        XCTAssertEqual(DelightInteraction.forge(question:q,response:r,piece:9,toForge:true,locked:false),r)
        XCTAssertEqual(DelightInteraction.forge(question:q,response:r,piece:1,toForge:false,locked:false),r)
    }
}

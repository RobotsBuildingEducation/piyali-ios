import XCTest
@testable import PiyaliCore
final class GameLoaderTests:XCTestCase{
    private func diff(_ a:JSONValue,_ b:JSONValue,_ path:String="root")->String?{
        if a == b{return nil}
        if case .string(let x)=a,case .string(let y)=b,path.hasPrefix("root.ops"),x.hasPrefix("rgba("),y.hasPrefix("rgba("){
            let separator=CharacterSet(charactersIn:"0123456789.-").inverted,first=x.components(separatedBy:separator).compactMap(Double.init),second=y.components(separatedBy:separator).compactMap(Double.init)
            if first.count==second.count,zip(first,second).allSatisfy({abs($0-$1)<1e-9}){return nil}
        }
        if case .number(let x)=a,case .number(let y)=b{return path.hasPrefix("root.ops") && abs(x-y)<1e-9 ? nil:"\(path): \(x) != \(y)"}
        if case .array(let x)=a,case .array(let y)=b{guard x.count==y.count else{return "\(path): counts"};for i in x.indices{if let d=diff(x[i],y[i],path+"[\(i)]"){return d}};return nil}
        if case .object(let x)=a,case .object(let y)=b{guard Set(x.keys)==Set(y.keys)else{return "\(path): keys"};for k in x.keys.sorted(){if let d=diff(x[k]!,y[k]!,path+"."+k){return d}};return nil}
        return "\(path): \(a) != \(b)"
    }
    func testOriginalWorldMovementDrawingMessagesAndDelayCases()throws{
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),policy=try GameLoaderPolicy(url:root.appendingPathComponent("Piyali/Resources/game-loader-policy.js")),rows=try ContentLibrary.decode([JSONValue].self,url:root.appendingPathComponent("Tests/PiyaliCoreTests/Fixtures/game-loader.json.gz"))
        XCTAssertEqual(rows.count,569)
        for (i,row) in rows.enumerated(){let actual=try policy.run(row["operation"].string,row["input"]);if let difference=diff(actual,row["expected"]){XCTFail("Original loader case \(i): \(difference)")}}
    }
}

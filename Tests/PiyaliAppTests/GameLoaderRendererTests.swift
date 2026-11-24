import XCTest
@testable import Piyali
@MainActor final class GameLoaderRendererTests:XCTestCase{
    func testNativeCanvasDrawsOriginalMapAndStopsItsClockWhenDetached()async throws{
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow},window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let host=UIViewController();window.rootViewController=host;window.makeKeyAndVisible();defer{window.isHidden=true;window.rootViewController=nil;old?.makeKey()}
        let model=GameLoaderModel(seed:7,support:"ar",pet:"axolotl",now:1000000),canvas=GameLoaderCanvasView(frame:window.bounds);canvas.paused=true;canvas.model=model;host.view.addSubview(canvas);canvas.render(now:1000000);canvas.layer.displayIfNeeded()
        let format=UIGraphicsImageRendererFormat();format.scale=1;let image=UIGraphicsImageRenderer(size:canvas.bounds.size,format:format).image{canvas.layer.render(in:$0.cgContext)},data=try XCTUnwrap(image.cgImage?.dataProvider?.data)as Data
        var colors:Set<Data>=[];for offset in stride(from:0,to:data.count-4,by:128){colors.insert(data.subdata(in:offset..<offset+4))};XCTAssertGreaterThan(colors.count,35);XCTAssertTrue(canvas.accessibilityValue?.hasPrefix("outdoor,")==true)
        let start=CFAbsoluteTimeGetCurrent();for i in 0..<20{canvas.render(now:1000100+Double(i)*16);canvas.layer.displayIfNeeded()};let milliseconds=(CFAbsoluteTimeGetCurrent()-start)*1000/20;print("NATIVE LOADER FRAME: \(milliseconds) ms average including policy, decode and drawing");XCTAssertLessThan(milliseconds,100)
        canvas.paused=false;XCTAssertTrue(canvas.isAnimating);canvas.removeFromSuperview();XCTAssertFalse(canvas.isAnimating)
        for name in ["rpgStep","rpgDialogueOpen","rpgDialogueSelect"]{let bytes=try Data(contentsOf:XCTUnwrap(Bundle.main.url(forResource:name,withExtension:"wav")));XCTAssertEqual(String(data:bytes.prefix(4),encoding:.utf8),"RIFF");XCTAssertGreaterThan(bytes.count,4000)}
    }
}

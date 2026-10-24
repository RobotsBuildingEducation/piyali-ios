import XCTest
import UIKit
import SceneKit
@testable import Piyali

@MainActor final class OrbRendererTests:XCTestCase {
    private func pixels(_ image:UIImage)throws->[UInt8] {
        let cg=try XCTUnwrap(image.cgImage);var bytes=[UInt8](repeating:0,count:cg.width*cg.height*4)
        let context=try XCTUnwrap(CGContext(data:&bytes,width:cg.width,height:cg.height,bitsPerComponent:8,bytesPerRow:cg.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue));context.draw(cg,in:CGRect(x:0,y:0,width:cg.width,height:cg.height));return bytes
    }
    func testNativeSphereRendersBothSourcePalettesWithTransparentCorners() throws {
        let host=VoiceOrbHost(frame:CGRect(x:0,y:0,width:256,height:256));host.layoutIfNeeded();defer {host.stop()}
        var outputs:[[UInt8]]=[]
        for dark in [false,true] {
            host.configure(VoiceOrbView(dark:dark,reducedMotion:true))
            let image=host.sceneView.snapshot(),bytes=try pixels(image)
            let a=XCTAttachment(image:image);a.name=dark ? "Native orb blue sleepy" : "Native orb mint sleepy";a.lifetime = .keepAlways;add(a)
            XCTAssertGreaterThan(bytes.filter{$0 > 0}.count,5000);XCTAssertLessThan(bytes[3],10)
            var colored=0
            for i in stride(from:0,to:bytes.count,by:4) { let r=Int(bytes[i]),g=Int(bytes[i+1]),b=Int(bytes[i+2]);if bytes[i+3]>240,max(r,g,b)-min(r,g,b)>15 {colored += 1} }
            XCTAssertGreaterThan(colored,1000,"Pigment shader must produce a colored body, not the plain white fallback.")
            outputs.append(bytes)
        }
        XCTAssertNotEqual(outputs[0],outputs[1])
    }
}

extension OrbRendererTests {
    func testReducedMotionReactionExpiresWhileNoDisplayLinkIsRunning() async throws {
        let host=VoiceOrbHost(frame:CGRect(x:0,y:0,width:64,height:64));host.configure(VoiceOrbView(feedback:OrbFeedback(correct:false),reducedMotion:true));defer {host.stop()}
        XCTAssertFalse(host.accessibilityLabel?.contains("sleepy") == true)
        let settled=expectation(for:NSPredicate {_,_ in host.accessibilityLabel?.contains("sleepy") == true},evaluatedWith:nil)
        await fulfillment(of:[settled],timeout:5)
    }
}

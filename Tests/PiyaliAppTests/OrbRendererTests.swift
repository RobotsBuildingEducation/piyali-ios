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
            let still=try XCTUnwrap(host.subviews.compactMap{$0 as? UIImageView}.first?.image);XCTAssertGreaterThanOrEqual(try XCTUnwrap(still.cgImage).width,512);XCTAssertLessThan(try pixels(still)[3],10,"Frozen orb corners stay transparent");XCTAssertTrue(host.sceneView.isHidden,"Do not double-composite the paused renderer below its still frame")
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

extension OrbRendererTests {
    func testReturningFromAwardStyleRestoresTutorCameraAndMaterial()throws{
        let host=VoiceOrbHost(frame:CGRect(x:0,y:0,width:128,height:128));defer{host.stop()}
        let orb=try XCTUnwrap(AchievementUI.source.data["items"]["en"].array.first?["orb"])
        host.configure(VoiceOrbView(callActive:true,personality:.init(mood:orb["mood"].string,state:orb["state"].string,reaction:orb["reaction"].string),dark:true,reducedMotion:true,achievement:orb))
        XCTAssertEqual(host.sceneView.pointOfView?.position.z ?? 0,5.6,accuracy:0.001)
        host.configure(VoiceOrbView(reducedMotion:true));XCTAssertEqual(host.sceneView.pointOfView?.position.z,5);XCTAssertEqual(host.sceneView.pointOfView?.position.y,0)
        var material:SCNMaterial?;host.sceneView.scene?.rootNode.enumerateChildNodes{node,_ in if let m=node.geometry?.firstMaterial,m.lightingModel == .physicallyBased{material=m}}
        let restored=try XCTUnwrap(material);XCTAssertEqual((restored.roughness.contents as? NSNumber)?.doubleValue ?? 0,0.28,accuracy:0.001);XCTAssertEqual((restored.metalness.contents as? NSNumber)?.doubleValue ?? 0,0.02,accuracy:0.001);XCTAssertEqual((restored.clearCoat.contents as? NSNumber)?.doubleValue ?? 0,0.72,accuracy:0.001)
    }
}

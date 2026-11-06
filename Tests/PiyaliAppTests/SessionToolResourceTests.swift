import XCTest
import SwiftUI
import CryptoKit
@testable import Piyali

@MainActor final class SessionToolResourceTests:XCTestCase {
    func testOriginalTimeUpPortraitAndNativeEnglishArabicPresentation() async throws {
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated offline rendering only.")}
        let asset=try XCTUnwrap(Bundle.main.url(forResource:"session-timer-character.webp",withExtension:nil)),data=try Data(contentsOf:asset)
        XCTAssertEqual(SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined(),"f3ed60b76b70bc38f0f9de6ef6aa8907af0378ef9d693092c87faa7e3db34d68","Source ID 32 is assets/33.webp; story image numbering is different.")
        XCTAssertNotNil(UIImage(data:data))
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),oldKey=scene.windows.first{$0.isKeyWindow}
        for language in ["en","ar"] {
            let content=SessionTimeUpView(minutes:1,language:language,onClose:{},onRestart:{}).environment(\.layoutDirection,language == "ar" ? .rightToLeft:.leftToRight).environment(\.dynamicTypeSize,.large)
            let host=UIHostingController(rootView:content),window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);window.rootViewController=host;window.makeKeyAndVisible();host.view.layoutIfNeeded()
            defer{window.isHidden=true;window.rootViewController=nil;oldKey?.makeKey()}
            try await Task.sleep(for:.milliseconds(150))
            let image=UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)}
            let shot=XCTAttachment(image:image);shot.name="Native time-up component \(language)";shot.lifetime = .keepAlways;add(shot)
        }
    }
}

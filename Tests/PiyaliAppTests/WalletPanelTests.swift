import XCTest
import SwiftUI
import WebKit
@testable import Piyali

@MainActor final class WalletPanelTests:XCTestCase {
    private func fixtures()throws->[JSONValue]{try JSONDecoder().decode([JSONValue].self,from:Data(contentsOf:try XCTUnwrap(Bundle(for:Self.self).url(forResource:"wallet-public",withExtension:"json"))))}
    func testAppModelAcceptsSourceRecipientAndCreatedFlagWithoutChangingProgress()throws {
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated identity required")}
        let app=AppModel();try app.identity.create();defer{try? app.identity.disconnect()};app.signedIn=true;app.learner.onboardingComplete=true
        let recipient=WalletCopy.recipients[1]["npub"].string,xp=app.learner.totalXP
        app.updateSettings(.object(["createdWallet":.bool(true)]));app.updateSettings(.object(["identity":.string(recipient)]))
        XCTAssertEqual(app.learner.settingsSnapshot["createdWallet"],.bool(true));XCTAssertEqual(app.learner.settingsSnapshot["identity"],.string(recipient));XCTAssertEqual(app.learner.totalXP,xp)
        app.updateSettings(.object(["identity":.string("invalid-recipient")]));XCTAssertEqual(app.learner.settingsSnapshot["identity"],.string(recipient))
    }
    func testPublicReceiptParserMatchesActualNDKAndRejectsForgedSignature()throws{
        let rows=try fixtures();XCTAssertEqual(rows.count,10)
        for row in rows{let event=try JSONDecoder().decode(NostrEventPayload.self,from:JSONEncoder().encode(row["event"])),result=WalletPublicTransaction.parse(event),expected=row["expected"]
            if expected == .null{XCTAssertNil(result)}else{let value=try XCTUnwrap(result);XCTAssertEqual(value.id,expected["id"].string);XCTAssertEqual(value.sender,expected["sender"].string);XCTAssertEqual(value.recipient,expected["recipient"].string);XCTAssertEqual(value.amount,expected["amount"].number);XCTAssertEqual(value.unit,expected["unit"].string);XCTAssertEqual(value.note,expected["note"].string)}
        }
    }
    func testPublicFeedReadsOnlyMatchingReceiptsAndSurvivesBadMetadata()async throws{
        let fixture=try fixtures(),relay=LocalNostrRelay();defer{relay.stop()}
        try await relay.start{frame,connection in if frame.first as? String == "REQ",let sub=frame[1] as? String,let filter=frame.last as? [String:Any]{if (filter["kinds"] as? [Int]) == [9321]{for row in fixture{relay.send(["EVENT",sub,try! JSONSerialization.jsonObject(with:JSONEncoder().encode(row["event"]))],to:connection)}};relay.send(["EOSE",sub],to:connection)}}
        let model=WalletPublicTransactions(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),now:{Date(timeIntervalSince1970:1700000100)});await model.load();XCTAssertFalse(model.failed);XCTAssertEqual(model.rows.count,2);XCTAssertEqual(Set(model.rows.map(\.amount)),Set([1,3]));XCTAssertTrue(model.name(model.rows[0].sender).hasPrefix("npub"));XCTAssertEqual(relay.frames().filter{$0.first as? String == "EVENT"}.count,0)
        let requests=relay.frames().filter{$0.first as? String == "REQ"}.compactMap{$0.last as? [String:Any]};XCTAssertEqual(requests.count,2);XCTAssertEqual(requests[0]["limit"] as? Int,100);XCTAssertEqual(requests[0]["since"] as? Int64,1700000100-30*24*60*60)
        let old=WalletPublicTransactions(client:NostrRelayClient(relays:[relay.url],timeout:.seconds(2)),now:{Date(timeIntervalSince1970:1800000000)});await old.load();XCTAssertTrue(old.rows.isEmpty);XCTAssertFalse(old.failed)
    }
    func testPublicFeedFailureIsVisibleAndReadNeverPublishes()async {
        let model=WalletPublicTransactions(client:NostrRelayClient(relays:[],timeout:.seconds(1)));await model.load();XCTAssertTrue(model.failed);XCTAssertFalse(model.loading);XCTAssertTrue(model.rows.isEmpty)
    }
    func testActualSourceWalletAndNativeEmptyUnfundedInvoiceAndFundedLayouts()async throws{
        let env=ProcessInfo.processInfo.environment;guard env["PIYALI_REFERENCE_PREVIEW_TESTS"] == "1",env["PIYALI_OFFLINE_TESTS"] == "1",UUID(uuidString:env["PIYALI_TEST_IDENTITY_SCOPE"] ?? "") != nil else{throw XCTSkip("Isolated source preview required")}
        let scene=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap{$0 as? UIWindowScene}.first),old=scene.windows.first{$0.isKeyWindow};defer{old?.makeKey()}
        for(lang,theme)in[("en","light"),("ar","dark")]{for state in["empty","unfunded","invoice","funded"]{
            let window=UIWindow(windowScene:scene);window.frame=CGRect(x:0,y:0,width:402,height:874);let config=WKWebViewConfiguration();config.websiteDataStore = .nonPersistent();let web=WKWebView(frame:window.frame,configuration:config),vc=UIViewController();vc.view=web;window.rootViewController=vc;window.makeKeyAndVisible();web.scrollView.contentInsetAdjustmentBehavior = .never;defer{web.stopLoading();window.isHidden=true;window.rootViewController=nil}
            web.load(URLRequest(url:URL(string:"http://127.0.0.1:5181/__piyali-wallet?language=\(lang)&theme=\(theme)&state=\(state)")!));var ready=false;for _ in 0..<600{ready=(try? await web.evaluateJavaScript("document.fonts.status==='loaded' && document.querySelectorAll('input[type=radio]').length===2"))as?Bool == true;if ready{break};try await Task.sleep(for:.milliseconds(50))};if !ready{let diagnostic=(try? await web.evaluateJavaScript("document.body.innerText"))as?String ?? "No page";let attachment=XCTAttachment(string:diagnostic);attachment.name="Wallet source readiness failure";add(attachment)};XCTAssertTrue(ready);guard ready else{return};try await Task.sleep(for:.milliseconds(500));let source=XCTAttachment(image:try await web.takeSnapshot(configuration:nil));source.name="Source Wallet \(state) \(lang)";source.lifetime = .keepAlways;add(source)
            let metrics=(try? await web.evaluateJavaScript("JSON.stringify([...document.querySelectorAll('p,button,svg,[class*=Card],label')].filter(e=>e.getBoundingClientRect().width>0).map(e=>{let r=e.getBoundingClientRect(),s=getComputedStyle(e);return{text:e.textContent,x:r.x,y:r.y,w:r.width,h:r.height,font:s.font,padding:s.padding,color:s.color,bg:s.backgroundColor}}))"))as?String ?? "[]";let geometry=XCTAttachment(data:Data(metrics.utf8),uniformTypeIdentifier:"public.json");geometry.name="Source Wallet \(state) \(lang) geometry";geometry.lifetime = .keepAlways;add(geometry);web.stopLoading();window.isHidden=true;window.rootViewController=nil
            let view=WalletPanelView(language:lang,selected:state == "empty" ? "":WalletCopy.recipients[0]["npub"].string,ready:state != "empty",canCreate:true,balance:state == "funded" ? 100:0,invoice:state == "invoice" ? "lnbc1publicwalletpreviewonly":"",choose:{_ in},create:{},deposit:{},copy:{},transactions:{})
            window.rootViewController=UIHostingController(rootView:ZStack(alignment:.top){PiyaliBrand.unitColor(theme == "dark" ? "0b1220":"fbf7f0");view.padding(24)}.environment(\.dynamicTypeSize,.large).preferredColorScheme(theme == "dark" ? .dark:.light).ignoresSafeArea());window.makeKeyAndVisible();try await Task.sleep(for:.milliseconds(450));let native=XCTAttachment(image:UIGraphicsImageRenderer(bounds:window.bounds).image{_ in window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)});native.name="Native Wallet \(state) \(lang)";native.lifetime = .keepAlways;add(native);window.isHidden=true;window.rootViewController=nil
        }}
    }
}

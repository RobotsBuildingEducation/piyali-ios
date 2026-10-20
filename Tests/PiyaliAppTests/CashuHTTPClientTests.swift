import XCTest
import CashuSwift
import CryptoKit
@testable import Piyali

private final class WalletHTTPFixture:URLProtocol {
    static var handler:((URLRequest) throws -> (Int,JSONValue))?
    override class func canInit(with request:URLRequest) -> Bool { request.url?.host == "wallet-http.invalid" }
    override class func canonicalRequest(for request:URLRequest) -> URLRequest { request }
    override func startLoading() {
        do { let (status,body)=try Self.handler!(request);client?.urlProtocol(self,didReceive:HTTPURLResponse(url:request.url!,statusCode:status,httpVersion:nil,headerFields:["Content-Type":"application/json"])!,cacheStoragePolicy:.notAllowed);client?.urlProtocol(self,didLoad:try JSONEncoder().encode(body));client?.urlProtocolDidFinishLoading(self) }
        catch { client?.urlProtocol(self,didFailWithError:error) }
    }
    override func stopLoading() {}
}
@MainActor final class CashuHTTPClientTests:XCTestCase {
    private func client() -> CashuHTTPClient { let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[WalletHTTPFixture.self];return CashuHTTPClient(session:URLSession(configuration:config)) }
    func testMintKeysetsAreLoadedFromItsBasePathAndValidatedBeforePayment() async throws {
        let fixture=WalletFixtureMint(),mint=try await fixture.loadMint("https://wallet-http.invalid/Bitcoin"),keyset=mint.keysets[0]
        let json=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(keyset));var paths:[String]=[]
        WalletHTTPFixture.handler={ request in paths.append(request.url!.path);XCTAssertEqual(request.httpMethod,"GET");return(200,.object(["keysets":.array([json])])) };defer { WalletHTTPFixture.handler=nil }
        let loaded=try await client().loadMint("https://wallet-http.invalid/Bitcoin")
        XCTAssertEqual(loaded.keysets.count,1);XCTAssertTrue(loaded.keysets[0].validID);XCTAssertEqual(paths,["/Bitcoin/v1/keysets","/Bitcoin/v1/keys/"+keyset.keysetID])
    }
    func testEmptyOrMismatchedKeysetsAndHTTPFailureCannotBecomeAUsableMint() async throws {
        WalletHTTPFixture.handler={ _ in(200,.object(["keysets":.array([])])) };defer { WalletHTTPFixture.handler=nil }
        do { _=try await client().loadMint("https://wallet-http.invalid");XCTFail("Empty mint was accepted") } catch { }
        let fixture=WalletFixtureMint(),mint=try await fixture.loadMint("https://wallet-http.invalid"),raw=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(mint.keysets[0]))
        WalletHTTPFixture.handler={ request in(200,.object(["keysets":.array([request.url!.path == "/v1/keysets" ? raw : raw.setting("id",.string("00aaaaaaaaaaaaaa"))])])) }
        do { _=try await client().loadMint("https://wallet-http.invalid");XCTFail("Mismatched keys were accepted") } catch { }
        WalletHTTPFixture.handler={ _ in(503,.object(["detail":.string("Private server diagnostics must not be surfaced")])) }
        do { _=try await client().request(mint:"https://wallet-http.invalid",path:"v1/info");XCTFail("HTTP failure was accepted") } catch { XCTAssertFalse(error.localizedDescription.contains("Private server diagnostics")) }
    }
    func testRetiredKeysetsCanContainUnsignedSixtyFourBitDenominations() async throws {
        let mint=try await WalletFixtureMint().loadMint("https://wallet-http.invalid"),active=try JSONDecoder().decode(JSONValue.self,from:JSONEncoder().encode(mint.keysets[0]))
        let publicKey=mint.keysets[0].keys["1"]!,amounts=(0..<64).map { UInt64(1) << $0 },keys=Dictionary(uniqueKeysWithValues:amounts.map { (String($0),publicKey) })
        let bytes=try amounts.reduce(into:Data()) { data,_ in data.append(try CashuMintBatch.bytes(publicKey)) },id="00"+CashuMintBatch.hex(Data(SHA256.hash(data:bytes))).prefix(14)
        let retired:JSONValue = .object(["id":.string(id),"unit":.string("sat"),"active":.bool(false),"keys":.object(keys.mapValues(JSONValue.string))])
        WalletHTTPFixture.handler={ request in
            let values=request.url!.path == "/v1/keysets" ? [active,retired] : request.url!.path.hasSuffix(id) ? [retired] : [active]
            return(200,.object(["keysets":.array(values)]))
        };defer { WalletHTTPFixture.handler=nil }
        let loaded=try await client().loadMint("https://wallet-http.invalid");XCTAssertEqual(loaded.keysets.count,2);XCTAssertTrue(loaded.keysets.allSatisfy(\.validID))
    }
    func testDefaultMintMetadataAndKeysReadOnly() async throws {
        guard ProcessInfo.processInfo.environment["PIYALI_LIVE_MINT_TESTS"] == "1" else { throw XCTSkip("Read-only live mint checks require explicit opt-in.") }
        let api=CashuHTTPClient(),info=try await api.request(mint:WalletContract.defaultMint,path:"v1/info")
        XCTAssertTrue(info["nuts"]["11"]["supported"].boolean);XCTAssertTrue(info["nuts"]["12"]["supported"].boolean);XCTAssertTrue(info["nuts"]["9"]["supported"].boolean)
        let mint=try await api.loadMint(WalletContract.defaultMint);XCTAssertTrue(mint.keysets.contains { $0.active && $0.unit == "sat" });XCTAssertTrue(mint.keysets.allSatisfy(\.validID))
        print("LIVE WALLET: read-only Minibits metadata and valid sat keysets passed; no quote or payment request created")
    }
}

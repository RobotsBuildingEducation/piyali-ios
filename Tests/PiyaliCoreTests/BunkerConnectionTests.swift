import XCTest
@testable import PiyaliCore

final class BunkerConnectionTests:XCTestCase {
    private let key=String(repeating:"a",count:64)
    func testBunkerSeparatesSignerFromUserAndParsesRepeatedRelaysAndOneTimeSecret() throws {
        let connection=try BunkerConnection("bunker://\(key)?relay=wss%3A%2F%2Frelay.example%2F&relay=wss%3A%2F%2Fsecond.example&relay=wss%3A%2F%2Frelay.example%2F&secret=one%2Btime")
        XCTAssertEqual(connection.signer,key);XCTAssertEqual(connection.relays,["wss://relay.example/","wss://second.example"]);XCTAssertEqual(connection.secret,"one+time")
        XCTAssertNil(try BunkerConnection("bunker://\(key)?relay=wss://relay.example&secret=").secret)
    }
    func testMalformedTokensAndUnsafeRelayLocationsAreRejected() {
        for token in ["nostrconnect://\(key)?relay=wss://relay.example","bunker://not-a-key?relay=wss://relay.example","bunker://\(key)","bunker://\(key)?relay=https://relay.example","bunker://\(key)?relay=ws://relay.example","bunker://\(key)?relay=wss://user:password@relay.example","bunker://\(key)?relay=wss://relay.example%23fragment","bunker://\(key)?relay=wss://relay.example&secret=a&secret=b","bunker://\(key)/extra?relay=wss://relay.example","bunker://\(key)?relay=wss://relay.example#fragment"] { XCTAssertThrowsError(try BunkerConnection(token)) }
    }
    func testLoopbackIsExplicitAndNeverAllowsCleartextPublicRelays() throws {
        let token="bunker://\(key)?relay=ws://127.0.0.1:9000"
        XCTAssertThrowsError(try BunkerConnection(token));XCTAssertEqual(try BunkerConnection(token,allowLoopback:true).relays,["ws://127.0.0.1:9000"])
        XCTAssertThrowsError(try BunkerConnection("bunker://\(key)?relay=ws://public.example",allowLoopback:true))
    }
}

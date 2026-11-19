import XCTest
@testable import PiyaliCore

final class EntryPolicyTests:XCTestCase {
    func testNativeRegistrationHeaderAndSignInErrorsMatchExecutedSourceCallbacks() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/entry-policy.json"),fixture=try JSONDecoder().decode(JSONValue.self,from:Data(contentsOf:url))
        XCTAssertEqual(fixture["cases"].array.count,24);XCTAssertEqual(fixture["header"].array.count,56);XCTAssertEqual(fixture["errors"].array.count,8)
        for row in fixture["cases"].array {XCTAssertEqual(EntryPolicy.registrationName(row["displayName"].string,instant:row["instant"].boolean,busy:row["busy"].boolean),row["name"] == .null ? nil : row["name"].string)}
        for row in fixture["header"].array {let state=EntryPolicy.header(scrollY:row["scrollY"].number,heroBottom:row["heroBottom"] == .null ? nil : row["heroBottom"].number);XCTAssertEqual(state.scrolled,row["scrolled"].boolean);XCTAssertEqual(state.actions,row["actions"].boolean)}
        for row in fixture["errors"].array {XCTAssertEqual(EntryPolicy.signInError(row["message"].string),row["key"].string)}
    }
}

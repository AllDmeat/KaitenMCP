import XCTest
@testable import kaiten_mcp

final class LazyConfigTests: XCTestCase {
    func testMissingCredentialKeysForEmptyConfig() {
        let config = Config()
        XCTAssertEqual(missingCredentialKeys(in: config), ["url", "token"])
    }

    func testValidateLoginInputRejectsBlankURL() {
        XCTAssertThrowsError(try validateLoginInput(url: "   ", token: "token"))
    }

    func testValidateLoginInputRejectsBlankToken() {
        XCTAssertThrowsError(try validateLoginInput(url: "https://example.kaiten.ru/api/latest", token: " "))
    }
}

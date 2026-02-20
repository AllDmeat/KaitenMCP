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

    func testReadLogContentReturnsTailLines() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "a\nb\nc\n".write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let content = try readLogContent(path: tmp.path, tailLines: 2)
        XCTAssertEqual(content, "c\n")
    }

    func testReadLogContentReturnsEmptyForMissingFile() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let content = try readLogContent(path: path, tailLines: nil)
        XCTAssertEqual(content, "")
    }

    func testFormatArgumentKeysReturnsSortedKeyList() {
        let formatted = formatArgumentKeys(["token", "board_id", "id"])
        XCTAssertEqual(formatted, "board_id,id,token")
    }

    func testFormatArgumentKeysForEmptyArrayReturnsNone() {
        XCTAssertEqual(formatArgumentKeys([]), "none")
    }
}

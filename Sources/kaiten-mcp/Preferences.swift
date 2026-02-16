import Foundation

/// Combined response for `kaiten_get_preferences` — includes url from config + user preferences.
/// Token is intentionally excluded.
struct PreferencesResponse: Codable, Sendable {
    let url: String?
    let myBoards: [Preferences.BoardRef]?
    let mySpaces: [Preferences.SpaceRef]?
}

/// User-level preferences stored at `~/.config/kaiten-mcp/preferences.json`
/// (Linux) or `~/Library/Application Support/kaiten-mcp/preferences.json` (macOS).
///
/// Credentials (url/token) live in `config.json` — shared with CLI.
/// This file contains only MCP-specific user preferences.
struct Preferences: Codable, Sendable {
    var mySpaces: [SpaceRef]?
    var myBoards: [BoardRef]?

    struct SpaceRef: Codable, Sendable {
        let id: Int
        var alias: String?
    }

    struct BoardRef: Codable, Sendable {
        let id: Int
        var alias: String?
    }

    /// Board IDs from preferences, or `nil` if not configured.
    var boardIds: [Int]? {
        guard let boards = myBoards, !boards.isEmpty else { return nil }
        return boards.map(\.id)
    }

    /// Space IDs from preferences, or `nil` if not configured.
    var spaceIds: [Int]? {
        guard let spaces = mySpaces, !spaces.isEmpty else { return nil }
        return spaces.map(\.id)
    }

    // MARK: - File path

    /// Config directory — always `~/.config/kaiten-mcp/` on all platforms.
    /// Matches CLI (KaitenSDK) so credentials in config.json are shared.
    static var configDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/kaiten-mcp", isDirectory: true)
    }

    static var filePath: URL {
        configDirectory.appendingPathComponent("preferences.json")
    }

    // MARK: - Load

    /// Load preferences from disk. Returns empty preferences if file doesn't exist.
    static func load() -> Preferences {
        let path = filePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return Preferences()
        }
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Preferences.self, from: data)
        } catch {
            log("Warning: failed to parse preferences at \(path.path): \(error)")
            return Preferences()
        }
    }

    // MARK: - Save

    /// Save preferences to disk, creating the directory if needed.
    func save() throws {
        let dir = Preferences.configDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)
        try data.write(to: Preferences.filePath, options: .atomic)
    }
}

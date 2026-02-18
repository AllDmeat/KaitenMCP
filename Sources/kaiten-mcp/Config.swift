import Foundation

/// Shared credentials stored at `~/.config/kaiten/config.json`.
/// This file is shared between CLI (KaitenSDK) and MCP.
struct Config: Codable, Sendable {
    var url: String?
    var token: String?

    // MARK: - File path

    static var filePath: URL {
        Preferences.configDirectory.appendingPathComponent("config.json")
    }

    // MARK: - Load

    /// Load config from disk. Returns empty config if file doesn't exist.
    static func load() -> Config {
        let path = filePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return Config()
        }
        do {
            let data = try Data(contentsOf: path)
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            log("Warning: failed to parse config at \(path.path): \(error)")
            return Config()
        }
    }

    // MARK: - Save

    /// Save config to disk, creating the directory if needed. Sets 0600 permissions.
    func save() throws {
        let dir = Preferences.configDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: Config.filePath, options: .atomic)

        // Restrict permissions — file contains secrets
        #if !os(macOS)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: Config.filePath.path
        )
        #endif
    }
}

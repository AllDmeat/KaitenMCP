import Foundation
import KaitenSDK
import MCP

// MARK: - Logging

let logFilePath = NSTemporaryDirectory() + "kaiten-mcp.log"

let logFile: FileHandle? = {
  FileManager.default.createFile(atPath: logFilePath, contents: nil)
  return FileHandle(forWritingAtPath: logFilePath)
}()

func log(_ message: String) {
  let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)\n"
  logFile?.seekToEndOfFile()
  logFile?.write(Data(line.utf8))
}

// MARK: - Configuration

func exitWithError(_ message: String) -> Never {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
  log("FATAL: \(message)")
  exit(1)
}

log("Starting KaitenMCP...")

let config = Config.load()
log(
  "Config loaded from \(Config.filePath.path): url=\(config.url != nil ? "set" : "NOT SET"), token=\(config.token != nil ? "set" : "NOT SET")"
)
log(
  "Preferences loaded from \(Preferences.filePath.path)"
)

// MARK: - MCP Server

let server = Server(
  name: "KaitenMCP",
  version: "1.3.0",
  capabilities: .init(
    tools: .init(listChanged: false)
  )
)

// MARK: - Tool Definitions

// Tool definitions are declared in Sources/kaiten-mcp/Tools/**


// MARK: - Handlers

await server.withMethodHandler(ListTools.self) { _ in
  .init(tools: allTools)
}

await server.withMethodHandler(CallTool.self) { params in
  await handleToolCall(params)
}

// MARK: - Start

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()

// MARK: - Helpers

enum ToolError: Error, CustomStringConvertible {
  case missingArgument(String)
  case invalidType(key: String, expected: String)
  case missingCredentials([String])
  case invalidCredentials(String)
  case unknownTool(String)

  var description: String {
    switch self {
    case .missingArgument(let key):
      return "Missing required argument: \(key)"
    case .invalidType(let key, let expected):
      return "Invalid type for '\(key)': expected \(expected)"
    case .missingCredentials(let keys):
      let missing = keys.joined(separator: ", ")
      return
        "Missing credentials in \(Config.filePath.path): \(missing). Run kaiten_login with url and token."
    case .invalidCredentials(let message):
      return "Invalid credentials input: \(message)"
    case .unknownTool(let name):
      return "Unknown tool: \(name)"
    }
  }
}

@Sendable func missingCredentialKeys(in config: Config) -> [String] {
  var missing: [String] = []
  if (config.url?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
    missing.append("url")
  }
  if (config.token?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
    missing.append("token")
  }
  return missing
}

@Sendable func validateLoginInput(url: String, token: String) throws {
  let normalizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
  let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

  guard !normalizedURL.isEmpty else {
    throw ToolError.invalidCredentials("url must not be empty")
  }
  guard !normalizedToken.isEmpty else {
    throw ToolError.invalidCredentials("token must not be empty")
  }
  guard let parsed = URL(string: normalizedURL), parsed.scheme != nil, parsed.host != nil else {
    throw ToolError.invalidCredentials("url must be an absolute URL")
  }
}

@Sendable func makeConfiguredKaitenClient() throws -> KaitenClient {
  let config = Config.load()
  let missing = missingCredentialKeys(in: config)
  guard missing.isEmpty else {
    log("Credentials missing in config: \(missing.joined(separator: ","))")
    throw ToolError.missingCredentials(missing)
  }
  return try KaitenClient(
    baseURL: config.url!.trimmingCharacters(in: .whitespacesAndNewlines),
    token: config.token!.trimmingCharacters(in: .whitespacesAndNewlines)
  )
}

@Sendable func readLogContent(path: String, tailLines: Int?) throws -> String {
  guard FileManager.default.fileExists(atPath: path) else {
    log("Log file not found at \(path), returning empty log content")
    return ""
  }
  let content = try String(contentsOfFile: path, encoding: .utf8)
  guard let tailLines else {
    return content
  }
  return content
    .split(separator: "\n", omittingEmptySubsequences: false)
    .suffix(tailLines)
    .joined(separator: "\n")
}

@Sendable func formatArgumentKeys(_ keys: [String]) -> String {
  guard !keys.isEmpty else { return "none" }
  return keys.sorted().joined(separator: ",")
}

@Sendable func elapsedMilliseconds(since start: Date) -> Int {
  Int(Date().timeIntervalSince(start) * 1000)
}

@Sendable func requireInt(_ params: CallTool.Parameters, key: String) throws -> Int {
  guard let value = params.arguments?[key] else {
    throw ToolError.missingArgument(key)
  }
  if let intVal = value.intValue {
    return intVal
  }
  if let doubleVal = value.doubleValue {
    return Int(doubleVal)
  }
  throw ToolError.invalidType(key: key, expected: "integer")
}

@Sendable func requireString(_ params: CallTool.Parameters, key: String) throws -> String {
  guard let value = params.arguments?[key] else {
    throw ToolError.missingArgument(key)
  }
  guard let str = value.stringValue else {
    throw ToolError.invalidType(key: key, expected: "string")
  }
  return str
}

@Sendable func optionalInt(_ params: CallTool.Parameters, key: String) -> Int? {
  guard let value = params.arguments?[key] else { return nil }
  return value.intValue ?? value.doubleValue.map(Int.init)
}

@Sendable func optionalString(_ params: CallTool.Parameters, key: String) -> String? {
  params.arguments?[key]?.stringValue
}

@Sendable func optionalDouble(_ params: CallTool.Parameters, key: String) -> Double? {
  guard let value = params.arguments?[key] else { return nil }
  return value.doubleValue ?? value.intValue.map(Double.init)
}

@Sendable func optionalBool(_ params: CallTool.Parameters, key: String) -> Bool? {
  params.arguments?[key]?.boolValue
}

@Sendable func requireIntArray(_ params: CallTool.Parameters, key: String) throws -> [Int] {
  guard let value = params.arguments?[key] else {
    throw ToolError.missingArgument(key)
  }
  guard let arr = value.arrayValue else {
    throw ToolError.invalidType(key: key, expected: "array")
  }
  return arr.compactMap { $0.intValue ?? $0.doubleValue.map(Int.init) }
}

@Sendable func jsonValueToAny(_ value: Value) -> Any {
  switch value {
  case .null:
    return NSNull()
  case .bool(let b):
    return b
  case .int(let i):
    return i
  case .double(let d):
    return d
  case .string(let s):
    return s
  case .array(let arr):
    return arr.map { jsonValueToAny($0) }
  case .object(let obj):
    return obj.mapValues { jsonValueToAny($0) }
  case .data(_, let data):
    return data.base64EncodedString()
  }
}

@Sendable func toJSON(_ value: some Encodable) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  guard let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) else {
    return "{\"error\": \"Failed to encode response\"}"
  }
  return str
}

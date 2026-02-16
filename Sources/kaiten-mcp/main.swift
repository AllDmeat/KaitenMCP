import Foundation
import KaitenSDK
import MCP

// MARK: - Logging

let logFile: FileHandle? = {
    let path = NSTemporaryDirectory() + "kaiten-mcp.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
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

let preferences = Preferences.load()
log("Preferences loaded from \(Preferences.filePath.path): boards=\(preferences.boardIds?.description ?? "none"), spaces=\(preferences.spaceIds?.description ?? "none")")

log("Config: KAITEN_URL=\(preferences.url != nil ? "set" : "NOT SET"), KAITEN_TOKEN=\(preferences.token != nil ? "set" : "NOT SET")")

guard let kaitenURL = preferences.url else {
    exitWithError("Error: KAITEN_URL not set in config. Run kaiten_set_token tool or edit \(Preferences.filePath.path)")
}

guard let kaitenToken = preferences.token else {
    exitWithError("Error: KAITEN_TOKEN not set in config. Run kaiten_set_token tool or edit \(Preferences.filePath.path)")
}

// Set env vars so KaitenClient picks them up
setenv("KAITEN_URL", kaitenURL, 1)
setenv("KAITEN_TOKEN", kaitenToken, 1)

let kaiten = try KaitenClient()
log("KaitenClient initialized successfully")

// MARK: - MCP Server

let server = Server(
    name: "KaitenMCP",
    version: "0.1.0",
    capabilities: .init(
        tools: .init(listChanged: false)
    )
)

// MARK: - Tool Definitions

let allTools: [Tool] = [
    // Cards
    Tool(
        name: "kaiten_list_cards",
        description: "List all cards on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object([
                    "type": "integer",
                    "description": "Board ID to list cards from",
                ]),
            ]),
            "required": .array(["board_id"]),
        ])
    ),
    Tool(
        name: "kaiten_get_card",
        description: "Get a single card by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object([
                    "type": "integer",
                    "description": "Card ID",
                ]),
            ]),
            "required": .array(["id"]),
        ])
    ),
    Tool(
        name: "kaiten_get_card_members",
        description: "Get members of a card",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "card_id": .object([
                    "type": "integer",
                    "description": "Card ID",
                ]),
            ]),
            "required": .array(["card_id"]),
        ])
    ),

    // Spaces & Boards
    Tool(
        name: "kaiten_list_spaces",
        description: "List all spaces",
        inputSchema: .object([
            "type": "object",
            "properties": .object([:]),
        ])
    ),
    Tool(
        name: "kaiten_list_boards",
        description: "List boards in a space",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "space_id": .object([
                    "type": "integer",
                    "description": "Space ID",
                ]),
            ]),
            "required": .array(["space_id"]),
        ])
    ),
    Tool(
        name: "kaiten_get_board",
        description: "Get a board by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object([
                    "type": "integer",
                    "description": "Board ID",
                ]),
            ]),
            "required": .array(["id"]),
        ])
    ),
    Tool(
        name: "kaiten_get_board_columns",
        description: "Get columns of a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object([
                    "type": "integer",
                    "description": "Board ID",
                ]),
            ]),
            "required": .array(["board_id"]),
        ])
    ),
    Tool(
        name: "kaiten_get_board_lanes",
        description: "Get lanes of a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object([
                    "type": "integer",
                    "description": "Board ID",
                ]),
            ]),
            "required": .array(["board_id"]),
        ])
    ),

    // Custom Properties
    Tool(
        name: "kaiten_list_custom_properties",
        description: "List all custom property definitions",
        inputSchema: .object([
            "type": "object",
            "properties": .object([:]),
        ])
    ),
    Tool(
        name: "kaiten_get_custom_property",
        description: "Get a custom property definition by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object([
                    "type": "integer",
                    "description": "Custom property ID",
                ]),
            ]),
            "required": .array(["id"]),
        ])
    ),

    // Preferences
    Tool(
        name: "kaiten_get_preferences",
        description: "Get current user preferences (configured boards, spaces). Returns the content of the user-level config file.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([:]),
        ])
    ),
    Tool(
        name: "kaiten_configure",
        description: "Manage user preferences (personal boards/spaces). Actions: get, set_boards, set_spaces, add_board, remove_board, add_space, remove_space",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "action": .object([
                    "type": "string",
                    "description": "Action to perform",
                    "enum": .array(["get", "set_boards", "set_spaces", "add_board", "remove_board", "add_space", "remove_space"]),
                ]),
                "ids": .object([
                    "type": "array",
                    "description": "Array of IDs (for set_boards, set_spaces)",
                    "items": .object(["type": "integer"]),
                ]),
                "id": .object([
                    "type": "integer",
                    "description": "Single ID (for add/remove operations)",
                ]),
                "alias": .object([
                    "type": "string",
                    "description": "Optional alias/name for the board or space",
                ]),
            ]),
            "required": .array(["action"]),
        ])
    ),
    Tool(
        name: "kaiten_set_token",
        description: "Store Kaiten API token and URL in user config. Token is saved securely with restricted file permissions (0600). Env vars always override config.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "token": .object([
                    "type": "string",
                    "description": "Kaiten API token",
                ]),
                "url": .object([
                    "type": "string",
                    "description": "Kaiten API base URL (e.g. https://mycompany.kaiten.ru)",
                ]),
            ]),
        ])
    ),
]

// MARK: - Handlers

await server.withMethodHandler(ListTools.self) { _ in
    .init(tools: allTools)
}

await server.withMethodHandler(CallTool.self) { params in
    do {
        let json: String = try await {
            switch params.name {
            case "kaiten_list_cards":
                let boardId = try requireInt(params, key: "board_id")
                let cards = try await kaiten.listCards(boardId: boardId)
                return toJSON(cards)

            case "kaiten_get_card":
                let id = try requireInt(params, key: "id")
                let card = try await kaiten.getCard(id: id)
                return toJSON(card)

            case "kaiten_get_card_members":
                let cardId = try requireInt(params, key: "card_id")
                let members = try await kaiten.getCardMembers(cardId: cardId)
                return toJSON(members)

            case "kaiten_list_spaces":
                let spaces = try await kaiten.listSpaces()
                return toJSON(spaces)

            case "kaiten_list_boards":
                let spaceId = try requireInt(params, key: "space_id")
                let boards = try await kaiten.listBoards(spaceId: spaceId)
                return toJSON(boards)

            case "kaiten_get_board":
                let id = try requireInt(params, key: "id")
                let board = try await kaiten.getBoard(id: id)
                return toJSON(board)

            case "kaiten_get_board_columns":
                let boardId = try requireInt(params, key: "board_id")
                let columns = try await kaiten.getBoardColumns(boardId: boardId)
                return toJSON(columns)

            case "kaiten_get_board_lanes":
                let boardId = try requireInt(params, key: "board_id")
                let lanes = try await kaiten.getBoardLanes(boardId: boardId)
                return toJSON(lanes)

            case "kaiten_list_custom_properties":
                let props = try await kaiten.listCustomProperties()
                return toJSON(props)

            case "kaiten_get_custom_property":
                let id = try requireInt(params, key: "id")
                let prop = try await kaiten.getCustomProperty(id: id)
                return toJSON(prop)

            case "kaiten_get_preferences":
                return toJSON(preferences)

            case "kaiten_set_token":
                var prefs = Preferences.load()
                if let token = optionalString(params, key: "token") {
                    prefs.token = token
                }
                if let url = optionalString(params, key: "url") {
                    prefs.url = url
                }
                try prefs.save()
                // Mask token in response
                var response = prefs
                if let t = response.token {
                    let masked = String(t.prefix(4)) + String(repeating: "*", count: max(0, t.count - 4))
                    response.token = masked
                }
                return toJSON(response)

            case "kaiten_configure":
                let action = try requireString(params, key: "action")
                var prefs = Preferences.load()

                switch action {
                case "get":
                    return toJSON(prefs)

                case "set_boards":
                    let ids = try requireIntArray(params, key: "ids")
                    prefs.myBoards = ids.map { Preferences.BoardRef(id: $0) }
                    try prefs.save()
                    return toJSON(prefs)

                case "set_spaces":
                    let ids = try requireIntArray(params, key: "ids")
                    prefs.mySpaces = ids.map { Preferences.SpaceRef(id: $0) }
                    try prefs.save()
                    return toJSON(prefs)

                case "add_board":
                    let id = try requireInt(params, key: "id")
                    let alias = optionalString(params, key: "alias")
                    var boards = prefs.myBoards ?? []
                    if !boards.contains(where: { $0.id == id }) {
                        boards.append(Preferences.BoardRef(id: id, alias: alias))
                    }
                    prefs.myBoards = boards
                    try prefs.save()
                    return toJSON(prefs)

                case "remove_board":
                    let id = try requireInt(params, key: "id")
                    prefs.myBoards?.removeAll(where: { $0.id == id })
                    try prefs.save()
                    return toJSON(prefs)

                case "add_space":
                    let id = try requireInt(params, key: "id")
                    let alias = optionalString(params, key: "alias")
                    var spaces = prefs.mySpaces ?? []
                    if !spaces.contains(where: { $0.id == id }) {
                        spaces.append(Preferences.SpaceRef(id: id, alias: alias))
                    }
                    prefs.mySpaces = spaces
                    try prefs.save()
                    return toJSON(prefs)

                case "remove_space":
                    let id = try requireInt(params, key: "id")
                    prefs.mySpaces?.removeAll(where: { $0.id == id })
                    try prefs.save()
                    return toJSON(prefs)

                default:
                    throw ToolError.invalidType(
                        key: "action",
                        expected: "one of: get, set_boards, set_spaces, add_board, remove_board, add_space, remove_space"
                    )
                }

            default:
                throw ToolError.unknownTool(params.name)
            }
        }()
        return .init(content: [.text(json)], isError: false)
    } catch let error as ToolError {
        return .init(content: [.text(error.description)], isError: true)
    } catch {
        return .init(content: [.text("Error: \(error)")], isError: true)
    }
}

// MARK: - Start

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()

// MARK: - Helpers

enum ToolError: Error, CustomStringConvertible {
    case missingArgument(String)
    case invalidType(key: String, expected: String)
    case unknownTool(String)

    var description: String {
        switch self {
        case .missingArgument(let key):
            "Missing required argument: \(key)"
        case .invalidType(let key, let expected):
            "Invalid type for '\(key)': expected \(expected)"
        case .unknownTool(let name):
            "Unknown tool: \(name)"
        }
    }
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

@Sendable func optionalString(_ params: CallTool.Parameters, key: String) -> String? {
    params.arguments?[key]?.stringValue
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

@Sendable func toJSON(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) else {
        return "{\"error\": \"Failed to encode response\"}"
    }
    return str
}

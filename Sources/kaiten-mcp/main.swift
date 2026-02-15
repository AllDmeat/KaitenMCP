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
log("Environment: KAITEN_URL=\(ProcessInfo.processInfo.environment["KAITEN_URL"] != nil ? "set" : "NOT SET"), KAITEN_TOKEN=\(ProcessInfo.processInfo.environment["KAITEN_TOKEN"] != nil ? "set" : "NOT SET")")

guard ProcessInfo.processInfo.environment["KAITEN_URL"] != nil else {
    exitWithError("Error: KAITEN_URL environment variable is not set")
}

guard ProcessInfo.processInfo.environment["KAITEN_TOKEN"] != nil else {
    exitWithError("Error: KAITEN_TOKEN environment variable is not set")
}

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

@Sendable func toJSON(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) else {
        return "{\"error\": \"Failed to encode response\"}"
    }
    return str
}

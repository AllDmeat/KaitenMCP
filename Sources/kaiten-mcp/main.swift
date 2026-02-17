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

let config = Config.load()
let preferences = Preferences.load()
log("Config loaded from \(Config.filePath.path): url=\(config.url != nil ? "set" : "NOT SET"), token=\(config.token != nil ? "set" : "NOT SET")")
log("Preferences loaded from \(Preferences.filePath.path): boards=\(preferences.boardIds?.description ?? "none"), spaces=\(preferences.spaceIds?.description ?? "none")")

guard let kaitenURL = config.url else {
    exitWithError("Error: url not set. Run kaiten_set_token tool or edit \(Config.filePath.path)")
}

guard let kaitenToken = config.token else {
    exitWithError("Error: token not set. Run kaiten_set_token tool or edit \(Config.filePath.path)")
}

let kaiten = try KaitenClient(baseURL: kaitenURL, token: kaitenToken)
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
        description: "List cards (paginated, max 100 per page). Supports 40+ filter parameters.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID to list cards from"]),
                "column_id": .object(["type": "integer", "description": "Column ID filter"]),
                "lane_id": .object(["type": "integer", "description": "Lane ID filter"]),
                "offset": .object(["type": "integer", "description": "Number of cards to skip (default: 0)"]),
                "limit": .object(["type": "integer", "description": "Max cards to return (default/max: 100)"]),
                "created_before": .object(["type": "string", "description": "ISO 8601 date — cards created before"]),
                "created_after": .object(["type": "string", "description": "ISO 8601 date — cards created after"]),
                "updated_before": .object(["type": "string", "description": "ISO 8601 date — cards updated before"]),
                "updated_after": .object(["type": "string", "description": "ISO 8601 date — cards updated after"]),
                "first_moved_in_progress_after": .object(["type": "string", "description": "ISO 8601 date filter"]),
                "first_moved_in_progress_before": .object(["type": "string", "description": "ISO 8601 date filter"]),
                "last_moved_to_done_at_after": .object(["type": "string", "description": "ISO 8601 date filter"]),
                "last_moved_to_done_at_before": .object(["type": "string", "description": "ISO 8601 date filter"]),
                "due_date_after": .object(["type": "string", "description": "ISO 8601 date — due date after"]),
                "due_date_before": .object(["type": "string", "description": "ISO 8601 date — due date before"]),
                "query": .object(["type": "string", "description": "Text search"]),
                "search_fields": .object(["type": "string", "description": "Comma-separated fields to search"]),
                "tag": .object(["type": "string", "description": "Tag name filter"]),
                "tag_ids": .object(["type": "string", "description": "Comma-separated tag IDs"]),
                "type_id": .object(["type": "integer", "description": "Card type ID"]),
                "type_ids": .object(["type": "string", "description": "Comma-separated type IDs"]),
                "member_ids": .object(["type": "string", "description": "Comma-separated member IDs"]),
                "owner_id": .object(["type": "integer", "description": "Owner ID"]),
                "owner_ids": .object(["type": "string", "description": "Comma-separated owner IDs"]),
                "responsible_id": .object(["type": "integer", "description": "Responsible person ID"]),
                "responsible_ids": .object(["type": "string", "description": "Comma-separated responsible IDs"]),
                "column_ids": .object(["type": "string", "description": "Comma-separated column IDs"]),
                "space_id": .object(["type": "integer", "description": "Space ID filter"]),
                "external_id": .object(["type": "string", "description": "External ID filter"]),
                "organizations_ids": .object(["type": "string", "description": "Comma-separated organization IDs"]),
                "exclude_board_ids": .object(["type": "string", "description": "Exclude these board IDs"]),
                "exclude_lane_ids": .object(["type": "string", "description": "Exclude these lane IDs"]),
                "exclude_column_ids": .object(["type": "string", "description": "Exclude these column IDs"]),
                "exclude_owner_ids": .object(["type": "string", "description": "Exclude these owner IDs"]),
                "exclude_card_ids": .object(["type": "string", "description": "Exclude these card IDs"]),
                "condition": .object(["type": "integer", "description": "Card condition: 1=queued, 2=in progress, 3=done"]),
                "states": .object(["type": "string", "description": "Comma-separated states"]),
                "archived": .object(["type": "boolean", "description": "Filter by archived status"]),
                "asap": .object(["type": "boolean", "description": "Filter ASAP cards"]),
                "overdue": .object(["type": "boolean", "description": "Filter overdue cards"]),
                "done_on_time": .object(["type": "boolean", "description": "Filter done-on-time cards"]),
                "with_due_date": .object(["type": "boolean", "description": "Filter cards with due date"]),
                "is_request": .object(["type": "boolean", "description": "Filter service desk requests"]),
                "order_by": .object(["type": "string", "description": "Sort field"]),
                "order_direction": .object(["type": "string", "description": "Sort direction (asc/desc)"]),
                "order_space_id": .object(["type": "integer", "description": "Space ID for ordering"]),
                "additional_card_fields": .object(["type": "string", "description": "Extra fields to include"]),
            ]),
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

    Tool(
        name: "kaiten_get_card_comments",
        description: "Get comments on a card",
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
    Tool(
        name: "kaiten_create_comment",
        description: "Add a comment to a card",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "card_id": .object(["type": "integer", "description": "Card ID"]),
                "text": .object(["type": "string", "description": "Comment text (markdown)"]),
            ]),
            "required": .array(["card_id", "text"]),
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
                "condition": .object([
                    "type": "integer",
                    "description": "Lane condition: 1=queued, 2=in progress, 3=done",
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
            "properties": .object([
                "offset": .object(["type": "integer", "description": "Number of items to skip (default: 0)"]),
                "limit": .object(["type": "integer", "description": "Max items to return (default: 100)"]),
                "query": .object(["type": "string", "description": "Search query"]),
                "include_values": .object(["type": "boolean", "description": "Include property values"]),
                "include_author": .object(["type": "boolean", "description": "Include author info"]),
                "compact": .object(["type": "boolean", "description": "Compact response"]),
                "load_by_ids": .object(["type": "boolean", "description": "Load by IDs mode"]),
                "ids": .object(["type": "array", "description": "Array of property IDs to load", "items": .object(["type": "integer"])]),
                "order_by": .object(["type": "string", "description": "Sort field"]),
                "order_direction": .object(["type": "string", "description": "Sort direction (asc/desc)"]),
            ]),
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
                let boardId = optionalInt(params, key: "board_id")
                let columnId = optionalInt(params, key: "column_id")
                let laneId = optionalInt(params, key: "lane_id")
                let offset = optionalInt(params, key: "offset") ?? 0
                let limit = optionalInt(params, key: "limit") ?? 100

                // Date parsing helper
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let iso2 = ISO8601DateFormatter()
                iso2.formatOptions = [.withInternetDateTime]
                func parseDate(_ key: String) -> Date? {
                    guard let s = optionalString(params, key: key) else { return nil }
                    return iso.date(from: s) ?? iso2.date(from: s)
                }

                let filter = KaitenClient.CardFilter(
                    createdBefore: parseDate("created_before"),
                    createdAfter: parseDate("created_after"),
                    updatedBefore: parseDate("updated_before"),
                    updatedAfter: parseDate("updated_after"),
                    firstMovedInProgressAfter: parseDate("first_moved_in_progress_after"),
                    firstMovedInProgressBefore: parseDate("first_moved_in_progress_before"),
                    lastMovedToDoneAtAfter: parseDate("last_moved_to_done_at_after"),
                    lastMovedToDoneAtBefore: parseDate("last_moved_to_done_at_before"),
                    dueDateAfter: parseDate("due_date_after"),
                    dueDateBefore: parseDate("due_date_before"),
                    query: optionalString(params, key: "query"),
                    searchFields: optionalString(params, key: "search_fields"),
                    tag: optionalString(params, key: "tag"),
                    tagIds: optionalString(params, key: "tag_ids"),
                    typeId: optionalInt(params, key: "type_id"),
                    typeIds: optionalString(params, key: "type_ids"),
                    memberIds: optionalString(params, key: "member_ids"),
                    ownerId: optionalInt(params, key: "owner_id"),
                    ownerIds: optionalString(params, key: "owner_ids"),
                    responsibleId: optionalInt(params, key: "responsible_id"),
                    responsibleIds: optionalString(params, key: "responsible_ids"),
                    columnIds: optionalString(params, key: "column_ids"),
                    spaceId: optionalInt(params, key: "space_id"),
                    externalId: optionalString(params, key: "external_id"),
                    organizationsIds: optionalString(params, key: "organizations_ids"),
                    excludeBoardIds: optionalString(params, key: "exclude_board_ids"),
                    excludeLaneIds: optionalString(params, key: "exclude_lane_ids"),
                    excludeColumnIds: optionalString(params, key: "exclude_column_ids"),
                    excludeOwnerIds: optionalString(params, key: "exclude_owner_ids"),
                    excludeCardIds: optionalString(params, key: "exclude_card_ids"),
                    condition: optionalInt(params, key: "condition"),
                    states: optionalString(params, key: "states"),
                    archived: optionalBool(params, key: "archived"),
                    asap: optionalBool(params, key: "asap"),
                    overdue: optionalBool(params, key: "overdue"),
                    doneOnTime: optionalBool(params, key: "done_on_time"),
                    withDueDate: optionalBool(params, key: "with_due_date"),
                    isRequest: optionalBool(params, key: "is_request"),
                    orderBy: optionalString(params, key: "order_by"),
                    orderDirection: optionalString(params, key: "order_direction"),
                    orderSpaceId: optionalInt(params, key: "order_space_id"),
                    additionalCardFields: optionalString(params, key: "additional_card_fields")
                )

                let page = try await kaiten.listCards(boardId: boardId, columnId: columnId, laneId: laneId, offset: offset, limit: limit, filter: filter)
                return toJSON(page)

            case "kaiten_get_card":
                let id = try requireInt(params, key: "id")
                let card = try await kaiten.getCard(id: id)
                return toJSON(card)

            case "kaiten_get_card_members":
                let cardId = try requireInt(params, key: "card_id")
                let members = try await kaiten.getCardMembers(cardId: cardId)
                return toJSON(members)

            case "kaiten_get_card_comments":
                let cardId = try requireInt(params, key: "card_id")
                let comments = try await kaiten.getCardComments(cardId: cardId)
                return toJSON(comments)

            case "kaiten_create_comment":
                let cardId = try requireInt(params, key: "card_id")
                let text = try requireString(params, key: "text")
                let comment = try await kaiten.createComment(cardId: cardId, text: text)
                return toJSON(comment)

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
                let condition = optionalInt(params, key: "condition")
                let lanes = try await kaiten.getBoardLanes(boardId: boardId, condition: condition)
                return toJSON(lanes)

            case "kaiten_list_custom_properties":
                let offset = optionalInt(params, key: "offset") ?? 0
                let limit = optionalInt(params, key: "limit") ?? 100
                let query = optionalString(params, key: "query")
                let includeValues = optionalBool(params, key: "include_values")
                let includeAuthor = optionalBool(params, key: "include_author")
                let compact = optionalBool(params, key: "compact")
                let loadByIds = optionalBool(params, key: "load_by_ids")
                let ids: [Int]? = (params.arguments?["ids"]?.arrayValue != nil) ? try requireIntArray(params, key: "ids") : nil
                let orderBy = optionalString(params, key: "order_by")
                let orderDirection = optionalString(params, key: "order_direction")
                let props = try await kaiten.listCustomProperties(offset: offset, limit: limit, query: query, includeValues: includeValues, includeAuthor: includeAuthor, compact: compact, loadByIds: loadByIds, ids: ids, orderBy: orderBy, orderDirection: orderDirection)
                return toJSON(props)

            case "kaiten_get_custom_property":
                let id = try requireInt(params, key: "id")
                let prop = try await kaiten.getCustomProperty(id: id)
                return toJSON(prop)

            case "kaiten_get_preferences":
                let response = PreferencesResponse(
                    url: config.url,
                    myBoards: preferences.myBoards,
                    mySpaces: preferences.mySpaces
                )
                return toJSON(response)

            case "kaiten_set_token":
                var cfg = Config.load()
                if let token = optionalString(params, key: "token") {
                    cfg.token = token
                }
                if let url = optionalString(params, key: "url") {
                    cfg.url = url
                }
                try cfg.save()
                // Mask token in response
                var response = cfg
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

@Sendable func optionalInt(_ params: CallTool.Parameters, key: String) -> Int? {
    guard let value = params.arguments?[key] else { return nil }
    return value.intValue ?? value.doubleValue.map(Int.init)
}

@Sendable func optionalString(_ params: CallTool.Parameters, key: String) -> String? {
    params.arguments?[key]?.stringValue
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

@Sendable func toJSON(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) else {
        return "{\"error\": \"Failed to encode response\"}"
    }
    return str
}

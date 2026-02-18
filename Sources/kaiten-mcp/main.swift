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
                "archived": .object(["type": "boolean", "description": "Filter by archived status (default: false — only non-archived cards)"]),
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
        name: "kaiten_update_card",
        description: "Update an existing card by ID. All fields except id are optional — only provided fields will be updated.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object(["type": "integer", "description": "Card ID (required)"]),
                "title": .object(["type": "string", "description": "New title"]),
                "description": .object(["type": "string", "description": "New description (markdown)"]),
                "asap": .object(["type": "boolean", "description": "Mark as ASAP"]),
                "due_date": .object(["type": "string", "description": "Due date (ISO 8601)"]),
                "due_date_time_present": .object(["type": "boolean", "description": "Whether due date includes time"]),
                "sort_order": .object(["type": "number", "description": "Sort order"]),
                "expires_later": .object(["type": "boolean", "description": "Expires later flag"]),
                "size_text": .object(["type": "string", "description": "Size text"]),
                "board_id": .object(["type": "integer", "description": "Move to board ID"]),
                "column_id": .object(["type": "integer", "description": "Move to column ID"]),
                "lane_id": .object(["type": "integer", "description": "Move to lane ID"]),
                "owner_id": .object(["type": "integer", "description": "Owner user ID"]),
                "type_id": .object(["type": "integer", "description": "Card type ID"]),
                "service_id": .object(["type": "integer", "description": "Service ID"]),
                "blocked": .object(["type": "boolean", "description": "Blocked flag"]),
                "condition": .object(["type": "integer", "description": "Condition: 1=queued, 2=in progress, 3=done"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
                "text_format_type_id": .object(["type": "integer", "description": "Text format type ID"]),
                "sd_new_comment": .object(["type": "boolean", "description": "Service desk new comment flag"]),
                "owner_email": .object(["type": "string", "description": "Owner email address"]),
                "prev_card_id": .object(["type": "integer", "description": "Previous card ID for repositioning"]),
                "estimate_workload": .object(["type": "number", "description": "Estimated workload"]),
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
        name: "kaiten_create_card",
        description: "Create a new card on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "title": .object(["type": "string", "description": "Card title"]),
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "column_id": .object(["type": "integer", "description": "Column ID"]),
                "lane_id": .object(["type": "integer", "description": "Lane ID"]),
                "description": .object(["type": "string", "description": "Card description (markdown)"]),
                "asap": .object(["type": "boolean", "description": "Mark as ASAP"]),
                "due_date": .object(["type": "string", "description": "Due date (ISO 8601)"]),
                "due_date_time_present": .object(["type": "boolean", "description": "Whether due_date includes time"]),
                "sort_order": .object(["type": "number", "description": "Sort order"]),
                "expires_later": .object(["type": "boolean", "description": "Expires later flag"]),
                "size_text": .object(["type": "string", "description": "Size text"]),
                "owner_id": .object(["type": "integer", "description": "Owner user ID"]),
                "responsible_id": .object(["type": "integer", "description": "Responsible user ID"]),
                "owner_email": .object(["type": "string", "description": "Owner email"]),
                "position": .object(["type": "integer", "description": "Position"]),
                "type_id": .object(["type": "integer", "description": "Card type ID"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
            ]),
            "required": .array(["title", "board_id"]),
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
    // Sprint
    Tool(
        name: "kaiten_get_sprint_summary",
        description: "Get sprint summary by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object(["type": "integer", "description": "Sprint ID"]),
                "exclude_deleted_cards": .object(["type": "boolean", "description": "Exclude deleted cards from summary"]),
            ]),
            "required": .array(["id"]),
        ])
    ),

    // Spaces CRUD
    Tool(
        name: "kaiten_create_space",
        description: "Create a new space",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "title": .object(["type": "string", "description": "Space title"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
            ]),
            "required": .array(["title"]),
        ])
    ),
    Tool(
        name: "kaiten_get_space",
        description: "Get a space by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object(["type": "integer", "description": "Space ID"]),
            ]),
            "required": .array(["id"]),
        ])
    ),
    Tool(
        name: "kaiten_update_space",
        description: "Update a space by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object(["type": "integer", "description": "Space ID"]),
                "title": .object(["type": "string", "description": "New title"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "access": .object(["type": "integer", "description": "Access level"]),
                "parent_entity_uid": .object(["type": "string", "description": "Parent entity UID"]),
            ]),
            "required": .array(["id"]),
        ])
    ),
    Tool(
        name: "kaiten_delete_space",
        description: "Delete a space by ID",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "id": .object(["type": "integer", "description": "Space ID"]),
            ]),
            "required": .array(["id"]),
        ])
    ),

    // Boards CRUD
    Tool(
        name: "kaiten_create_board",
        description: "Create a new board in a space",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "space_id": .object(["type": "integer", "description": "Space ID"]),
                "title": .object(["type": "string", "description": "Board title"]),
                "description": .object(["type": "string", "description": "Board description"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
            ]),
            "required": .array(["space_id", "title"]),
        ])
    ),
    Tool(
        name: "kaiten_update_board",
        description: "Update a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "space_id": .object(["type": "integer", "description": "Space ID"]),
                "id": .object(["type": "integer", "description": "Board ID"]),
                "title": .object(["type": "string", "description": "New title"]),
                "description": .object(["type": "string", "description": "New description"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "external_id": .object(["type": "string", "description": "External ID"]),
            ]),
            "required": .array(["space_id", "id"]),
        ])
    ),
    Tool(
        name: "kaiten_delete_board",
        description: "Delete a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "space_id": .object(["type": "integer", "description": "Space ID"]),
                "id": .object(["type": "integer", "description": "Board ID"]),
            ]),
            "required": .array(["space_id", "id"]),
        ])
    ),

    // Columns CRUD
    Tool(
        name: "kaiten_create_column",
        description: "Create a column on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "title": .object(["type": "string", "description": "Column title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "type": .object(["type": "integer", "description": "Column type"]),
                "wip_limit": .object(["type": "integer", "description": "WIP limit"]),
                "wip_limit_type": .object(["type": "string", "description": "WIP limit type"]),
                "col_count": .object(["type": "integer", "description": "Column count"]),
            ]),
            "required": .array(["board_id", "title"]),
        ])
    ),
    Tool(
        name: "kaiten_update_column",
        description: "Update a column on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "id": .object(["type": "integer", "description": "Column ID"]),
                "title": .object(["type": "string", "description": "New title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "type": .object(["type": "integer", "description": "Column type"]),
                "wip_limit": .object(["type": "integer", "description": "WIP limit"]),
                "wip_limit_type": .object(["type": "string", "description": "WIP limit type"]),
                "col_count": .object(["type": "integer", "description": "Column count"]),
            ]),
            "required": .array(["board_id", "id"]),
        ])
    ),
    Tool(
        name: "kaiten_delete_column",
        description: "Delete a column from a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "id": .object(["type": "integer", "description": "Column ID"]),
            ]),
            "required": .array(["board_id", "id"]),
        ])
    ),

    // Subcolumns
    Tool(
        name: "kaiten_list_subcolumns",
        description: "List subcolumns of a column",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "column_id": .object(["type": "integer", "description": "Column ID"]),
            ]),
            "required": .array(["column_id"]),
        ])
    ),
    Tool(
        name: "kaiten_create_subcolumn",
        description: "Create a subcolumn",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "column_id": .object(["type": "integer", "description": "Column ID"]),
                "title": .object(["type": "string", "description": "Subcolumn title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "type": .object(["type": "integer", "description": "Subcolumn type"]),
            ]),
            "required": .array(["column_id", "title"]),
        ])
    ),
    Tool(
        name: "kaiten_update_subcolumn",
        description: "Update a subcolumn",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "column_id": .object(["type": "integer", "description": "Column ID"]),
                "id": .object(["type": "integer", "description": "Subcolumn ID"]),
                "title": .object(["type": "string", "description": "New title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "type": .object(["type": "integer", "description": "Subcolumn type"]),
            ]),
            "required": .array(["column_id", "id"]),
        ])
    ),
    Tool(
        name: "kaiten_delete_subcolumn",
        description: "Delete a subcolumn",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "column_id": .object(["type": "integer", "description": "Column ID"]),
                "id": .object(["type": "integer", "description": "Subcolumn ID"]),
            ]),
            "required": .array(["column_id", "id"]),
        ])
    ),

    // Lanes CRUD
    Tool(
        name: "kaiten_create_lane",
        description: "Create a lane on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "title": .object(["type": "string", "description": "Lane title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "wip_limit": .object(["type": "integer", "description": "WIP limit"]),
                "wip_limit_type": .object(["type": "string", "description": "WIP limit type"]),
                "row_count": .object(["type": "integer", "description": "Row count"]),
            ]),
            "required": .array(["board_id", "title"]),
        ])
    ),
    Tool(
        name: "kaiten_update_lane",
        description: "Update a lane on a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "id": .object(["type": "integer", "description": "Lane ID"]),
                "title": .object(["type": "string", "description": "New title"]),
                "sort_order": .object(["type": "integer", "description": "Sort order"]),
                "wip_limit": .object(["type": "integer", "description": "WIP limit"]),
                "wip_limit_type": .object(["type": "string", "description": "WIP limit type"]),
                "row_count": .object(["type": "integer", "description": "Row count"]),
                "condition": .object(["type": "integer", "description": "Lane condition"]),
            ]),
            "required": .array(["board_id", "id"]),
        ])
    ),
    Tool(
        name: "kaiten_delete_lane",
        description: "Delete a lane from a board",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "board_id": .object(["type": "integer", "description": "Board ID"]),
                "id": .object(["type": "integer", "description": "Lane ID"]),
            ]),
            "required": .array(["board_id", "id"]),
        ])
    ),

    // Card Baselines
    Tool(
        name: "kaiten_get_card_baselines",
        description: "Get card baselines",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "card_id": .object(["type": "integer", "description": "Card ID"]),
            ]),
            "required": .array(["card_id"]),
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
                    archived: optionalBool(params, key: "archived") ?? false,
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

            case "kaiten_update_card":
                let id = try requireInt(params, key: "id")
                let card = try await kaiten.updateCard(
                    id: id,
                    title: optionalString(params, key: "title"),
                    description: optionalString(params, key: "description"),
                    asap: optionalBool(params, key: "asap"),
                    dueDate: optionalString(params, key: "due_date"),
                    dueDateTimePresent: optionalBool(params, key: "due_date_time_present"),
                    sortOrder: optionalDouble(params, key: "sort_order"),
                    expiresLater: optionalBool(params, key: "expires_later"),
                    sizeText: optionalString(params, key: "size_text"),
                    boardId: optionalInt(params, key: "board_id"),
                    columnId: optionalInt(params, key: "column_id"),
                    laneId: optionalInt(params, key: "lane_id"),
                    ownerId: optionalInt(params, key: "owner_id"),
                    typeId: optionalInt(params, key: "type_id"),
                    serviceId: optionalInt(params, key: "service_id"),
                    blocked: optionalBool(params, key: "blocked"),
                    condition: optionalInt(params, key: "condition"),
                    externalId: optionalString(params, key: "external_id"),
                    textFormatTypeId: optionalInt(params, key: "text_format_type_id"),
                    sdNewComment: optionalBool(params, key: "sd_new_comment"),
                    ownerEmail: optionalString(params, key: "owner_email"),
                    prevCardId: optionalInt(params, key: "prev_card_id"),
                    estimateWorkload: optionalDouble(params, key: "estimate_workload")
                )
                return toJSON(card)

            case "kaiten_get_card_members":
                let cardId = try requireInt(params, key: "card_id")
                let members = try await kaiten.getCardMembers(cardId: cardId)
                return toJSON(members)

            case "kaiten_get_card_comments":
                let cardId = try requireInt(params, key: "card_id")
                let comments = try await kaiten.getCardComments(cardId: cardId)
                return toJSON(comments)

            case "kaiten_create_card":
                let title = try requireString(params, key: "title")
                let boardId = try requireInt(params, key: "board_id")
                let columnId = optionalInt(params, key: "column_id")
                let laneId = optionalInt(params, key: "lane_id")
                let description = optionalString(params, key: "description")
                let asap = optionalBool(params, key: "asap")
                let dueDate = optionalString(params, key: "due_date")
                let dueDateTimePresent = optionalBool(params, key: "due_date_time_present")
                let sortOrder = params.arguments?["sort_order"]?.doubleValue
                let expiresLater = optionalBool(params, key: "expires_later")
                let sizeText = optionalString(params, key: "size_text")
                let ownerId = optionalInt(params, key: "owner_id")
                let responsibleId = optionalInt(params, key: "responsible_id")
                let ownerEmail = optionalString(params, key: "owner_email")
                let position = optionalInt(params, key: "position")
                let typeId = optionalInt(params, key: "type_id")
                let externalId = optionalString(params, key: "external_id")
                let card = try await kaiten.createCard(
                    title: title,
                    boardId: boardId,
                    columnId: columnId,
                    laneId: laneId,
                    description: description,
                    asap: asap,
                    dueDate: dueDate,
                    dueDateTimePresent: dueDateTimePresent,
                    sortOrder: sortOrder,
                    expiresLater: expiresLater,
                    sizeText: sizeText,
                    ownerId: ownerId,
                    responsibleId: responsibleId,
                    ownerEmail: ownerEmail,
                    position: position,
                    typeId: typeId,
                    externalId: externalId
                )
                return toJSON(card)

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

            // Sprint
            case "kaiten_get_sprint_summary":
                let id = try requireInt(params, key: "id")
                let excludeDeletedCards = optionalBool(params, key: "exclude_deleted_cards")
                let summary = try await kaiten.getSprintSummary(id: id, excludeDeletedCards: excludeDeletedCards)
                return toJSON(summary)

            // Spaces CRUD
            case "kaiten_create_space":
                let title = try requireString(params, key: "title")
                let externalId = optionalString(params, key: "external_id")
                let sortOrder = optionalInt(params, key: "sort_order")
                let space = try await kaiten.createSpace(title: title, externalId: externalId, sortOrder: sortOrder)
                return toJSON(space)

            case "kaiten_get_space":
                let id = try requireInt(params, key: "id")
                let space = try await kaiten.getSpace(id: id)
                return toJSON(space)

            case "kaiten_update_space":
                let id = try requireInt(params, key: "id")
                let space = try await kaiten.updateSpace(
                    id: id,
                    title: optionalString(params, key: "title"),
                    externalId: optionalString(params, key: "external_id"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    access: optionalInt(params, key: "access"),
                    parentEntityUid: optionalString(params, key: "parent_entity_uid")
                )
                return toJSON(space)

            case "kaiten_delete_space":
                let id = try requireInt(params, key: "id")
                let deletedId = try await kaiten.deleteSpace(id: id)
                return toJSON(["id": deletedId])

            // Boards CRUD
            case "kaiten_create_board":
                let spaceId = try requireInt(params, key: "space_id")
                let title = try requireString(params, key: "title")
                let board = try await kaiten.createBoard(
                    spaceId: spaceId,
                    title: title,
                    description: optionalString(params, key: "description"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    externalId: optionalString(params, key: "external_id")
                )
                return toJSON(board)

            case "kaiten_update_board":
                let spaceId = try requireInt(params, key: "space_id")
                let id = try requireInt(params, key: "id")
                let board = try await kaiten.updateBoard(
                    spaceId: spaceId,
                    id: id,
                    title: optionalString(params, key: "title"),
                    description: optionalString(params, key: "description"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    externalId: optionalString(params, key: "external_id")
                )
                return toJSON(board)

            case "kaiten_delete_board":
                let spaceId = try requireInt(params, key: "space_id")
                let id = try requireInt(params, key: "id")
                let deletedId = try await kaiten.deleteBoard(spaceId: spaceId, id: id)
                return toJSON(["id": deletedId])

            // Columns CRUD
            case "kaiten_create_column":
                let boardId = try requireInt(params, key: "board_id")
                let title = try requireString(params, key: "title")
                let column = try await kaiten.createColumn(
                    boardId: boardId,
                    title: title,
                    sortOrder: optionalInt(params, key: "sort_order"),
                    type: optionalInt(params, key: "type"),
                    wipLimit: optionalInt(params, key: "wip_limit"),
                    wipLimitType: optionalString(params, key: "wip_limit_type"),
                    colCount: optionalInt(params, key: "col_count")
                )
                return toJSON(column)

            case "kaiten_update_column":
                let boardId = try requireInt(params, key: "board_id")
                let id = try requireInt(params, key: "id")
                let column = try await kaiten.updateColumn(
                    boardId: boardId,
                    id: id,
                    title: optionalString(params, key: "title"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    type: optionalInt(params, key: "type"),
                    wipLimit: optionalInt(params, key: "wip_limit"),
                    wipLimitType: optionalString(params, key: "wip_limit_type"),
                    colCount: optionalInt(params, key: "col_count")
                )
                return toJSON(column)

            case "kaiten_delete_column":
                let boardId = try requireInt(params, key: "board_id")
                let id = try requireInt(params, key: "id")
                let deletedId = try await kaiten.deleteColumn(boardId: boardId, id: id)
                return toJSON(["id": deletedId])

            // Subcolumns
            case "kaiten_list_subcolumns":
                let columnId = try requireInt(params, key: "column_id")
                let subcolumns = try await kaiten.listSubcolumns(columnId: columnId)
                return toJSON(subcolumns)

            case "kaiten_create_subcolumn":
                let columnId = try requireInt(params, key: "column_id")
                let title = try requireString(params, key: "title")
                let subcolumn = try await kaiten.createSubcolumn(
                    columnId: columnId,
                    title: title,
                    sortOrder: optionalInt(params, key: "sort_order"),
                    type: optionalInt(params, key: "type")
                )
                return toJSON(subcolumn)

            case "kaiten_update_subcolumn":
                let columnId = try requireInt(params, key: "column_id")
                let id = try requireInt(params, key: "id")
                let subcolumn = try await kaiten.updateSubcolumn(
                    columnId: columnId,
                    id: id,
                    title: optionalString(params, key: "title"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    type: optionalInt(params, key: "type")
                )
                return toJSON(subcolumn)

            case "kaiten_delete_subcolumn":
                let columnId = try requireInt(params, key: "column_id")
                let id = try requireInt(params, key: "id")
                let deletedId = try await kaiten.deleteSubcolumn(columnId: columnId, id: id)
                return toJSON(["id": deletedId])

            // Lanes CRUD
            case "kaiten_create_lane":
                let boardId = try requireInt(params, key: "board_id")
                let title = try requireString(params, key: "title")
                let lane = try await kaiten.createLane(
                    boardId: boardId,
                    title: title,
                    sortOrder: optionalInt(params, key: "sort_order"),
                    wipLimit: optionalInt(params, key: "wip_limit"),
                    wipLimitType: optionalString(params, key: "wip_limit_type"),
                    rowCount: optionalInt(params, key: "row_count")
                )
                return toJSON(lane)

            case "kaiten_update_lane":
                let boardId = try requireInt(params, key: "board_id")
                let id = try requireInt(params, key: "id")
                let lane = try await kaiten.updateLane(
                    boardId: boardId,
                    id: id,
                    title: optionalString(params, key: "title"),
                    sortOrder: optionalInt(params, key: "sort_order"),
                    wipLimit: optionalInt(params, key: "wip_limit"),
                    wipLimitType: optionalString(params, key: "wip_limit_type"),
                    rowCount: optionalInt(params, key: "row_count"),
                    condition: optionalInt(params, key: "condition")
                )
                return toJSON(lane)

            case "kaiten_delete_lane":
                let boardId = try requireInt(params, key: "board_id")
                let id = try requireInt(params, key: "id")
                let deletedId = try await kaiten.deleteLane(boardId: boardId, id: id)
                return toJSON(["id": deletedId])

            // Card Baselines
            case "kaiten_get_card_baselines":
                let cardId = try requireInt(params, key: "card_id")
                let baselines = try await kaiten.getCardBaselines(cardId: cardId)
                return toJSON(baselines)

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

@Sendable func toJSON(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(value), let str = String(data: data, encoding: .utf8) else {
        return "{\"error\": \"Failed to encode response\"}"
    }
    return str
}

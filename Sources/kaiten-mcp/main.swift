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
  version: "1.2.0",
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
        "offset": .object([
          "type": "integer", "description": "Number of cards to skip (default: 0)",
        ]),
        "limit": .object([
          "type": "integer", "description": "Max cards to return (default/max: 100)",
        ]),
        "created_before": .object([
          "type": "string", "description": "ISO 8601 date — cards created before",
        ]),
        "created_after": .object([
          "type": "string", "description": "ISO 8601 date — cards created after",
        ]),
        "updated_before": .object([
          "type": "string", "description": "ISO 8601 date — cards updated before",
        ]),
        "updated_after": .object([
          "type": "string", "description": "ISO 8601 date — cards updated after",
        ]),
        "first_moved_in_progress_after": .object([
          "type": "string", "description": "ISO 8601 date filter",
        ]),
        "first_moved_in_progress_before": .object([
          "type": "string", "description": "ISO 8601 date filter",
        ]),
        "last_moved_to_done_at_after": .object([
          "type": "string", "description": "ISO 8601 date filter",
        ]),
        "last_moved_to_done_at_before": .object([
          "type": "string", "description": "ISO 8601 date filter",
        ]),
        "due_date_after": .object([
          "type": "string", "description": "ISO 8601 date — due date after",
        ]),
        "due_date_before": .object([
          "type": "string", "description": "ISO 8601 date — due date before",
        ]),
        "query": .object(["type": "string", "description": "Text search"]),
        "search_fields": .object([
          "type": "string", "description": "Comma-separated fields to search",
        ]),
        "tag": .object(["type": "string", "description": "Tag name filter"]),
        "tag_ids": .object(["type": "string", "description": "Comma-separated tag IDs"]),
        "type_id": .object(["type": "integer", "description": "Card type ID"]),
        "type_ids": .object(["type": "string", "description": "Comma-separated type IDs"]),
        "member_ids": .object(["type": "string", "description": "Comma-separated member IDs"]),
        "owner_id": .object(["type": "integer", "description": "Owner ID"]),
        "owner_ids": .object(["type": "string", "description": "Comma-separated owner IDs"]),
        "responsible_id": .object(["type": "integer", "description": "Responsible person ID"]),
        "responsible_ids": .object([
          "type": "string", "description": "Comma-separated responsible IDs",
        ]),
        "column_ids": .object(["type": "string", "description": "Comma-separated column IDs"]),
        "space_id": .object(["type": "integer", "description": "Space ID filter"]),
        "external_id": .object(["type": "string", "description": "External ID filter"]),
        "organizations_ids": .object([
          "type": "string", "description": "Comma-separated organization IDs",
        ]),
        "exclude_board_ids": .object(["type": "string", "description": "Exclude these board IDs"]),
        "exclude_lane_ids": .object(["type": "string", "description": "Exclude these lane IDs"]),
        "exclude_column_ids": .object(["type": "string", "description": "Exclude these column IDs"]
        ),
        "exclude_owner_ids": .object(["type": "string", "description": "Exclude these owner IDs"]),
        "exclude_card_ids": .object(["type": "string", "description": "Exclude these card IDs"]),
        "condition": .object([
          "type": "integer", "description": "Card condition: 1=queued, 2=in progress, 3=done",
        ]),
        "states": .object(["type": "string", "description": "Comma-separated states"]),
        "archived": .object([
          "type": "boolean",
          "description": "Filter by archived status (default: false — only non-archived cards)",
        ]),
        "asap": .object(["type": "boolean", "description": "Filter ASAP cards"]),
        "overdue": .object(["type": "boolean", "description": "Filter overdue cards"]),
        "done_on_time": .object(["type": "boolean", "description": "Filter done-on-time cards"]),
        "with_due_date": .object(["type": "boolean", "description": "Filter cards with due date"]),
        "is_request": .object(["type": "boolean", "description": "Filter service desk requests"]),
        "order_by": .object(["type": "string", "description": "Sort field"]),
        "order_direction": .object(["type": "string", "description": "Sort direction (asc/desc)"]),
        "order_space_id": .object(["type": "integer", "description": "Space ID for ordering"]),
        "additional_card_fields": .object([
          "type": "string", "description": "Extra fields to include",
        ]),
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
        ])
      ]),
      "required": .array(["id"]),
    ])
  ),
  Tool(
    name: "kaiten_update_card",
    description:
      "Update an existing card by ID. All fields except id are optional — only provided fields will be updated.",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "id": .object(["type": "integer", "description": "Card ID (required)"]),
        "title": .object(["type": "string", "description": "New title"]),
        "description": .object(["type": "string", "description": "New description (markdown)"]),
        "asap": .object(["type": "boolean", "description": "Mark as ASAP"]),
        "due_date": .object(["type": "string", "description": "Due date (ISO 8601)"]),
        "due_date_time_present": .object([
          "type": "boolean", "description": "Whether due date includes time",
        ]),
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
        "condition": .object([
          "type": "integer", "description": "Condition: 1=queued, 2=in progress, 3=done",
        ]),
        "external_id": .object(["type": "string", "description": "External ID"]),
        "text_format_type_id": .object(["type": "integer", "description": "Text format type ID"]),
        "sd_new_comment": .object([
          "type": "boolean", "description": "Service desk new comment flag",
        ]),
        "owner_email": .object(["type": "string", "description": "Owner email address"]),
        "prev_card_id": .object([
          "type": "integer", "description": "Previous card ID for repositioning",
        ]),
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
        ])
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
        ])
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
        "due_date_time_present": .object([
          "type": "boolean", "description": "Whether due_date includes time",
        ]),
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
        ])
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
        ])
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
        ])
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
        "offset": .object([
          "type": "integer", "description": "Number of items to skip (default: 0)",
        ]),
        "limit": .object(["type": "integer", "description": "Max items to return (default: 100)"]),
        "query": .object(["type": "string", "description": "Search query"]),
        "include_values": .object(["type": "boolean", "description": "Include property values"]),
        "include_author": .object(["type": "boolean", "description": "Include author info"]),
        "compact": .object(["type": "boolean", "description": "Compact response"]),
        "load_by_ids": .object(["type": "boolean", "description": "Load by IDs mode"]),
        "ids": .object([
          "type": "array", "description": "Array of property IDs to load",
          "items": .object(["type": "integer"]),
        ]),
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
        ])
      ]),
      "required": .array(["id"]),
    ])
  ),
  Tool(
    name: "kaiten_get_custom_property_select_values",
    description: "Get available select/multi-select values for a custom property",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "property_id": .object(["type": "integer", "description": "Custom property ID"]),
        "query": .object(["type": "string", "description": "Search query"]),
        "offset": .object([
          "type": "integer", "description": "Number of items to skip (default: 0)",
        ]),
        "limit": .object(["type": "integer", "description": "Max items to return (default: 100)"]),
      ]),
      "required": .array(["property_id"]),
    ])
  ),
  Tool(
    name: "kaiten_update_card_properties",
    description:
      "Update custom property values on a card. Property keys use format 'id_{property_id}'. Values: array of value IDs for select/multi-select, or a number for numeric properties. Pass null to remove a property value.",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "properties": .object([
          "type": "object",
          "description":
            "Custom properties to set. Keys: 'id_{property_id}', values: array of value IDs (select) or number (numeric). Pass null to clear.",
          "additionalProperties": .bool(true),
        ]),
      ]),
      "required": .array(["card_id", "properties"]),
    ])
  ),

  // Preferences
  Tool(
    name: "kaiten_get_preferences",
    description:
      "Get current user preferences (configured boards, spaces). Returns the content of the user-level config file.",
    inputSchema: .object([
      "type": "object",
      "properties": .object([:]),
    ])
  ),
  Tool(
    name: "kaiten_configure",
    description:
      "Manage user preferences (personal boards/spaces). Actions: get, set_boards, set_spaces, add_board, remove_board, add_space, remove_space",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "action": .object([
          "type": "string",
          "description": "Action to perform",
          "enum": .array([
            "get", "set_boards", "set_spaces", "add_board", "remove_board", "add_space",
            "remove_space",
          ]),
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
    name: "kaiten_login",
    description: "Save Kaiten credentials (url, token) to shared config",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "url": .object(["type": "string", "description": "Kaiten API URL"]),
        "token": .object(["type": "string", "description": "Kaiten API token"]),
      ]),
      "required": .array(["url", "token"]),
    ])
  ),
  Tool(
    name: "kaiten_read_logs",
    description: "Read MCP log file text for troubleshooting",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "tail_lines": .object([
          "type": "integer",
          "description": "Optional: return only last N lines",
        ])
      ]),
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
        "exclude_deleted_cards": .object([
          "type": "boolean", "description": "Exclude deleted cards from summary",
        ]),
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
        "id": .object(["type": "integer", "description": "Space ID"])
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
        "id": .object(["type": "integer", "description": "Space ID"])
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
        "column_id": .object(["type": "integer", "description": "Column ID"])
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
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),

  // External Links
  Tool(
    name: "kaiten_list_external_links",
    description: "List external links on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_add_external_link",
    description: "Add an external link to a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "url": .object(["type": "string", "description": "URL of the external link"]),
        "title": .object(["type": "string", "description": "Title/description of the link"]),
      ]),
      "required": .array(["card_id", "url"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_external_link",
    description: "Remove an external link from a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "link_id": .object(["type": "integer", "description": "External link ID"]),
      ]),
      "required": .array(["card_id", "link_id"]),
    ])
  ),

  // Checklists
  Tool(
    name: "kaiten_create_checklist",
    description: "Create a new checklist on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "name": .object(["type": "string", "description": "Checklist name"]),
        "sort_order": .object(["type": "number", "description": "Sort order position"]),
      ]),
      "required": .array(["card_id", "name"]),
    ])
  ),
  Tool(
    name: "kaiten_get_checklist",
    description: "Get a checklist by ID",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
      ]),
      "required": .array(["card_id", "checklist_id"]),
    ])
  ),
  Tool(
    name: "kaiten_update_checklist",
    description: "Update a checklist (name, sort order, or move to another card)",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        "name": .object(["type": "string", "description": "New checklist name"]),
        "sort_order": .object(["type": "number", "description": "New sort order"]),
        "move_to_card_id": .object([
          "type": "integer", "description": "Move checklist to another card",
        ]),
      ]),
      "required": .array(["card_id", "checklist_id"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_checklist",
    description: "Remove a checklist from a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
      ]),
      "required": .array(["card_id", "checklist_id"]),
    ])
  ),
  Tool(
    name: "kaiten_create_checklist_item",
    description: "Create a new item in a checklist",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        "text": .object(["type": "string", "description": "Item text (1-4096 characters)"]),
        "sort_order": .object(["type": "number", "description": "Sort order (must be > 0)"]),
        "checked": .object(["type": "boolean", "description": "Checked state"]),
        "due_date": .object(["type": "string", "description": "Due date (YYYY-MM-DD)"]),
        "responsible_id": .object(["type": "integer", "description": "Responsible user ID"]),
      ]),
      "required": .array(["card_id", "checklist_id", "text"]),
    ])
  ),
  Tool(
    name: "kaiten_update_checklist_item",
    description: "Update a checklist item",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        "item_id": .object(["type": "integer", "description": "Checklist item ID"]),
        "text": .object(["type": "string", "description": "Item text (max 4096 characters)"]),
        "sort_order": .object(["type": "number", "description": "Sort order (must be > 0)"]),
        "move_to_checklist_id": .object([
          "type": "integer", "description": "Move item to another checklist",
        ]),
        "checked": .object(["type": "boolean", "description": "Checked state"]),
        "due_date": .object(["type": "string", "description": "Due date (YYYY-MM-DD)"]),
        "responsible_id": .object(["type": "integer", "description": "Responsible user ID"]),
      ]),
      "required": .array(["card_id", "checklist_id", "item_id"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_checklist_item",
    description: "Remove an item from a checklist",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        "item_id": .object(["type": "integer", "description": "Checklist item ID"]),
      ]),
      "required": .array(["card_id", "checklist_id", "item_id"]),
    ])
  ),

  // Delete Card
  Tool(
    name: "kaiten_delete_card",
    description: "Delete a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),

  // Card Members
  Tool(
    name: "kaiten_add_card_member",
    description: "Add a member to a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "user_id": .object(["type": "integer", "description": "User ID to add"]),
      ]),
      "required": .array(["card_id", "user_id"]),
    ])
  ),
  Tool(
    name: "kaiten_update_card_member_role",
    description: "Update a card member's role (1 = member, 2 = responsible)",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "user_id": .object(["type": "integer", "description": "User ID"]),
        "type": .object([
          "type": "integer",
          "description": "Role type: 1 = member, 2 = responsible",
        ]),
      ]),
      "required": .array(["card_id", "user_id", "type"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_card_member",
    description: "Remove a member from a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "user_id": .object(["type": "integer", "description": "User ID to remove"]),
      ]),
      "required": .array(["card_id", "user_id"]),
    ])
  ),

  // Comments
  Tool(
    name: "kaiten_update_comment",
    description: "Update a comment on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "comment_id": .object(["type": "integer", "description": "Comment ID"]),
        "text": .object(["type": "string", "description": "New comment text (markdown)"]),
      ]),
      "required": .array(["card_id", "comment_id", "text"]),
    ])
  ),
  Tool(
    name: "kaiten_delete_comment",
    description: "Delete a comment from a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "comment_id": .object(["type": "integer", "description": "Comment ID"]),
      ]),
      "required": .array(["card_id", "comment_id"]),
    ])
  ),

  // Card Tags
  Tool(
    name: "kaiten_list_card_tags",
    description: "List all tags on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_add_card_tag",
    description: "Add a tag to a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "name": .object(["type": "string", "description": "Tag name"]),
      ]),
      "required": .array(["card_id", "name"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_card_tag",
    description: "Remove a tag from a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "tag_id": .object(["type": "integer", "description": "Tag ID"]),
      ]),
      "required": .array(["card_id", "tag_id"]),
    ])
  ),

  // Card Children
  Tool(
    name: "kaiten_list_card_children",
    description: "List children of a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_add_card_child",
    description: "Add a child card to a parent card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Parent card ID"]),
        "child_card_id": .object(["type": "integer", "description": "Child card ID"]),
      ]),
      "required": .array(["card_id", "child_card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_remove_card_child",
    description: "Remove a child card from a parent card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Parent card ID"]),
        "child_id": .object(["type": "integer", "description": "Child card ID"]),
      ]),
      "required": .array(["card_id", "child_id"]),
    ])
  ),

  // Users
  Tool(
    name: "kaiten_list_users",
    description: "List users in the company",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "type": .object(["type": "string", "description": "User type filter"]),
        "query": .object(["type": "string", "description": "Search query"]),
        "ids": .object(["type": "string", "description": "Comma-separated user IDs"]),
        "limit": .object(["type": "integer", "description": "Max users to return (max 100)"]),
        "offset": .object(["type": "integer", "description": "Pagination offset"]),
        "include_inactive": .object([
          "type": "boolean", "description": "Include inactive users",
        ]),
      ]),
    ])
  ),
  Tool(
    name: "kaiten_get_current_user",
    description: "Get the currently authenticated user",
    inputSchema: .object([
      "type": "object",
      "properties": .object([:]),
    ])
  ),

  // Card Blockers
  Tool(
    name: "kaiten_list_card_blockers",
    description: "List all blockers on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_create_card_blocker",
    description: "Create a blocker on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "reason": .object(["type": "string", "description": "Blocker reason"]),
        "blocker_card_id": .object([
          "type": "integer", "description": "ID of the blocking card",
        ]),
      ]),
      "required": .array(["card_id"]),
    ])
  ),
  Tool(
    name: "kaiten_update_card_blocker",
    description: "Update a card blocker",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "blocker_id": .object(["type": "integer", "description": "Blocker ID"]),
        "reason": .object(["type": "string", "description": "Blocker reason"]),
        "blocker_card_id": .object([
          "type": "integer", "description": "ID of the blocking card",
        ]),
      ]),
      "required": .array(["card_id", "blocker_id"]),
    ])
  ),
  Tool(
    name: "kaiten_delete_card_blocker",
    description: "Delete a card blocker",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "blocker_id": .object(["type": "integer", "description": "Blocker ID"]),
      ]),
      "required": .array(["card_id", "blocker_id"]),
    ])
  ),

  // Card Types
  Tool(
    name: "kaiten_list_card_types",
    description: "List card types",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "limit": .object(["type": "integer", "description": "Max items to return"]),
        "offset": .object(["type": "integer", "description": "Pagination offset"]),
      ]),
    ])
  ),

  // Sprints
  Tool(
    name: "kaiten_list_sprints",
    description: "List sprints",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "active": .object(["type": "boolean", "description": "Filter by active status"]),
        "limit": .object(["type": "integer", "description": "Max items to return"]),
        "offset": .object(["type": "integer", "description": "Pagination offset"]),
      ]),
    ])
  ),

  // Card Location History
  Tool(
    name: "kaiten_get_card_location_history",
    description: "Get card location history (column/lane movements)",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"])
      ]),
      "required": .array(["card_id"]),
    ])
  ),

  // Update External Link
  Tool(
    name: "kaiten_update_external_link",
    description: "Update an external link on a card",
    inputSchema: .object([
      "type": "object",
      "properties": .object([
        "card_id": .object(["type": "integer", "description": "Card ID"]),
        "link_id": .object(["type": "integer", "description": "External link ID"]),
        "url": .object(["type": "string", "description": "New URL"]),
        "title": .object(["type": "string", "description": "New title/description"]),
      ]),
      "required": .array(["card_id", "link_id"]),
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
      if params.name == "kaiten_get_preferences" {
        let currentConfig = Config.load()
        let currentPreferences = Preferences.load()
        let response = PreferencesResponse(
          url: currentConfig.url,
          myBoards: currentPreferences.myBoards,
          mySpaces: currentPreferences.mySpaces
        )
        return toJSON(response)
      }

      if params.name == "kaiten_configure" {
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
            expected:
              "one of: get, set_boards, set_spaces, add_board, remove_board, add_space, remove_space"
          )
        }
      }

      if params.name == "kaiten_login" {
        let rawURL = try requireString(params, key: "url")
        let rawToken = try requireString(params, key: "token")
        try validateLoginInput(url: rawURL, token: rawToken)

        var currentConfig = Config.load()
        currentConfig.url = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        currentConfig.token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        try currentConfig.save()
        return toJSON(currentConfig)
      }

      if params.name == "kaiten_read_logs" {
        let tailLines = optionalInt(params, key: "tail_lines")
        if let tailLines, tailLines <= 0 {
          throw ToolError.invalidType(key: "tail_lines", expected: "positive integer")
        }
        let response = LogReadResponse(
          path: logFilePath,
          content: try readLogContent(path: logFilePath, tailLines: tailLines)
        )
        return toJSON(response)
      }

      let kaiten = try makeConfiguredKaitenClient()

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
          condition: optionalInt(params, key: "condition").flatMap { CardCondition(rawValue: $0) },
          states: optionalString(params, key: "states").map {
            $0.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
              .compactMap { CardState(rawValue: $0) }
          },
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

        let page = try await kaiten.listCards(
          boardId: boardId, columnId: columnId, laneId: laneId, offset: offset, limit: limit,
          filter: filter)
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
          condition: optionalInt(params, key: "condition").flatMap {
            CardCondition(rawValue: $0)
          },
          externalId: optionalString(params, key: "external_id"),
          textFormatTypeId: optionalInt(params, key: "text_format_type_id").flatMap {
            TextFormatType(rawValue: $0)
          },
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
          position: optionalInt(params, key: "position").flatMap { CardPosition(rawValue: $0) },
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
        let condition = optionalInt(params, key: "condition").flatMap {
          LaneCondition(rawValue: $0)
        }
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
        let ids: [Int]? =
          (params.arguments?["ids"]?.arrayValue != nil)
          ? try requireIntArray(params, key: "ids") : nil
        let orderBy = optionalString(params, key: "order_by")
        let orderDirection = optionalString(params, key: "order_direction")
        let props = try await kaiten.listCustomProperties(
          offset: offset, limit: limit, query: query, includeValues: includeValues,
          includeAuthor: includeAuthor, compact: compact, loadByIds: loadByIds, ids: ids,
          orderBy: orderBy, orderDirection: orderDirection)
        return toJSON(props)

      case "kaiten_get_custom_property":
        let id = try requireInt(params, key: "id")
        let prop = try await kaiten.getCustomProperty(id: id)
        return toJSON(prop)

      case "kaiten_get_custom_property_select_values":
        let propertyId = try requireInt(params, key: "property_id")
        let query = optionalString(params, key: "query")
        let offset = optionalInt(params, key: "offset") ?? 0
        let limit = optionalInt(params, key: "limit") ?? 100
        let values = try await kaiten.listCustomPropertySelectValues(
          propertyId: propertyId,
          query: query,
          offset: offset,
          limit: limit
        )
        return toJSON(values)

      case "kaiten_update_card_properties":
        let cardId = try requireInt(params, key: "card_id")
        guard let propsValue = params.arguments?["properties"],
          let propsObject = propsValue.objectValue
        else {
          throw ToolError.invalidType(key: "properties", expected: "object")
        }
        // Convert MCP Value dict to JSON data, then decode as propertiesPayload
        let propsData = try JSONSerialization.data(
          withJSONObject: propsObject.mapValues { jsonValueToAny($0) })
        let properties = try JSONDecoder().decode(
          Components.Schemas.UpdateCardRequest.propertiesPayload.self, from: propsData)
        let card = try await kaiten.updateCard(id: cardId, properties: properties)
        return toJSON(card)

      // Sprint
      case "kaiten_get_sprint_summary":
        let id = try requireInt(params, key: "id")
        let excludeDeletedCards = optionalBool(params, key: "exclude_deleted_cards")
        let summary = try await kaiten.getSprintSummary(
          id: id, excludeDeletedCards: excludeDeletedCards)
        return toJSON(summary)

      // Spaces CRUD
      case "kaiten_create_space":
        let title = try requireString(params, key: "title")
        let externalId = optionalString(params, key: "external_id")
        let sortOrder = optionalDouble(params, key: "sort_order")
        let space = try await kaiten.createSpace(
          title: title, externalId: externalId, sortOrder: sortOrder)
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          access: optionalString(params, key: "access"),
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
          sortOrder: optionalDouble(params, key: "sort_order"),
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
          sortOrder: optionalDouble(params, key: "sort_order"),
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          type: optionalInt(params, key: "type").flatMap { ColumnType(rawValue: $0) },
          wipLimit: optionalInt(params, key: "wip_limit"),
          wipLimitType: optionalInt(params, key: "wip_limit_type").flatMap {
            WipLimitType(rawValue: $0)
          },
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          type: optionalInt(params, key: "type").flatMap { ColumnType(rawValue: $0) },
          wipLimit: optionalInt(params, key: "wip_limit"),
          wipLimitType: optionalInt(params, key: "wip_limit_type").flatMap {
            WipLimitType(rawValue: $0)
          },
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          type: optionalInt(params, key: "type").flatMap { ColumnType(rawValue: $0) }
        )
        return toJSON(subcolumn)

      case "kaiten_update_subcolumn":
        let columnId = try requireInt(params, key: "column_id")
        let id = try requireInt(params, key: "id")
        let subcolumn = try await kaiten.updateSubcolumn(
          columnId: columnId,
          id: id,
          title: optionalString(params, key: "title"),
          sortOrder: optionalDouble(params, key: "sort_order"),
          type: optionalInt(params, key: "type").flatMap { ColumnType(rawValue: $0) }
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          wipLimit: optionalInt(params, key: "wip_limit"),
          wipLimitType: optionalInt(params, key: "wip_limit_type").flatMap {
            WipLimitType(rawValue: $0)
          },
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
          sortOrder: optionalDouble(params, key: "sort_order"),
          wipLimit: optionalInt(params, key: "wip_limit"),
          wipLimitType: optionalInt(params, key: "wip_limit_type").flatMap {
            WipLimitType(rawValue: $0)
          },
          rowCount: optionalInt(params, key: "row_count"),
          condition: optionalInt(params, key: "condition").flatMap { LaneCondition(rawValue: $0) }
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

      // External Links
      case "kaiten_list_external_links":
        let cardId = try requireInt(params, key: "card_id")
        let links = try await kaiten.listExternalLinks(cardId: cardId)
        return toJSON(links)

      case "kaiten_add_external_link":
        let cardId = try requireInt(params, key: "card_id")
        let url = try requireString(params, key: "url")
        let title = optionalString(params, key: "title")
        let link = try await kaiten.createExternalLink(cardId: cardId, url: url, description: title)
        return toJSON(link)

      case "kaiten_remove_external_link":
        let cardId = try requireInt(params, key: "card_id")
        let linkId = try requireInt(params, key: "link_id")
        let deletedId = try await kaiten.removeExternalLink(cardId: cardId, linkId: linkId)
        return toJSON(["id": deletedId])

      // Checklists
      case "kaiten_create_checklist":
        let cardId = try requireInt(params, key: "card_id")
        let name = try requireString(params, key: "name")
        let sortOrder = optionalDouble(params, key: "sort_order")
        let checklist = try await kaiten.createChecklist(
          cardId: cardId, name: name, sortOrder: sortOrder)
        return toJSON(checklist)

      case "kaiten_get_checklist":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let checklist = try await kaiten.getChecklist(cardId: cardId, checklistId: checklistId)
        return toJSON(checklist)

      case "kaiten_update_checklist":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let name = optionalString(params, key: "name")
        let sortOrder = optionalDouble(params, key: "sort_order")
        let moveToCardId = optionalInt(params, key: "move_to_card_id")
        let checklist = try await kaiten.updateChecklist(
          cardId: cardId, checklistId: checklistId, name: name, sortOrder: sortOrder,
          moveToCardId: moveToCardId)
        return toJSON(checklist)

      case "kaiten_remove_checklist":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let deletedId = try await kaiten.removeChecklist(cardId: cardId, checklistId: checklistId)
        return toJSON(["id": deletedId])

      case "kaiten_create_checklist_item":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let text = try requireString(params, key: "text")
        let sortOrder = optionalDouble(params, key: "sort_order")
        let checked = optionalBool(params, key: "checked")
        let dueDate = optionalString(params, key: "due_date")
        let responsibleId = optionalInt(params, key: "responsible_id")
        let item = try await kaiten.createChecklistItem(
          cardId: cardId, checklistId: checklistId, text: text, sortOrder: sortOrder,
          checked: checked, dueDate: dueDate, responsibleId: responsibleId)
        return toJSON(item)

      case "kaiten_update_checklist_item":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let itemId = try requireInt(params, key: "item_id")
        let text = optionalString(params, key: "text")
        let sortOrder = optionalDouble(params, key: "sort_order")
        let moveToChecklistId = optionalInt(params, key: "move_to_checklist_id")
        let checked = optionalBool(params, key: "checked")
        let dueDate = optionalString(params, key: "due_date")
        let responsibleId = optionalInt(params, key: "responsible_id")
        let item = try await kaiten.updateChecklistItem(
          cardId: cardId, checklistId: checklistId, itemId: itemId, text: text,
          sortOrder: sortOrder, moveToChecklistId: moveToChecklistId, checked: checked,
          dueDate: dueDate, responsibleId: responsibleId)
        return toJSON(item)

      case "kaiten_remove_checklist_item":
        let cardId = try requireInt(params, key: "card_id")
        let checklistId = try requireInt(params, key: "checklist_id")
        let itemId = try requireInt(params, key: "item_id")
        let deletedId = try await kaiten.removeChecklistItem(
          cardId: cardId, checklistId: checklistId, itemId: itemId)
        return toJSON(["id": deletedId])

      // Delete Card
      case "kaiten_delete_card":
        let cardId = try requireInt(params, key: "card_id")
        let card = try await kaiten.deleteCard(id: cardId)
        return toJSON(card)

      // Card Members
      case "kaiten_add_card_member":
        let cardId = try requireInt(params, key: "card_id")
        let userId = try requireInt(params, key: "user_id")
        let member = try await kaiten.addCardMember(cardId: cardId, userId: userId)
        return toJSON(member)

      case "kaiten_update_card_member_role":
        let cardId = try requireInt(params, key: "card_id")
        let userId = try requireInt(params, key: "user_id")
        let typeValue = try requireInt(params, key: "type")
        guard let roleType = CardMemberRoleType(rawValue: typeValue) else {
          throw ToolError.invalidType(key: "type", expected: "1 (member) or 2 (responsible)")
        }
        let role = try await kaiten.updateCardMemberRole(
          cardId: cardId, userId: userId, type: roleType)
        return toJSON(role)

      case "kaiten_remove_card_member":
        let cardId = try requireInt(params, key: "card_id")
        let userId = try requireInt(params, key: "user_id")
        let deletedId = try await kaiten.removeCardMember(cardId: cardId, userId: userId)
        return toJSON(["id": deletedId])

      // Comments
      case "kaiten_update_comment":
        let cardId = try requireInt(params, key: "card_id")
        let commentId = try requireInt(params, key: "comment_id")
        let text = try requireString(params, key: "text")
        let comment = try await kaiten.updateComment(
          cardId: cardId, commentId: commentId, text: text)
        return toJSON(comment)

      case "kaiten_delete_comment":
        let cardId = try requireInt(params, key: "card_id")
        let commentId = try requireInt(params, key: "comment_id")
        let deletedId = try await kaiten.deleteComment(cardId: cardId, commentId: commentId)
        return toJSON(["id": deletedId])

      // Card Tags
      case "kaiten_list_card_tags":
        let cardId = try requireInt(params, key: "card_id")
        let tags = try await kaiten.listCardTags(cardId: cardId)
        return toJSON(tags)

      case "kaiten_add_card_tag":
        let cardId = try requireInt(params, key: "card_id")
        let name = try requireString(params, key: "name")
        let tag = try await kaiten.addCardTag(cardId: cardId, name: name)
        return toJSON(tag)

      case "kaiten_remove_card_tag":
        let cardId = try requireInt(params, key: "card_id")
        let tagId = try requireInt(params, key: "tag_id")
        let deletedId = try await kaiten.removeCardTag(cardId: cardId, tagId: tagId)
        return toJSON(["id": deletedId])

      // Card Children
      case "kaiten_list_card_children":
        let cardId = try requireInt(params, key: "card_id")
        let children = try await kaiten.listCardChildren(cardId: cardId)
        return toJSON(children)

      case "kaiten_add_card_child":
        let cardId = try requireInt(params, key: "card_id")
        let childCardId = try requireInt(params, key: "child_card_id")
        let child = try await kaiten.addCardChild(cardId: cardId, childCardId: childCardId)
        return toJSON(child)

      case "kaiten_remove_card_child":
        let cardId = try requireInt(params, key: "card_id")
        let childId = try requireInt(params, key: "child_id")
        let deletedId = try await kaiten.removeCardChild(cardId: cardId, childId: childId)
        return toJSON(["id": deletedId])

      // Users
      case "kaiten_list_users":
        let type = optionalString(params, key: "type")
        let query = optionalString(params, key: "query")
        let ids = optionalString(params, key: "ids")
        let limit = optionalInt(params, key: "limit")
        let offset = optionalInt(params, key: "offset")
        let includeInactive = optionalBool(params, key: "include_inactive")
        let users = try await kaiten.listUsers(
          type: type, query: query, ids: ids, limit: limit, offset: offset,
          includeInactive: includeInactive)
        return toJSON(users)

      case "kaiten_get_current_user":
        let user = try await kaiten.getCurrentUser()
        return toJSON(user)

      // Card Blockers
      case "kaiten_list_card_blockers":
        let cardId = try requireInt(params, key: "card_id")
        let blockers = try await kaiten.listCardBlockers(cardId: cardId)
        return toJSON(blockers)

      case "kaiten_create_card_blocker":
        let cardId = try requireInt(params, key: "card_id")
        let reason = optionalString(params, key: "reason")
        let blockerCardId = optionalInt(params, key: "blocker_card_id")
        let blocker = try await kaiten.createCardBlocker(
          cardId: cardId, reason: reason, blockerCardId: blockerCardId)
        return toJSON(blocker)

      case "kaiten_update_card_blocker":
        let cardId = try requireInt(params, key: "card_id")
        let blockerId = try requireInt(params, key: "blocker_id")
        let reason = optionalString(params, key: "reason")
        let blockerCardId = optionalInt(params, key: "blocker_card_id")
        let blocker = try await kaiten.updateCardBlocker(
          cardId: cardId, blockerId: blockerId, reason: reason, blockerCardId: blockerCardId)
        return toJSON(blocker)

      case "kaiten_delete_card_blocker":
        let cardId = try requireInt(params, key: "card_id")
        let blockerId = try requireInt(params, key: "blocker_id")
        let blocker = try await kaiten.deleteCardBlocker(cardId: cardId, blockerId: blockerId)
        return toJSON(blocker)

      // Card Types
      case "kaiten_list_card_types":
        let limit = optionalInt(params, key: "limit")
        let offset = optionalInt(params, key: "offset")
        let types = try await kaiten.listCardTypes(limit: limit, offset: offset)
        return toJSON(types)

      // Sprints
      case "kaiten_list_sprints":
        let active = optionalBool(params, key: "active")
        let limit = optionalInt(params, key: "limit")
        let offset = optionalInt(params, key: "offset")
        let sprints = try await kaiten.listSprints(active: active, limit: limit, offset: offset)
        return toJSON(sprints)

      // Card Location History
      case "kaiten_get_card_location_history":
        let cardId = try requireInt(params, key: "card_id")
        let history = try await kaiten.getCardLocationHistory(cardId: cardId)
        return toJSON(history)

      // Update External Link
      case "kaiten_update_external_link":
        let cardId = try requireInt(params, key: "card_id")
        let linkId = try requireInt(params, key: "link_id")
        let url = optionalString(params, key: "url")
        let title = optionalString(params, key: "title")
        let link = try await kaiten.updateExternalLink(
          cardId: cardId, linkId: linkId, url: url, description: title)
        return toJSON(link)

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
    throw ToolError.missingCredentials(missing)
  }
  return try KaitenClient(
    baseURL: config.url!.trimmingCharacters(in: .whitespacesAndNewlines),
    token: config.token!.trimmingCharacters(in: .whitespacesAndNewlines)
  )
}

@Sendable func readLogContent(path: String, tailLines: Int?) throws -> String {
  guard FileManager.default.fileExists(atPath: path) else {
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

import MCP

let cardsTools: [Tool] = [
  Tool(
      name: "kaiten_list_cards",
      description:
        "List cards (paginated, max 100 per page). Defaults to active (non-archived) cards; set archived=true to include archived cards. Supports 40+ filter parameters.",
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
            "default": .bool(false),
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
      name: "kaiten_delete_card",
      description: "Delete a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"])
        ]),
        "required": .array(["card_id"]),
      ])
    )
]

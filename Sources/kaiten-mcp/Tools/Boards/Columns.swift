import MCP

let columnsTools: [Tool] = [
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
    )
]

import MCP

let boardsTools: [Tool] = [
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
]

import MCP

let lanesTools: [Tool] = [
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
    )
]

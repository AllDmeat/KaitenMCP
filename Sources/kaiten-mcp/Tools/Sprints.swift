import MCP

let sprintsTools: [Tool] = [
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
    )
]

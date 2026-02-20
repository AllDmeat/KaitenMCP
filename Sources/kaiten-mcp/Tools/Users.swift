import MCP

let usersTools: [Tool] = [
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
    )
]

import MCP

let settingsTools: [Tool] = [
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
    )
]

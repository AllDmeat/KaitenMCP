import MCP

let cardMembersTools: [Tool] = [
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
    )
]

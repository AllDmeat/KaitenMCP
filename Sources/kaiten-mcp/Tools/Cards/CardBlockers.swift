import MCP

let cardBlockersTools: [Tool] = [
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
    )
]

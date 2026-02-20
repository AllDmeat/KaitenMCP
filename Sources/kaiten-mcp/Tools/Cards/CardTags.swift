import MCP

let cardTagsTools: [Tool] = [
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
    )
]

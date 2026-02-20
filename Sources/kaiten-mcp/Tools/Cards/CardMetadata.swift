import MCP

let cardMetadataTools: [Tool] = [
  Tool(
      name: "kaiten_get_card_baselines",
      description: "Get card baselines",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"])
        ]),
        "required": .array(["card_id"]),
      ])
    ),
  Tool(
      name: "kaiten_list_card_types",
      description: "List card types",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "limit": .object(["type": "integer", "description": "Max items to return"]),
          "offset": .object(["type": "integer", "description": "Pagination offset"]),
        ]),
      ])
    ),
  Tool(
      name: "kaiten_get_card_location_history",
      description: "Get card location history (column/lane movements)",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"])
        ]),
        "required": .array(["card_id"]),
      ])
    )
]

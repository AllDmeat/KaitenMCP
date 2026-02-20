import MCP

let cardChildrenTools: [Tool] = [
  Tool(
      name: "kaiten_list_card_children",
      description: "List children of a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"])
        ]),
        "required": .array(["card_id"]),
      ])
    ),
  Tool(
      name: "kaiten_add_card_child",
      description: "Add a child card to a parent card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Parent card ID"]),
          "child_card_id": .object(["type": "integer", "description": "Child card ID"]),
        ]),
        "required": .array(["card_id", "child_card_id"]),
      ])
    ),
  Tool(
      name: "kaiten_remove_card_child",
      description: "Remove a child card from a parent card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Parent card ID"]),
          "child_id": .object(["type": "integer", "description": "Child card ID"]),
        ]),
        "required": .array(["card_id", "child_id"]),
      ])
    )
]

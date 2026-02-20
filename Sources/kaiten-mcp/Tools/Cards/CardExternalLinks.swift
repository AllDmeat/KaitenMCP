import MCP

let cardExternalLinksTools: [Tool] = [
  Tool(
      name: "kaiten_list_external_links",
      description: "List external links on a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"])
        ]),
        "required": .array(["card_id"]),
      ])
    ),
  Tool(
      name: "kaiten_add_external_link",
      description: "Add an external link to a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "url": .object(["type": "string", "description": "URL of the external link"]),
          "title": .object(["type": "string", "description": "Title/description of the link"]),
        ]),
        "required": .array(["card_id", "url"]),
      ])
    ),
  Tool(
      name: "kaiten_update_external_link",
      description: "Update an external link on a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "link_id": .object(["type": "integer", "description": "External link ID"]),
          "url": .object(["type": "string", "description": "New URL"]),
          "title": .object(["type": "string", "description": "New title/description"]),
        ]),
        "required": .array(["card_id", "link_id"]),
      ])
    ),
  Tool(
      name: "kaiten_remove_external_link",
      description: "Remove an external link from a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "link_id": .object(["type": "integer", "description": "External link ID"]),
        ]),
        "required": .array(["card_id", "link_id"]),
      ])
    )
]

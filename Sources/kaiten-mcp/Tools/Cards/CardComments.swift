import MCP

let cardCommentsTools: [Tool] = [
  Tool(
      name: "kaiten_get_card_comments",
      description: "Get comments on a card",
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
      name: "kaiten_create_comment",
      description: "Add a comment to a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "text": .object(["type": "string", "description": "Comment text (markdown)"]),
        ]),
        "required": .array(["card_id", "text"]),
      ])
    ),
  Tool(
      name: "kaiten_update_comment",
      description: "Update a comment on a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "comment_id": .object(["type": "integer", "description": "Comment ID"]),
          "text": .object(["type": "string", "description": "New comment text (markdown)"]),
        ]),
        "required": .array(["card_id", "comment_id", "text"]),
      ])
    ),
  Tool(
      name: "kaiten_delete_comment",
      description: "Delete a comment from a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "comment_id": .object(["type": "integer", "description": "Comment ID"]),
        ]),
        "required": .array(["card_id", "comment_id"]),
      ])
    )
]

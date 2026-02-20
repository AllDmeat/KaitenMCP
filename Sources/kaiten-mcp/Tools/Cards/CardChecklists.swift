import MCP

let cardChecklistsTools: [Tool] = [
  Tool(
      name: "kaiten_create_checklist",
      description: "Create a new checklist on a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "name": .object(["type": "string", "description": "Checklist name"]),
          "sort_order": .object(["type": "number", "description": "Sort order position"]),
        ]),
        "required": .array(["card_id", "name"]),
      ])
    ),
  Tool(
      name: "kaiten_get_checklist",
      description: "Get a checklist by ID",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        ]),
        "required": .array(["card_id", "checklist_id"]),
      ])
    ),
  Tool(
      name: "kaiten_update_checklist",
      description: "Update a checklist (name, sort order, or move to another card)",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
          "name": .object(["type": "string", "description": "New checklist name"]),
          "sort_order": .object(["type": "number", "description": "New sort order"]),
          "move_to_card_id": .object([
            "type": "integer", "description": "Move checklist to another card",
          ]),
        ]),
        "required": .array(["card_id", "checklist_id"]),
      ])
    ),
  Tool(
      name: "kaiten_remove_checklist",
      description: "Remove a checklist from a card",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
        ]),
        "required": .array(["card_id", "checklist_id"]),
      ])
    ),
  Tool(
      name: "kaiten_create_checklist_item",
      description: "Create a new item in a checklist",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
          "text": .object(["type": "string", "description": "Item text (1-4096 characters)"]),
          "sort_order": .object(["type": "number", "description": "Sort order (must be > 0)"]),
          "checked": .object(["type": "boolean", "description": "Checked state"]),
          "due_date": .object(["type": "string", "description": "Due date (YYYY-MM-DD)"]),
          "responsible_id": .object(["type": "integer", "description": "Responsible user ID"]),
        ]),
        "required": .array(["card_id", "checklist_id", "text"]),
      ])
    ),
  Tool(
      name: "kaiten_update_checklist_item",
      description: "Update a checklist item",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
          "item_id": .object(["type": "integer", "description": "Checklist item ID"]),
          "text": .object(["type": "string", "description": "Item text (max 4096 characters)"]),
          "sort_order": .object(["type": "number", "description": "Sort order (must be > 0)"]),
          "move_to_checklist_id": .object([
            "type": "integer", "description": "Move item to another checklist",
          ]),
          "checked": .object(["type": "boolean", "description": "Checked state"]),
          "due_date": .object(["type": "string", "description": "Due date (YYYY-MM-DD)"]),
          "responsible_id": .object(["type": "integer", "description": "Responsible user ID"]),
        ]),
        "required": .array(["card_id", "checklist_id", "item_id"]),
      ])
    ),
  Tool(
      name: "kaiten_remove_checklist_item",
      description: "Remove an item from a checklist",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "checklist_id": .object(["type": "integer", "description": "Checklist ID"]),
          "item_id": .object(["type": "integer", "description": "Checklist item ID"]),
        ]),
        "required": .array(["card_id", "checklist_id", "item_id"]),
      ])
    )
]

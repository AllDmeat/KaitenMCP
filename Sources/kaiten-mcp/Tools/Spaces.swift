import MCP

let spacesTools: [Tool] = [
  Tool(
      name: "kaiten_list_spaces",
      description: "List all spaces",
      inputSchema: .object([
        "type": "object",
        "properties": .object([:]),
      ])
    ),
  Tool(
      name: "kaiten_get_space",
      description: "Get a space by ID",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "id": .object(["type": "integer", "description": "Space ID"])
        ]),
        "required": .array(["id"]),
      ])
    ),
  Tool(
      name: "kaiten_create_space",
      description: "Create a new space",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "title": .object(["type": "string", "description": "Space title"]),
          "external_id": .object(["type": "string", "description": "External ID"]),
          "sort_order": .object(["type": "integer", "description": "Sort order"]),
        ]),
        "required": .array(["title"]),
      ])
    ),
  Tool(
      name: "kaiten_update_space",
      description: "Update a space by ID",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "id": .object(["type": "integer", "description": "Space ID"]),
          "title": .object(["type": "string", "description": "New title"]),
          "external_id": .object(["type": "string", "description": "External ID"]),
          "sort_order": .object(["type": "integer", "description": "Sort order"]),
          "access": .object(["type": "integer", "description": "Access level"]),
          "parent_entity_uid": .object(["type": "string", "description": "Parent entity UID"]),
        ]),
        "required": .array(["id"]),
      ])
    ),
  Tool(
      name: "kaiten_delete_space",
      description: "Delete a space by ID",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "id": .object(["type": "integer", "description": "Space ID"])
        ]),
        "required": .array(["id"]),
      ])
    )
]

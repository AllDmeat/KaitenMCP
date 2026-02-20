import MCP

let subcolumnsTools: [Tool] = [
  Tool(
      name: "kaiten_list_subcolumns",
      description: "List subcolumns of a column",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "column_id": .object(["type": "integer", "description": "Column ID"])
        ]),
        "required": .array(["column_id"]),
      ])
    ),
  Tool(
      name: "kaiten_create_subcolumn",
      description: "Create a subcolumn",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "column_id": .object(["type": "integer", "description": "Column ID"]),
          "title": .object(["type": "string", "description": "Subcolumn title"]),
          "sort_order": .object(["type": "integer", "description": "Sort order"]),
          "type": .object(["type": "integer", "description": "Subcolumn type"]),
        ]),
        "required": .array(["column_id", "title"]),
      ])
    ),
  Tool(
      name: "kaiten_update_subcolumn",
      description: "Update a subcolumn",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "column_id": .object(["type": "integer", "description": "Column ID"]),
          "id": .object(["type": "integer", "description": "Subcolumn ID"]),
          "title": .object(["type": "string", "description": "New title"]),
          "sort_order": .object(["type": "integer", "description": "Sort order"]),
          "type": .object(["type": "integer", "description": "Subcolumn type"]),
        ]),
        "required": .array(["column_id", "id"]),
      ])
    ),
  Tool(
      name: "kaiten_delete_subcolumn",
      description: "Delete a subcolumn",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "column_id": .object(["type": "integer", "description": "Column ID"]),
          "id": .object(["type": "integer", "description": "Subcolumn ID"]),
        ]),
        "required": .array(["column_id", "id"]),
      ])
    )
]

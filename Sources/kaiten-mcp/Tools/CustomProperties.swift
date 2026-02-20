import MCP

let customPropertiesTools: [Tool] = [
  Tool(
      name: "kaiten_list_custom_properties",
      description: "List all custom property definitions",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "offset": .object([
            "type": "integer", "description": "Number of items to skip (default: 0)",
          ]),
          "limit": .object(["type": "integer", "description": "Max items to return (default: 100)"]),
          "query": .object(["type": "string", "description": "Search query"]),
          "include_values": .object(["type": "boolean", "description": "Include property values"]),
          "include_author": .object(["type": "boolean", "description": "Include author info"]),
          "compact": .object(["type": "boolean", "description": "Compact response"]),
          "load_by_ids": .object(["type": "boolean", "description": "Load by IDs mode"]),
          "ids": .object([
            "type": "array", "description": "Array of property IDs to load",
            "items": .object(["type": "integer"]),
          ]),
          "order_by": .object(["type": "string", "description": "Sort field"]),
          "order_direction": .object(["type": "string", "description": "Sort direction (asc/desc)"]),
        ]),
      ])
    ),
  Tool(
      name: "kaiten_get_custom_property",
      description: "Get a custom property definition by ID",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "id": .object([
            "type": "integer",
            "description": "Custom property ID",
          ])
        ]),
        "required": .array(["id"]),
      ])
    ),
  Tool(
      name: "kaiten_get_custom_property_select_values",
      description: "Get available select/multi-select values for a custom property",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "property_id": .object(["type": "integer", "description": "Custom property ID"]),
          "query": .object(["type": "string", "description": "Search query"]),
          "offset": .object([
            "type": "integer", "description": "Number of items to skip (default: 0)",
          ]),
          "limit": .object(["type": "integer", "description": "Max items to return (default: 100)"]),
        ]),
        "required": .array(["property_id"]),
      ])
    ),
  Tool(
      name: "kaiten_update_card_properties",
      description:
        "Update custom property values on a card. Property keys use format 'id_{property_id}'. Values: array of value IDs for select/multi-select, or a number for numeric properties. Pass null to remove a property value.",
      inputSchema: .object([
        "type": "object",
        "properties": .object([
          "card_id": .object(["type": "integer", "description": "Card ID"]),
          "properties": .object([
            "type": "object",
            "description":
              "Custom properties to set. Keys: 'id_{property_id}', values: array of value IDs (select) or number (numeric). Pass null to clear.",
            "additionalProperties": .bool(true),
          ]),
        ]),
        "required": .array(["card_id", "properties"]),
      ])
    )
]

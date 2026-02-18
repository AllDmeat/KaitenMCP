# kaiten-mcp

[![Build](https://github.com/AllDmeat/kaiten-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/AllDmeat/kaiten-mcp/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-mcp%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AllDmeat/kaiten-mcp)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAllDmeat%2Fkaiten-mcp%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AllDmeat/kaiten-mcp)

MCP server for [Kaiten](https://kaiten.ru) — gives AI agents access to boards, cards, and properties via [Model Context Protocol](https://modelcontextprotocol.io).

Built on top of [kaiten-sdk](https://github.com/AllDmeat/kaiten-sdk).

## Installation

### mise (recommended)

[mise](https://mise.jdx.dev) — a tool version manager. It will install the required version automatically:

```bash
mise use github:alldmeat/kaiten-mcp
```

### GitHub Release

Download the binary for your platform from the [releases page](https://github.com/AllDmeat/kaiten-mcp/releases).

### From Source

```bash
swift build -c release
# Binary: .build/release/kaiten-mcp
```

## Usage

### Configuration

Credentials are stored in `~/.config/kaiten/config.json` (shared with the [CLI](https://github.com/AllDmeat/kaiten-sdk)):

```json
{
  "url": "https://your-company.kaiten.ru/api/latest",
  "token": "your-api-token"
}
```

You can also configure credentials via the `kaiten_set_token` MCP tool after connecting the server.

Kaiten token: Profile Settings → API Tokens → Create.

### Connecting

#### Claude Desktop

`~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "/path/to/kaiten-mcp"
    }
  }
}
```

#### Cursor

Settings → MCP Servers → Add:

```json
{
  "kaiten": {
    "command": "/path/to/kaiten-mcp"
  }
}
```

## API Reference

### Cards

| Tool | Description |
|------|-------------|
| `kaiten_list_cards` | List cards on a board (paginated) |
| `kaiten_get_card` | Get a card by ID |
| `kaiten_create_card` | Create a new card |
| `kaiten_update_card` | Update a card |
| `kaiten_get_card_members` | Get card members |
| `kaiten_get_card_comments` | Get card comments |
| `kaiten_create_comment` | Add a comment to a card |
| `kaiten_get_card_baselines` | Get card baselines |

### Spaces

| Tool | Description |
|------|-------------|
| `kaiten_list_spaces` | List all spaces |
| `kaiten_create_space` | Create a space |
| `kaiten_get_space` | Get a space by ID |
| `kaiten_update_space` | Update a space |
| `kaiten_delete_space` | Delete a space |

### Boards

| Tool | Description |
|------|-------------|
| `kaiten_list_boards` | List boards in a space |
| `kaiten_get_board` | Get a board by ID |
| `kaiten_create_board` | Create a board |
| `kaiten_update_board` | Update a board |
| `kaiten_delete_board` | Delete a board |

### Columns

| Tool | Description |
|------|-------------|
| `kaiten_get_board_columns` | Get columns of a board |
| `kaiten_create_column` | Create a column |
| `kaiten_update_column` | Update a column |
| `kaiten_delete_column` | Delete a column |
| `kaiten_list_subcolumns` | List subcolumns |
| `kaiten_create_subcolumn` | Create a subcolumn |
| `kaiten_update_subcolumn` | Update a subcolumn |
| `kaiten_delete_subcolumn` | Delete a subcolumn |

### Lanes

| Tool | Description |
|------|-------------|
| `kaiten_get_board_lanes` | Get lanes of a board |
| `kaiten_create_lane` | Create a lane |
| `kaiten_update_lane` | Update a lane |
| `kaiten_delete_lane` | Delete a lane |

### Custom Properties

| Tool | Description |
|------|-------------|
| `kaiten_list_custom_properties` | List custom property definitions |
| `kaiten_get_custom_property` | Get a custom property by ID |

### Sprints

| Tool | Description |
|------|-------------|
| `kaiten_get_sprint_summary` | Get sprint summary |

### Settings

| Tool | Description |
|------|-------------|
| `kaiten_configure` | Manage preferences (boards/spaces) |
| `kaiten_get_preferences` | Get current preferences |
| `kaiten_set_token` | Save URL and token to config |

## Configuration

The config file at `~/.config/kaiten/config.json` is shared between MCP and [CLI](https://github.com/AllDmeat/kaiten-sdk). You only need to configure it once.

```json
{
  "url": "https://your-company.kaiten.ru/api/latest",
  "token": "your-api-token"
}
```

User preferences are stored separately in `~/.config/kaiten/preferences.json`:

```json
{
  "myBoards": [
    { "id": 123, "alias": "team" }
  ],
  "mySpaces": [
    { "id": 456 }
  ]
}
```

## Requirements

- Swift 6.2+
- macOS 15+ (ARM) / Linux (x86-64, ARM)

## License

MIT

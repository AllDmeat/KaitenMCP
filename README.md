# kaiten-mcp

[![Build](https://github.com/AllDmeat/kaiten-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/AllDmeat/kaiten-mcp/actions/workflows/ci.yml)

MCP server for [Kaiten](https://kaiten.ru) — gives AI agents access to boards, cards, and properties via [Model Context Protocol](https://modelcontextprotocol.io).

Built on top of [kaiten-sdk](https://github.com/AllDmeat/kaiten-sdk).

## Requirements

- Swift 6.2+
- macOS 15+ or Linux (x86_64, ARM64)

## Installation

### mise (recommended)

[mise](https://mise.jdx.dev) — a tool manager. It will install the required version automatically:

```bash
mise use github:AllDmeat/kaiten-mcp
```

### From GitHub Release

Download the binary for your platform from the [releases page](https://github.com/AllDmeat/kaiten-mcp/releases):

- `kaiten-mcp_<version>_darwin_arm64.tar.gz` — macOS (Apple Silicon)
- `kaiten-mcp_<version>_linux_x86_64.tar.gz` — Linux x86_64
- `kaiten-mcp_<version>_linux_arm64.tar.gz` — Linux ARM64

### From source

```bash
swift build -c release
# Binary: .build/release/kaiten-mcp
```

## Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `kaiten_list_spaces` | List spaces | — |
| `kaiten_list_boards` | Boards in a space | `space_id` |
| `kaiten_get_board` | Board by ID | `id` |
| `kaiten_get_board_columns` | Board columns | `board_id` |
| `kaiten_get_board_lanes` | Board lanes | `board_id` |
| `kaiten_list_cards` | Cards on a board (paginated) | `board_id`, `offset?`, `limit?` |
| `kaiten_get_card` | Card by ID | `id` |
| `kaiten_get_card_members` | Card members | `card_id` |
| `kaiten_list_custom_properties` | Custom properties | — |
| `kaiten_get_custom_property` | Custom property by ID | `id` |
| `kaiten_configure` | Manage preferences (boards/spaces) | `action`, `ids?`, `id?`, `alias?` |
| `kaiten_get_preferences` | Current preferences | — |
| `kaiten_set_token` | Save URL and token to config | `url?`, `token?` |

## Configuration

Credentials are stored in `config.json`, user preferences in `preferences.json`:

| File | Path | Contents |
|------|------|----------|
| `config.json` | `~/.config/kaiten-mcp/config.json` | `url`, `token` |
| `preferences.json` | `~/.config/kaiten-mcp/preferences.json` | `myBoards`, `mySpaces` |

The path is the same on all platforms (macOS, Linux).

`config.json` is shared between MCP and [CLI](https://github.com/AllDmeat/kaiten-sdk). You only need to configure it once.

`config.json`:

```json
{
  "url": "https://your-company.kaiten.ru/api/latest",
  "token": "your-api-token"
}
```

`preferences.json`:

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

You can also configure credentials via the `kaiten_set_token` MCP tool after connecting the server.

Kaiten token: Profile Settings → API Tokens → Create.

## Connecting

### Claude Desktop

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

### Cursor

Settings → MCP Servers → Add:

```json
{
  "kaiten": {
    "command": "/path/to/kaiten-mcp"
  }
}
```

## License

MIT

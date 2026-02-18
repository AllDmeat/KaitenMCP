# Integration Guide

How to connect **kaiten-mcp** to popular AI tools.

> **Prerequisites** — install kaiten-mcp and configure credentials first. See the main [README](../README.md#usage).

All examples below use `kaiten-mcp` as the command. If you installed via [mise](https://mise.jdx.dev), it is already in your `PATH`.

## Table of Contents

- [Claude Desktop](#claude-desktop)
- [Claude Code (CLI)](#claude-code-cli)
- [GitHub Copilot (VS Code)](#github-copilot-vs-code)
- [GitHub Copilot CLI](#github-copilot-cli)
- [Cursor](#cursor)
- [OpenAI Codex CLI](#openai-codex-cli)
- [Windsurf](#windsurf)

---

## Claude Desktop

> User-level only — Claude Desktop does not support project-level MCP configuration.

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

Restart Claude Desktop to apply.

---

## Claude Code (CLI)

### Project-level

Create `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

Or use the CLI:

```bash
claude mcp add kaiten --scope project -- kaiten-mcp
```

### User-level

Edit `~/.claude.json`:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

Or use the CLI:

```bash
claude mcp add kaiten --scope user -- kaiten-mcp
```

---

## GitHub Copilot (VS Code)

### Project-level

Create `.vscode/mcp.json` in your project root:

```json
{
  "servers": {
    "kaiten": {
      "type": "stdio",
      "command": "kaiten-mcp"
    }
  }
}
```

### User-level

Open VS Code **Settings (JSON)** and add:

```json
{
  "mcp": {
    "servers": {
      "kaiten": {
        "type": "stdio",
        "command": "kaiten-mcp"
      }
    }
  }
}
```

After adding, open the Command Palette → **MCP: List Servers** → start the server.

---

## GitHub Copilot CLI

> User-level only — Copilot CLI does not auto-detect project-level MCP configs ([tracking issue](https://github.com/github/copilot-cli/issues/1291)). It does pick up `.vscode/mcp.json` if present.

Create or edit `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp",
      "args": []
    }
  }
}
```

---

## Cursor

Cursor IDE and Cursor CLI share the same configuration format.

### Project-level

Create `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

### User-level

Create or edit `~/.cursor/mcp.json` (macOS/Linux) or `%APPDATA%\Cursor\mcp.json` (Windows):

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

You can also add the server via **Settings → Tools & MCP → Add MCP Server**.

---

## OpenAI Codex CLI

Codex CLI uses TOML configuration.

### Project-level

Create `.codex/config.toml` in your project root:

```toml
[mcp_servers.kaiten]
command = "kaiten-mcp"
```

### User-level

Edit `~/.codex/config.toml`:

```toml
[mcp_servers.kaiten]
command = "kaiten-mcp"
```

---

## Windsurf

> User-level only — Windsurf does not support project-level MCP configuration.

1. Open **Settings → Advanced Settings → Cascade** and enable **Model Context Protocol (MCP)**.
2. Edit `~/.codeium/windsurf/mcp_config.json` (macOS/Linux) or `%USERPROFILE%\.codeium\windsurf\mcp_config.json` (Windows):

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "kaiten-mcp"
    }
  }
}
```

Click **Refresh** in the MCP toolbar to load the server.

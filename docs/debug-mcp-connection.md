# Debug: MCP server fails to connect from Claude Code

GitHub Issue: https://github.com/AllDmeat/KaitenMCP/issues/12

## Problem

Claude Code shows "failed to connect" when trying to connect to the kaiten MCP server.

## What works

- `swift build -c release` — builds successfully
- Manual launch with env variables — works (server hangs, waiting for JSON-RPC on stdin):
  ```bash
  export KAITEN_URL=https://dodopizza.kaiten.ru
  export KAITEN_TOKEN=xxx
  .build/release/kaiten-mcp
  # (no output — this is correct, waiting for stdin)
  ```
- Other MCP servers in Claude Code work (context7 — http type)

## What does NOT work

### Option 1: env in .mcp.json
```json
{
  "mcpServers": {
    "kaiten": {
      "command": "/Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp",
      "env": {
        "KAITEN_URL": "https://dodopizza.kaiten.ru",
        "KAITEN_TOKEN": "xxx"
      }
    }
  }
}
```
Result: failed to connect

### Option 2: env via command
```json
{
  "mcpServers": {
    "kaiten": {
      "command": "env",
      "args": [
        "KAITEN_URL=https://dodopizza.kaiten.ru",
        "KAITEN_TOKEN=xxx",
        "/Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp"
      ]
    }
  }
}
```
Result: failed to connect

## Diagnostics

Logging to `/tmp/kaiten-mcp.log` was added to the binary at startup. After a connection attempt, the file is NOT created — meaning **Claude Code does not launch the binary at all**.

## What to check

1. Path to binary — does `command` in `.mcp.json` match the actual path?
   ```bash
   ls -la /Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp
   ```

2. Execute permissions?
   ```bash
   file /Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp
   ```

3. Try `type: "stdio"` explicitly:
   ```json
   {
     "mcpServers": {
       "kaiten": {
         "type": "stdio",
         "command": "/Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp",
         "env": {
           "KAITEN_URL": "https://dodopizza.kaiten.ru",
           "KAITEN_TOKEN": "xxx"
         }
       }
     }
   }
   ```

4. Try a shell wrapper:
   ```json
   {
     "mcpServers": {
       "kaiten": {
         "command": "bash",
         "args": ["-c", "KAITEN_URL=https://dodopizza.kaiten.ru KAITEN_TOKEN=xxx /Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp"]
       }
     }
   }
   ```

5. Check Claude Code logs:
   ```bash
   /mcp
   ```
   In Claude Code — shows the status of each server and errors.

6. Verify that `.mcp.json` is valid:
   ```bash
   python3 -c "import json; json.load(open('.mcp.json'))"
   ```

## Architecture

- MCP server: Swift executable, stdio transport (StdioTransport from modelcontextprotocol/swift-sdk)
- Reads KAITEN_URL and KAITEN_TOKEN from env via ProcessInfo
- On startup creates KaitenClient, registers MCP Server with tools capability
- Runs `server.start(transport: StdioTransport())`

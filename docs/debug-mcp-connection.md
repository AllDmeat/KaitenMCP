# Debug: MCP сервер не подключается из Claude Code

GitHub Issue: https://github.com/AllDmeat/KaitenMCP/issues/12

## Проблема

Claude Code показывает "failed to connect" при попытке подключиться к kaiten MCP-серверу.

## Что работает

- `swift build -c release` — собирается успешно
- Ручной запуск с env переменными — работает (сервер висит, ждёт JSON-RPC на stdin):
  ```bash
  export KAITEN_URL=https://dodopizza.kaiten.ru
  export KAITEN_TOKEN=xxx
  .build/release/kaiten-mcp
  # (ничего не выводит — это правильно, ждёт stdin)
  ```
- Другие MCP-серверы в Claude Code работают (context7 — http type)

## Что НЕ работает

### Вариант 1: env в .mcp.json
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
Результат: failed to connect

### Вариант 2: env через command
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
Результат: failed to connect

## Диагностика

В бинарь добавлено логирование в `/tmp/kaiten-mcp.log` при старте. После попытки подключения файл НЕ создаётся — значит **Claude Code не запускает бинарь вообще**.

## Что проверить

1. Путь к бинарю — совпадает ли `command` в `.mcp.json` с реальным путём?
   ```bash
   ls -la /Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp
   ```

2. Права на исполнение?
   ```bash
   file /Users/alldmeat/Developer/KaitenMCP/.build/release/kaiten-mcp
   ```

3. Попробовать `type: "stdio"` явно:
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

4. Попробовать обёртку через shell:
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

5. Посмотреть логи Claude Code:
   ```bash
   /mcp
   ```
   В Claude Code — показывает статус каждого сервера и ошибки.

6. Проверить что `.mcp.json` валидный:
   ```bash
   python3 -c "import json; json.load(open('.mcp.json'))"
   ```

## Архитектура

- MCP-сервер: Swift executable, stdio transport (StdioTransport из modelcontextprotocol/swift-sdk)
- Читает KAITEN_URL и KAITEN_TOKEN из env через ProcessInfo
- При старте создаёт KaitenClient, регистрирует MCP Server с tools capability
- Запускает `server.start(transport: StdioTransport())`

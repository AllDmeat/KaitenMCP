# KaitenMCP

MCP-сервер для [Kaiten](https://kaiten.ru) — даёт AI-агентам доступ к доскам, карточкам и свойствам через [Model Context Protocol](https://modelcontextprotocol.io).

Построен поверх [KaitenSDK](https://github.com/AllDmeat/KaitenSDK).

## Tools

| Tool | Описание | Параметры |
|------|----------|-----------|
| `kaiten_list_spaces` | Список пространств | — |
| `kaiten_list_boards` | Доски в пространстве | `space_id` |
| `kaiten_get_board` | Доска по ID | `id` |
| `kaiten_get_board_columns` | Колонки доски | `board_id` |
| `kaiten_get_board_lanes` | Лейны доски | `board_id` |
| `kaiten_list_cards` | Карточки на доске | `board_id` |
| `kaiten_get_card` | Карточка по ID | `id` |
| `kaiten_get_card_members` | Участники карточки | `card_id` |
| `kaiten_list_custom_properties` | Кастомные свойства | — |
| `kaiten_get_custom_property` | Кастомное свойство по ID | `id` |

## Установка

### Из GitHub Release

Скачайте бинарь для вашей платформы со [страницы релизов](https://github.com/AllDmeat/KaitenMCP/releases).

### Из исходников

```bash
swift build -c release
# Бинарь: .build/release/kaiten-mcp
```

## Конфигурация

Создайте `.env` (или экспортируйте переменные иначе):

```bash
cp env.example .env
# Отредактируйте .env:
# KAITEN_URL=https://your-company.kaiten.ru
# KAITEN_TOKEN=your-api-token
```

Токен Kaiten: Настройки профиля → API-токены → Создать.

## Подключение

### Claude Desktop

`~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "kaiten": {
      "command": "/path/to/kaiten-mcp",
      "env": {
        "KAITEN_URL": "https://your-company.kaiten.ru",
        "KAITEN_TOKEN": "your-token"
      }
    }
  }
}
```

### OpenClaw

В конфиге OpenClaw (`gateway.yaml`), секция `mcp`:

```yaml
mcp:
  servers:
    - name: kaiten
      command: /path/to/kaiten-mcp
      env:
        KAITEN_URL: https://your-company.kaiten.ru
        KAITEN_TOKEN: your-token
```

### Cursor

Settings → MCP Servers → Add:

```json
{
  "kaiten": {
    "command": "/path/to/kaiten-mcp",
    "env": {
      "KAITEN_URL": "https://your-company.kaiten.ru",
      "KAITEN_TOKEN": "your-token"
    }
  }
}
```

## Требования

- Swift 6.0+
- macOS 15+ или Linux

## Лицензия

MIT

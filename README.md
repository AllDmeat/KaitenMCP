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
| `kaiten_list_cards` | Карточки на доске (пагинация) | `board_id`, `offset?`, `limit?` |
| `kaiten_get_card` | Карточка по ID | `id` |
| `kaiten_get_card_members` | Участники карточки | `card_id` |
| `kaiten_list_custom_properties` | Кастомные свойства | — |
| `kaiten_get_custom_property` | Кастомное свойство по ID | `id` |
| `kaiten_configure` | Управление предпочтениями (доски/пространства) | `action`, `ids?`, `id?`, `alias?` |
| `kaiten_get_preferences` | Текущие предпочтения | — |
| `kaiten_set_token` | Сохранить URL и токен в конфиг | `url?`, `token?` |

## Установка

### mise (рекомендуется)

[mise](https://mise.jdx.dev) — менеджер инструментов. Установит нужную версию автоматически:

```bash
mise use -g ubi:AllDmeat/KaitenMCP
```

### Из GitHub Release

Скачайте бинарь для вашей платформы со [страницы релизов](https://github.com/AllDmeat/KaitenMCP/releases):

- `kaiten-mcp_<version>_darwin_arm64.tar.gz` — macOS (Apple Silicon)
- `kaiten-mcp_<version>_linux_x86_64.tar.gz` — Linux x86_64
- `kaiten-mcp_<version>_linux_arm64.tar.gz` — Linux ARM64

### Из исходников

```bash
swift build -c release
# Бинарь: .build/release/kaiten-mcp
```

## Конфигурация

Credentials хранятся в `config.json`, пользовательские предпочтения — в `preferences.json`:

| Файл | Путь | Содержимое |
|------|------|------------|
| `config.json` | `~/.config/kaiten-mcp/config.json` | `url`, `token` |
| `preferences.json` | `~/.config/kaiten-mcp/preferences.json` | `myBoards`, `mySpaces` |

Путь одинаковый на всех платформах (macOS, Linux).

`config.json` — общий для MCP и [CLI](https://github.com/AllDmeat/KaitenSDK). Достаточно настроить один раз.

### Вручную

```bash
mkdir -p ~/.config/kaiten-mcp
cat > ~/.config/kaiten-mcp/config.json << 'EOF'
{
  "url": "https://your-company.kaiten.ru/api/latest",
  "token": "your-api-token"
}
EOF
chmod 600 ~/.config/kaiten-mcp/config.json
```

### Через MCP-тул

После подключения сервера вызовите `kaiten_set_token` с параметрами `url` и `token` — файл создастся автоматически.

Токен Kaiten: Настройки профиля → API-токены → Создать.

## Подключение

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

### OpenClaw

В конфиге OpenClaw (`gateway.yaml`), секция `mcp`:

```yaml
mcp:
  servers:
    - name: kaiten
      command: /path/to/kaiten-mcp
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

## Требования

- Swift 6.0+
- macOS 15+ или Linux

## Лицензия

MIT

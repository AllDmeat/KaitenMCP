# Feature Specification: KaitenMCP Server

**Created**: 2026-02-15
**Status**: Draft

## User Scenarios & Testing

### User Story 1 — AI-агент читает карточки с доски (Priority: P1)

AI-агент (Claude Desktop, OpenClaw, Cursor) подключается к KaitenMCP через stdio и получает информацию о карточках на доске Kaiten: список карточек, детали конкретной карточки, участников карточки.

**Why this priority**: Карточки — основная сущность Kaiten. Без доступа к ним остальные tools бесполезны.

**Independent Test**: Запустить MCP-сервер, вызвать `kaiten_list_cards` с board_id, получить JSON-массив карточек.

**Acceptance Scenarios**:

1. **Given** сервер запущен с валидными KAITEN_URL и KAITEN_TOKEN, **When** клиент вызывает `kaiten_list_cards` с board_id, **Then** возвращается JSON-массив карточек
2. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_card` с id существующей карточки, **Then** возвращается JSON-объект карточки
3. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_card` с несуществующим id, **Then** возвращается ошибка с isError=true
4. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_card_members` с card_id, **Then** возвращается JSON-массив участников

---

### User Story 2 — AI-агент навигирует по структуре Kaiten (Priority: P1)

AI-агент просматривает пространства, доски, колонки и лейны для понимания структуры проекта.

**Why this priority**: Чтобы вызвать `kaiten_list_cards`, нужно знать board_id. Навигация по структуре — необходимый шаг.

**Independent Test**: Вызвать `kaiten_list_spaces`, получить пространства, затем `kaiten_list_boards` для пространства.

**Acceptance Scenarios**:

1. **Given** сервер запущен, **When** клиент вызывает `kaiten_list_spaces`, **Then** возвращается JSON-массив пространств
2. **Given** сервер запущен, **When** клиент вызывает `kaiten_list_boards` с space_id, **Then** возвращается JSON-массив досок
3. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_board` с id, **Then** возвращается JSON-объект доски
4. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_board_columns` с board_id, **Then** возвращается JSON-массив колонок
5. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_board_lanes` с board_id, **Then** возвращается JSON-массив лейнов

---

### User Story 3 — AI-агент работает с кастомными свойствами (Priority: P2)

AI-агент получает информацию о кастомных свойствах карточек (custom properties) — их определения и значения.

**Why this priority**: Кастомные свойства нужны для полного понимания карточек, но базовая навигация работает и без них.

**Independent Test**: Вызвать `kaiten_list_custom_properties`, получить список определений.

**Acceptance Scenarios**:

1. **Given** сервер запущен, **When** клиент вызывает `kaiten_list_custom_properties`, **Then** возвращается JSON-массив определений свойств
2. **Given** сервер запущен, **When** клиент вызывает `kaiten_get_custom_property` с id, **Then** возвращается JSON-объект свойства

---

### Edge Cases

- Что если KAITEN_URL или KAITEN_TOKEN не заданы? → Сервер должен упасть при старте с понятной ошибкой
- Что если токен невалидный / истёк? → Tool возвращает isError=true с сообщением об unauthorized
- Что если Kaiten API недоступен (таймаут, 5xx)? → Tool возвращает isError=true, retry-логика в SDK
- Что если аргумент tool невалидный (отрицательный id, отсутствует обязательный параметр)? → Tool возвращает isError=true с описанием ошибки

## Requirements

### Functional Requirements

- **FR-001**: Сервер MUST запускаться как stdio MCP-сервер
- **FR-002**: Сервер MUST читать KAITEN_URL и KAITEN_TOKEN из environment variables
- **FR-003**: Сервер MUST предоставлять tool для каждого публичного метода KaitenSDK
- **FR-004**: Каждый tool MUST возвращать данные в формате JSON
- **FR-005**: Каждый tool MUST возвращать isError=true при ошибках SDK с описанием ошибки
- **FR-006**: Сервер MUST падать при старте если KAITEN_URL или KAITEN_TOKEN отсутствуют
- **FR-007**: Сервер MUST использовать KaitenSDK как зависимость, без дублирования бизнес-логики
- **FR-008**: Сервер MUST собираться как executable Swift package (Swift 6.0+, macOS + Linux)
- **FR-009**: Сервер MUST иметь CI через GitHub Actions (билд + линт на macOS и Linux)
- **FR-010**: При создании тега MUST запускаться release-джоба, которая собирает бинари (macOS + Linux) и прикрепляет их как артефакты к GitHub Release
- **FR-011**: Сервер MUST иметь README с описанием, списком tools и примером подключения к Claude Desktop и OpenClaw

### Key Entities

- **Tool**: MCP-инструмент = name + description + inputSchema + handler. 1:1 с методом KaitenSDK.
- **KaitenClient**: Единственный экземпляр SDK-клиента, создаётся при старте, передаётся в handlers.

## Architecture Decisions

- **Вариант A (тонкий маппинг)**: каждый MCP tool — адаптер из 5-15 строк над методом SDK
- **Без протокола-абстракции** на старте — KaitenClient используется напрямую. Протокол добавим когда появится второй потребитель (API)
- **MCP Swift SDK**: `modelcontextprotocol/swift-sdk` v0.10+
- **Transport**: только stdio
- **Без тестов** на старте — сервер тонкий, тестируем руками
- **Write-операции**: SDK будет расширяться, архитектура tools не мешает добавлению
- **`nonisolated(unsafe)` запрещён** — использовать `Mutex` из `Synchronization` (аналогично правилу FR-014 в KaitenSDK)

## Success Criteria

- **SC-001**: MCP-сервер запускается через `kaiten-mcp` и отвечает на `tools/list`
- **SC-002**: Все 10 tools вызываются и возвращают корректный JSON из Kaiten API
- **SC-003**: Ошибки SDK транслируются в isError=true с читаемым сообщением
- **SC-004**: CI зелёный (билд + линт)
- **SC-005**: README достаточен для подключения сервера к Claude Desktop / OpenClaw за 5 минут

# Feature Specification: KaitenMCP Server

**Created**: 2026-02-15
**Status**: Draft

## User Scenarios & Testing

### User Story 1 — AI agent reads cards from a board (Priority: P1)

An AI agent (Claude Desktop, OpenClaw, Cursor) connects to KaitenMCP via stdio and retrieves information about cards on a Kaiten board: card list, details of a specific card, card members.

**Why this priority**: Cards are the core entity in Kaiten. Without access to them, other tools are useless.

**Independent Test**: Start the MCP server, call `kaiten_list_cards` with board_id, receive a JSON array of cards.

**Acceptance Scenarios**:

1. **Given** the server is running with valid KAITEN_URL and KAITEN_TOKEN, **When** the client calls `kaiten_list_cards` with board_id, **Then** a JSON array of cards is returned
2. **Given** the server is running, **When** the client calls `kaiten_get_card` with the id of an existing card, **Then** a JSON card object is returned
3. **Given** the server is running, **When** the client calls `kaiten_get_card` with a non-existent id, **Then** an error with isError=true is returned
4. **Given** the server is running, **When** the client calls `kaiten_get_card_members` with card_id, **Then** a JSON array of members is returned

---

### User Story 2 — AI agent navigates the Kaiten structure (Priority: P1)

An AI agent browses spaces, boards, columns, and lanes to understand the project structure.

**Why this priority**: To call `kaiten_list_cards`, you need to know the board_id. Navigating the structure is a necessary step.

**Independent Test**: Call `kaiten_list_spaces`, get spaces, then `kaiten_list_boards` for a space.

**Acceptance Scenarios**:

1. **Given** the server is running, **When** the client calls `kaiten_list_spaces`, **Then** a JSON array of spaces is returned
2. **Given** the server is running, **When** the client calls `kaiten_list_boards` with space_id, **Then** a JSON array of boards is returned
3. **Given** the server is running, **When** the client calls `kaiten_get_board` with id, **Then** a JSON board object is returned
4. **Given** the server is running, **When** the client calls `kaiten_get_board_columns` with board_id, **Then** a JSON array of columns is returned
5. **Given** the server is running, **When** the client calls `kaiten_get_board_lanes` with board_id, **Then** a JSON array of lanes is returned

---

### User Story 3 — AI agent works with custom properties (Priority: P2)

An AI agent retrieves information about custom card properties — their definitions and values.

**Why this priority**: Custom properties are needed for full understanding of cards, but basic navigation works without them.

**Independent Test**: Call `kaiten_list_custom_properties`, get a list of definitions.

**Acceptance Scenarios**:

1. **Given** the server is running, **When** the client calls `kaiten_list_custom_properties`, **Then** a JSON array of property definitions is returned
2. **Given** the server is running, **When** the client calls `kaiten_get_custom_property` with id, **Then** a JSON property object is returned

---

### Edge Cases

- What if url/token are not configured? → Server starts successfully; API tools fail at call time with a clear error that asks to run `kaiten_login`
- What if the token is invalid / expired? → Tool returns isError=true with an unauthorized message
- What if the Kaiten API is unavailable (timeout, 5xx)? → Tool returns isError=true, retry logic in SDK
- What if a tool argument is invalid (negative id, missing required parameter)? → Tool returns isError=true with an error description
- What if the log file does not exist yet? → The log tool returns an empty content string with the resolved log file path

## Requirements

### Functional Requirements

- **FR-001**: The server MUST start as a stdio MCP server
- **FR-002**: The server MUST load credentials from shared config file `~/.config/kaiten/config.json` (`url`, `token`)
- **FR-003**: The server MUST provide a tool for each public KaitenSDK method. Every public method on `KaitenClient` MUST have a corresponding MCP tool — there MUST be a 1:1 mapping between SDK public API surface and MCP tools. When new methods are added to KaitenSDK, corresponding MCP tools MUST be added before the next release.
- **FR-003a**: When upgrading the KaitenSDK dependency to a new version, the developer MUST diff the public API surface of `KaitenClient` (all `public func` declarations) between the old and new SDK versions. New methods MUST get corresponding MCP tools, removed methods MUST have their MCP tools deleted, and changed signatures MUST be reflected in tool definitions and handlers. This audit MUST happen as part of every SDK version bump PR.
- **FR-004**: Each tool MUST return data in JSON format
- **FR-005**: Each tool MUST return isError=true on SDK errors with an error description
- **FR-006**: The server MUST start even if `url` or `token` are missing in config
- **FR-012**: The server MUST validate `url` and `token` lazily when an API-backed tool is called, and return `isError=true` with an actionable message if credentials are missing
- **FR-013**: The server MUST provide MCP tool `kaiten_login` that accepts `url` and `token`, validates both values, and saves them to `~/.config/kaiten/config.json`
- **FR-014**: The server MUST provide MCP tool `kaiten_read_logs` that returns MCP log file path and text content for troubleshooting, with optional tail limiting
- **FR-007**: The server MUST use KaitenSDK as a dependency, without duplicating business logic
- **FR-008**: The server MUST build as an executable Swift package (Swift 6.0+, macOS + Linux)
- **FR-009**: The server MUST have CI via GitHub Actions (build + lint on macOS and Linux)
- **FR-010**: On tag creation, a release job MUST run that builds binaries (macOS + Linux) and attaches them as artifacts to the GitHub Release
- **FR-011**: The server MUST have a README with a description, tool list, and connection examples for Claude Desktop and OpenClaw

### Key Entities

- **Tool**: MCP tool = name + description + inputSchema + handler. 1:1 with a KaitenSDK method.
- **KaitenClient**: Single SDK client instance, created at startup, passed to handlers.

## Architecture Decisions

- **Option A (thin mapping)**: each MCP tool is an adapter of 5–15 lines over an SDK method
- **No protocol abstraction** at the start — KaitenClient is used directly. A protocol will be added when a second consumer (API) appears
- **MCP Swift SDK**: `modelcontextprotocol/swift-sdk` v0.10+
- **Transport**: stdio only
- **No tests** at the start — the server is thin, tested manually
- **Write operations**: The SDK will be extended; the tools architecture does not prevent additions
- **`nonisolated(unsafe)` is forbidden** — use `Mutex` from `Synchronization` (same as rule FR-014 in KaitenSDK)

## Success Criteria

- **SC-001**: The MCP server starts via `kaiten-mcp` and responds to `tools/list`
- **SC-002**: All 10 tools are callable and return correct JSON from the Kaiten API
- **SC-003**: SDK errors are translated to isError=true with a readable message
- **SC-004**: CI is green (build + lint)
- **SC-005**: The README is sufficient to connect the server to Claude Desktop / OpenClaw in 5 minutes

# Research: MCP Prompts for KaitenMCP

## What are MCP Prompts?

Prompts are server-exposed **message templates** that clients can discover and invoke. Think of them as pre-built conversation starters or reference materials that an LLM can use.

Key properties:
- **User-controlled** — designed to be explicitly selected by the user (e.g., slash commands)
- **Parameterized** — can accept arguments to customize the output
- **Structured** — return `PromptMessage[]` with role (user/assistant) and content (text/image/resource)
- **Discoverable** — clients list available prompts via `prompts/list`

### How it works

1. Server declares `capabilities.prompts` during init
2. Client calls `prompts/list` → gets available prompts with names, descriptions, arguments
3. Client calls `prompts/get(name, arguments)` → gets `PromptMessage[]`
4. Client injects these messages into the LLM conversation

### Swift SDK support

The `swift-sdk` (MCP package we use) fully supports prompts:
- `Prompt` struct with `name`, `description`, `arguments`
- `Prompt.Message` with `.user()` / `.assistant()` factory methods
- `ListPrompts` / `GetPrompt` method handlers
- Server capability: `.init(prompts: .init(listChanged: false))`

## Client support

| Client | MCP support | Prompts | Notes |
|--------|------------|---------|-------|
| Claude Desktop | ✅ | ✅ | Slash commands in chat |
| Cursor | ✅ | ❌ | Tools only |
| GitHub Copilot (VS Code, JetBrains, Xcode) | ✅ | ❌ | Tools + resources, no prompts in docs |
| Codex (OpenAI) | N/A | N/A | Cloud agent, not an MCP client |
| Gemini (Google) | ✅ (announced) | ❓ | MCP support announced, details unclear |
| Zed | ✅ | ✅ | Slash commands |
| Cline | ✅ | ✅ | Menu selection |
| OpenClaw | ✅ | ❓ | Needs testing |

**Bottom line:** The "big three" IDE integrations (Copilot, Cursor, Codex) do NOT support prompts. Only Claude Desktop, Zed, and Cline do. This significantly limits the reach of prompts-only solutions.

**Recommendation update:** Given poor client support, a **hybrid approach** is likely best — prompts for clients that support them, plus brief hints in tool descriptions as a universal fallback.

## Potential prompts for KaitenMCP

### 1. `kaiten_field_reference` — Field value glossary

No arguments. Returns a reference card explaining magic values:

```
condition: 1=active, 2=archived
column.type: 1=queue, 2=in_progress, 3=done (TBD — verify)
wip_limit_type: 1=by_column, 2=by_cell (TBD — verify)
```

**Use case:** Agent encounters `condition: 2` and doesn't know what it means → user invokes prompt → agent gets the glossary.

### 2. `kaiten_board_overview` — Board status summary

Arguments: `board_id` (required)

Returns a structured prompt asking the LLM to:
1. Fetch board columns, lanes, and cards
2. Summarize: how many cards per column, blocked items, WIP limits
3. Highlight anything unusual

**Use case:** "Give me a sprint overview" → user selects prompt → agent follows the template.

### 3. `kaiten_sprint_status` — Sprint progress report

Arguments: `board_id` (required), `sprint_name` (optional)

Returns a prompt template for generating sprint status:
- Cards done vs in progress vs blocked
- Who's working on what
- Risks and blockers

### 4. `kaiten_card_deep_dive` — Detailed card analysis

Arguments: `card_id` (required)

Returns a prompt that asks the agent to fetch card details, members, properties, and provide a structured summary.

## Recommendation

**Start with `kaiten_field_reference`** — it's the simplest (no arguments, static content), solves a real problem (#43), and validates the prompts infrastructure.

Then add `kaiten_board_overview` as the first parameterized prompt.

### Tradeoffs vs alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **Prompts** | Clean separation, discoverable, scalable | Not all clients support it (Cursor ❌) |
| **Tool descriptions** | Works everywhere, always visible | Bloats descriptions, hard to maintain |
| **Dedicated reference tool** | Works everywhere, on-demand | Extra tool call, pollutes tool list |

**Hybrid approach possible:** Use prompts as primary, and also add brief hints in tool descriptions for clients that don't support prompts (e.g., "condition: 1=active, 2=archived" in `kaiten_get_board_lanes` description).

## Implementation notes

```swift
// Add prompts capability
let server = Server(
    name: "KaitenMCP",
    version: "0.2.1",
    capabilities: .init(
        prompts: .init(listChanged: false),
        tools: .init(listChanged: false)
    )
)

// Register prompt handlers
await server.withMethodHandler(ListPrompts.self) { _ in
    .init(prompts: [
        Prompt(
            name: "kaiten_field_reference",
            description: "Reference card for Kaiten API field values (condition, type, etc.)"
        ),
    ])
}

await server.withMethodHandler(GetPrompt.self) { params in
    switch params.name {
    case "kaiten_field_reference":
        return .init(
            description: "Kaiten API field reference",
            messages: [
                .user("Here is a reference for Kaiten API numeric field values:\n\n" +
                       "condition: 1 = active, 2 = archived\n" +
                       "column.type: ...\n" +
                       "wip_limit_type: ...")
            ]
        )
    default:
        throw MCPError.invalidParams("Unknown prompt: \(params.name)")
    }
}
```

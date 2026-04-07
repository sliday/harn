# harn — Harness Engineering Plugin for Claude Code

Deterministic guardrails, quality gates, and progressive disclosure for AI coding agents.

## Why Harness Engineering?

The underlying AI model matters less than the system built around it. A well-harnessed agent produces consistent, safe, high-quality output regardless of the model version. [Read the foundations](https://harn.app/kb/foundations.html).

## Quick Start

```bash
claude plugins marketplace add sliday/claude-plugins
claude plugins install harn
```

Then in any project:

```bash
/harn:init        # scaffold your harness
```

## Commands

| Command | Description |
|---------|-------------|
| `/harn:init` | Scaffold a complete harness — AGENTS.md, hooks, guardrails |
| `/harn:guard` | Generate or update security guardrail hooks (PreToolUse) |
| `/harn:gate` | Generate or update quality gate Stop hook |
| `/harn:analyze` | Audit your project against the CAR framework |
| `/harn:agents-md` | Build or rebuild AGENTS.md with progressive disclosure |
| `/harn:format` | Generate PostToolUse auto-formatter hook |
| `/harn:trace` | Generate PostToolUse trace logging hook for observability |
| `/harn:checkpoint` | Generate resume artifacts (LEARNED.md, CHECKPOINT.json) |
| `/harn:mcp-check` | Generate MCP server health check hook |
| `/harn:context` | Monitor context window usage and apply backpressure |

## What `/harn:init` Creates

- `AGENTS.md` — Agent behavior spec with progressive disclosure
- `.claude/settings.json` — Hook configuration
- `.claude/hooks/security-guard.sh` — PreToolUse guardrail
- `.claude/hooks/quality-gate.sh` — Stop hook for type/lint/test checks
- `.claude/hooks/auto-format.sh` — PostToolUse formatter (optional)
- `LEARNED.md` — Persistent gotchas and decisions log

## CAR Framework

Every agentic system has three layers:

- **Control** — Constraints and specifications (AGENTS.md, linters, tests, architectural rules)
- **Agency** — Tools and interfaces (MCP servers, sub-agents, browser access)
- **Runtime** — Execution and recovery (hooks, compaction, retries, rollback)

Run `/harn:analyze` to score your project across all three. Learn more at [harn.app](https://harn.app).

## Dependencies

- `jq` — JSON processing (used by hooks)
- `python3 >= 3.6` — Script execution
- Language-specific toolchain for quality gates (e.g., `tsc`, `cargo`, `go vet`, `ruff`)

## Troubleshooting

If a hook is blocking legitimate work or the agent is stuck in a loop, see [references/escape-hatches.md](references/escape-hatches.md).

## Knowledge Base

Curated articles on harness engineering — security, context, evals, specs, and tools: [harn.app/kb](https://harn.app/kb/).

## License

MIT

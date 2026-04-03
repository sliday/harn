# harn — Harness Engineering Plugin for Claude Code

> The underlying AI model matters less than the system built around it.

**harn** scaffolds deterministic guardrails, quality gates, and progressive disclosure for AI coding agents.

## Install

```bash
claude plugins marketplace add sliday/claude-plugins
claude plugins install harn
```

## What it does

- `/harn:init` — Scaffold a complete harness (AGENTS.md, hooks, guardrails) for your project
- `/harn:analyze` — Audit your project against the CAR framework (Control, Agency, Runtime)
- `/harn:guard` — Generate or update security guardrail hooks

## The CAR Framework

Every agentic system has three layers:

- **Control** — Constraints & specifications (AGENTS.md, linters, tests, architectural rules)
- **Agency** — Tools & interfaces (MCP servers, sub-agents, browser access)  
- **Runtime** — Execution & recovery (hooks, compaction, retries, rollback)

## Learn more

[harn.app](https://harn.app) — Interactive hub for Harness Engineering

## License

MIT

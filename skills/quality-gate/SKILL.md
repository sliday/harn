---
name: quality-gate
description: "Generate or update the quality gate Stop hook. Use when: /harn:quality-gate, 'set up type checking', 'add quality gate', 'stop hook'"
---

# Quality Gate Generator

Generate or update `scripts/harness/quality_gate.sh` for the current project.

## Process

1. Detect the project's tech stack
2. Select appropriate checker(s):
   - TypeScript → `npx tsc --noEmit`
   - Rust → `cargo check`
   - Go → `go vet ./...`
   - Python → `mypy` or `pyright`
   - JavaScript → `npx eslint .`
3. Generate the quality gate script with infinite-loop prevention
4. Ensure it's wired as a Stop hook in `.claude/settings.json`

## Key Requirements

- MUST check `stop_hook_active` payload to prevent infinite loops
- MUST output errors to stderr (fed back to agent)
- MUST exit 2 to block, exit 0 to allow
- Should complete in under 30 seconds

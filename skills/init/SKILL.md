---
name: init
description: "Scaffold a complete harness for the current project — AGENTS.md, hooks, guardrails. Use when starting a new project or hardening an existing one. Triggers: /harn:init, 'set up harness', 'scaffold guardrails', 'create AGENTS.md'"
---

# Harness Init — Full Project Scaffold

You are scaffolding a complete harness for the current project. Follow these steps exactly.

## Step 1: Detect Tech Stack

Read the project root to identify the stack:
- `package.json` → Node.js/TypeScript (check for `typescript` dep → TS)
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pyproject.toml` or `requirements.txt` → Python
- `Gemfile` → Ruby

Store the detected stack for later steps.

## Step 2: Generate AGENTS.md

Create `AGENTS.md` in the project root. Keep it under 60 lines. Use this template:

```
# Agent North Star

You are operating within a harnessed environment. Write maintainable, reliable code within architectural boundaries.

## System of Record

- Stack: [detected stack]
- Entry points: [detect from package.json scripts, Makefile, etc.]

## Constraints

- Never push to main — create feat/ or fix/ branches
- [Stack-specific constraints — e.g. "UI layer must not access DB directly"]

## Harness Hooks Active

- **PreToolUse**: Security guard blocks dangerous shell commands
- **PostToolUse**: Auto-formatter runs on file changes
- **Stop**: Quality gate runs type/lint checker before completion

## Skills (Progressive Disclosure)

Load these only when working on relevant tasks:
- API work → [reference api-reviewer skill if applicable]
- DB work → [reference db-schema skill if applicable]

## If Stuck

If you hit the same error 3 times, stop and ask the human.
```

## Step 3: Generate Security Guard

Create `scripts/harness/security_guard.py`:

```python
#!/usr/bin/env python3
"""PreToolUse hook — blocks dangerous shell commands."""
import sys
import json
import re

def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    if payload.get("tool_name") != "Bash":
        sys.exit(0)

    command = payload.get("parameters", {}).get("command", "")

    dangerous = [
        r"rm\s+-r[fF]",
        r"git\s+push\s+.*main",
        r"git\s+push\s+.*master",
        r"chmod\s+777",
        r">\s*~/",
        r"curl\s+.*\|\s*(?:sudo\s+)?(?:bash|sh)",
        r"sudo\s+rm",
        r"mkfs\.",
        r"dd\s+if=",
    ]

    for pattern in dangerous:
        if re.search(pattern, command):
            print(f"HARNESS BLOCK: Command matches prohibited pattern ({pattern}).", file=sys.stderr)
            print("Find a safer alternative.", file=sys.stderr)
            sys.exit(2)

    sys.exit(0)

if __name__ == "__main__":
    main()
```

Make it executable.

## Step 4: Generate Quality Gate

Create `scripts/harness/quality_gate.sh`:

```bash
#!/usr/bin/env bash
# Stop hook — quality gate. Blocks agent from completing if code is broken.
set -euo pipefail

PAYLOAD=$(cat /dev/stdin)
IS_ACTIVE=$(echo "$PAYLOAD" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

if [ "$IS_ACTIVE" = "true" ]; then
  exit 0
fi

echo "Harn: Running quality gate..." >&2

# Detect stack and run appropriate checker
if [ -f "tsconfig.json" ]; then
  npx tsc --noEmit > /tmp/harn_gate.log 2>&1 || {
    echo "QUALITY GATE FAILED — TypeScript errors:" >&2
    cat /tmp/harn_gate.log >&2
    exit 2
  }
elif [ -f "Cargo.toml" ]; then
  cargo check > /tmp/harn_gate.log 2>&1 || {
    echo "QUALITY GATE FAILED — Rust errors:" >&2
    cat /tmp/harn_gate.log >&2
    exit 2
  }
elif [ -f "go.mod" ]; then
  go vet ./... > /tmp/harn_gate.log 2>&1 || {
    echo "QUALITY GATE FAILED — Go errors:" >&2
    cat /tmp/harn_gate.log >&2
    exit 2
  }
elif [ -f "pyproject.toml" ] && command -v mypy &>/dev/null; then
  mypy . > /tmp/harn_gate.log 2>&1 || {
    echo "QUALITY GATE FAILED — Python type errors:" >&2
    cat /tmp/harn_gate.log >&2
    exit 2
  }
fi

echo "Harn: Quality gate passed." >&2
exit 0
```

Make it executable.

## Step 5: Generate `.claude/settings.json` wiring

Create `.claude/settings.json` in the user's project with hook wiring:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 scripts/harness/security_guard.py",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/harness/quality_gate.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Step 5b: Offer Additional Hooks (Optional)

Tell the user about additional harness capabilities they can add:

- **Auto-formatter** (`/harn:format`): PostToolUse hook that runs prettier/black/rustfmt on every file edit
- **Trace logging** (`/harn:trace`): PostToolUse hook that logs all tool calls to JSONL for debugging
- **Checkpoint artifacts** (`/harn:checkpoint`): LEARNED.md + CHECKPOINT.json for session recovery
- **MCP health check** (`/harn:mcp-check`): Validates MCP servers are running on session start

These are opt-in. The core harness (security guard + quality gate) is always generated.

## Step 6: Commit and push

After creating all files, ensure they're executable where needed, then commit the changes.

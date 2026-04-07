---
name: init
description: "Scaffold a complete harness for the current project — AGENTS.md, hooks, guardrails. Use when starting a new project or hardening an existing one. Triggers: /harn:init, 'set up harness', 'scaffold guardrails', 'create AGENTS.md'"
---

# Harness Init v2.0 — Full Project Scaffold

You are scaffolding a complete harness for the current project. Follow these steps exactly.

## Step 0: Pre-flight Checks

Before anything:

1. Verify core dependencies are available:
   - `jq` — run `command -v jq`
   - `python3` — run `command -v python3`
   If either is missing, tell the user to install them first and stop.

2. Check if `AGENTS.md`, `scripts/harness/`, or `.claude/settings.json` already exist in the project root.

3. If ANY exist, **assess each file** against the templates in this skill:
   - Read each existing file
   - Compare to the template version (Steps 2-6)
   - Classify each as: `up-to-date`, `outdated` (missing sections/patterns), or `customized` (user modifications beyond template)

4. Present a summary table and recommendation:

   ```
   Existing harness assessment:
   | File                    | Status      | Action       |
   |-------------------------|-------------|--------------|
   | AGENTS.md               | up-to-date  | skip         |
   | security_guard.py       | outdated    | update       |
   | quality_gate.sh         | customized  | skip (manual)|
   | trace_logger.sh         | missing     | create       |
   | .claude/settings.json   | up-to-date  | skip         |

   Recommendation: Update 1 file, create 1 file. 2 files unchanged.
   Proceed?
   ```

   - `up-to-date` → skip (no changes needed)
   - `outdated` → recommend update (template has improvements)
   - `customized` → skip and flag for manual review (don't overwrite user work)
   - `missing` → create

   Wait for user confirmation before proceeding. Only touch files marked for update/create.

5. If NO harness files exist, proceed directly to Step 1 (fresh scaffold).

## Step 1: Detect Tech Stack

Read the project root to identify the stack:
- `package.json` → Node.js/TypeScript (check for `typescript` dep → TS)
- `Cargo.toml` → Rust
- `go.mod` → Go
- `pyproject.toml` or `requirements.txt` → Python
- `Gemfile` → Ruby

Tell the user what was detected and ask to confirm: **"Detected: [stack]. Correct?"**

Store the detected stack for later steps.

## Step 2: Generate AGENTS.md

Create `AGENTS.md` in the project root. Keep it under 60 lines. Use this template:

```markdown
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
- **Stop**: Quality gate runs type/lint checker before completion

## Workflow

1. Understand → Read code, check LEARNED.md for gotchas
2. Plan → Break task into steps, update CHECKPOINT.json
3. Implement → Write code within constraints
4. Verify → Run quality gate before finishing
5. Document → Update LEARNED.md if something was tricky

## Context Budget

- Keep this file under 60 lines — load skills/ on demand
- Delegate research to sub-agents — only summaries return
- After 30+ tool calls, compact and update CHECKPOINT.json

## Escape Hatches

- Quality gate stuck? Stop hook checks stop_hook_active — retry lets you through
- Security guard wrong? Report false positive, use alternative command
- Same error 3 times? Stop and ask the human
```

## Step 3: Generate Security Guard

Create `scripts/harness/security_guard.py`:

```python
#!/usr/bin/env python3
"""PreToolUse hook — blocks dangerous shell commands before execution.

Why: https://harn.app/kb/safety.html — "Tools should be hard to misuse"
Docs: https://harn.app/kb/safety.html — "Mitigating Prompt Injection Attacks"
"""
import sys
import json
import re

def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    if not isinstance(payload, dict):
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
        try:
            if re.search(pattern, command):
                print(f"HARNESS BLOCK: Matches prohibited pattern ({pattern}).", file=sys.stderr)
                print("Find a safer alternative.", file=sys.stderr)
                sys.exit(2)
        except re.error:
            print(f"HARNESS WARNING: Invalid pattern skipped: {pattern}", file=sys.stderr)
            continue

    sys.exit(0)

if __name__ == "__main__":
    main()
```

Make it executable: `chmod +x scripts/harness/security_guard.py`

## Step 4: Generate Quality Gate

Create `scripts/harness/quality_gate.sh`:

```bash
#!/usr/bin/env bash
# Stop hook — quality gate. Blocks agent from completing if code is broken.
# Why: https://harn.app/kb/safety.html — "Quality checks in the loop"
# Pattern: https://harn.app/kb/evals.html — "Infrastructure noise moves benchmarks"
set -euo pipefail

# Check dependencies
command -v jq &>/dev/null || { echo "Harn: jq not found, quality gate skipped" >&2; exit 0; }

PAYLOAD=$(cat /dev/stdin)
IS_ACTIVE=$(echo "$PAYLOAD" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")

# CRITICAL: Break infinite loops
if [ "$IS_ACTIVE" = "true" ]; then
  exit 0
fi

# Session-aware temp file (prevents race conditions)
LOG_FILE="${TMPDIR:-/tmp}/harn_gate_${PPID}_$$.log"

echo "Harn: Running quality gate..." >&2

# Detect stack and run checker (fail-closed: block if checker missing)
if [ -f "tsconfig.json" ]; then
  command -v npx &>/dev/null || {
    echo "QUALITY GATE BLOCKED: TypeScript detected but 'npx' not found." >&2
    echo "Install Node.js or remove tsconfig.json to skip." >&2
    exit 2
  }
  npx tsc --noEmit > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE FAILED — TypeScript errors:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
elif [ -f "Cargo.toml" ]; then
  command -v cargo &>/dev/null || {
    echo "QUALITY GATE BLOCKED: Rust detected but 'cargo' not found." >&2
    exit 2
  }
  cargo check > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE FAILED — Rust errors:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
elif [ -f "go.mod" ]; then
  command -v go &>/dev/null || {
    echo "QUALITY GATE BLOCKED: Go detected but 'go' not found." >&2
    exit 2
  }
  go vet ./... > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE FAILED — Go errors:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
elif [ -f "pyproject.toml" ] && command -v mypy &>/dev/null; then
  mypy . > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE FAILED — Python type errors:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
fi

# Clean up temp file
rm -f "$LOG_FILE"

echo "Harn: Quality gate passed." >&2
exit 0
```

Make it executable: `chmod +x scripts/harness/quality_gate.sh`

## Step 5: Generate .claude/settings.json

Create `.claude/settings.json` in the project root:

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
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/harness/trace_logger.sh",
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

## Step 5b: Offer Additional Hooks

After creating the core harness, tell the user:

> Your core harness is ready (security guard + quality gate + trace logger). You can also add:
>
> - **Auto-formatter** (`/harn:format`) — formats code on every edit
> - **Context monitor** (`/harn:context`) — warns when context is getting full
> - **Checkpoint artifacts** (`/harn:checkpoint`) — LEARNED.md + CHECKPOINT.json for session recovery
> - **MCP health check** (`/harn:mcp-check`) — validates MCP servers on start
>
> These are opt-in. Run any command to add it.

## Step 6: Generate Trace Logger

Always generate `scripts/harness/trace_logger.sh` (pure observability, no downside):

```bash
#!/usr/bin/env bash
# PostToolUse hook — logs tool calls to JSONL for debugging and analytics.
set -euo pipefail

TRACE_FILE=".claude/agent-trace.jsonl"
MAX_LINES=5000
KEEP_LINES=2500

# Ensure directory exists
mkdir -p "$(dirname "$TRACE_FILE")"

# Read payload from stdin
PAYLOAD=$(cat /dev/stdin 2>/dev/null || echo "{}")

# Extract tool_name and exit_code
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
EXIT_CODE=$(echo "$PAYLOAD" | jq -r '.exit_code // 0' 2>/dev/null || echo "0")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append trace entry
echo "{\"ts\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"exit\":$EXIT_CODE}" >> "$TRACE_FILE"

# Log rotation: keep last KEEP_LINES when exceeding MAX_LINES
if [ -f "$TRACE_FILE" ]; then
  LINE_COUNT=$(wc -l < "$TRACE_FILE" | tr -d ' ')
  if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
    tail -n "$KEEP_LINES" "$TRACE_FILE" > "${TRACE_FILE}.tmp" && mv "${TRACE_FILE}.tmp" "$TRACE_FILE"
  fi
fi

exit 0
```

Make it executable: `chmod +x scripts/harness/trace_logger.sh`

This hook is already wired into the `PostToolUse` array in `.claude/settings.json` (Step 5).

## Step 7: Gitignore Guidance

Tell the user:

```
Files to commit to git:
  - AGENTS.md
  - scripts/harness/security_guard.py
  - scripts/harness/quality_gate.sh
  - scripts/harness/trace_logger.sh
  - .claude/settings.json

Files to .gitignore:
  - .claude/settings.local.json (personal overrides)
  - .claude/agent-trace.jsonl (session logs)
  - CHECKPOINT.json (ephemeral session state)
```

## Step 8: Run Harness Evaluator

After creating all files, use the harness-evaluator agent to validate the scaffold is correct. Run `/harn:evaluate` or invoke the evaluator skill to check:
- All files exist and are executable where needed
- settings.json is valid JSON with correct hook wiring
- Security guard catches known dangerous patterns
- Quality gate detects the right stack

## Step 9: Commit

Commit the new files with message:

```
chore: scaffold harn harness (security guard + quality gate + trace logger)
```

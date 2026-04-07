---
name: trace-logger
description: "Generate PostToolUse trace logging hook for observability. Triggers: /harn:trace, 'trace logging', 'observable hooks', 'agent trace', 'JSONL logging'"
---

# Trace Logger Skill

Generate a PostToolUse hook that logs all tool calls to JSONL for debugging and eval generation.

## Steps

1. Create `scripts/harness/trace_logger.sh` with the following content:

```bash
#!/usr/bin/env bash
# PostToolUse trace logger — appends JSONL to .claude/agent-trace.jsonl
# Non-blocking observability hook. Always exits 0.

set -euo pipefail

LOG_FILE=".claude/agent-trace.jsonl"
mkdir -p "$(dirname "$LOG_FILE")"

# Read hook JSON payload from stdin
PAYLOAD="$(cat 2>/dev/null || echo '{}')"

# Extract fields with jq, fallback to defaults
TOOL_NAME="$(echo "$PAYLOAD" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")"
EXIT_CODE="$(echo "$PAYLOAD" | jq -r '.exit_code // 0' 2>/dev/null || echo "0")"
ARGS_SUMMARY="$(echo "$PAYLOAD" | jq -r '.tool_input // .parameters // {} | tostring' 2>/dev/null | head -c 200 || echo "{}")"

SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build JSONL entry and append
jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg args "$ARGS_SUMMARY" \
  --arg exit "$EXIT_CODE" \
  --arg sid "$SESSION_ID" \
  '{timestamp: $ts, tool_name: $tool, args_summary: $args, exit_code: ($exit | tonumber), session_id: $sid}' \
  >> "$LOG_FILE" 2>/dev/null

exit 0
```

2. Make the script executable:

```bash
chmod +x scripts/harness/trace_logger.sh
```

3. Wire the hook into `.claude/settings.json`. Merge the following into the `hooks` object (create if absent):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/harness/trace_logger.sh",
            "timeout": 3
          }
        ]
      }
    ]
  }
}
```

## Notes

- The hook reads the JSON payload that Claude Code pipes to PostToolUse hooks via stdin.
- Parameters are truncated to 200 characters to keep log size manageable.
- `session_id` comes from the `CLAUDE_SESSION_ID` environment variable (set automatically by Claude Code); defaults to `"unknown"`.
- The script always exits 0 so it never blocks the agent, even if jq is missing or the payload is malformed.
- Log output goes to `.claude/agent-trace.jsonl` — one JSON object per line, suitable for `jq` queries and eval pipelines.

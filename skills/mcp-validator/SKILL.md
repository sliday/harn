---
name: mcp-validator
description: "Generate MCP server health check for SessionStart. Triggers: /harn:mcp-check, 'MCP health', 'check MCP servers', 'validate MCP'"
---

# MCP Server Health Validator

Generate a bash script at `scripts/harness/mcp_health.sh` that validates configured MCP servers are reachable. This runs from the SessionStart hook as an informational check (never blocks).

## Step 1: Create the health check script

Create `scripts/harness/mcp_health.sh` and make it executable:

```bash
#!/usr/bin/env bash
# SessionStart hook — MCP server health check.
# Informational only — always exits 0.

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Find settings file
SETTINGS=""
for candidate in "${PROJECT_ROOT}/.claude/settings.local.json" "${PROJECT_ROOT}/.claude/settings.json"; do
  if [ -f "$candidate" ]; then
    SETTINGS="$candidate"
    break
  fi
done

if [ -z "$SETTINGS" ]; then
  # No settings file — nothing to check
  exit 0
fi

# Check if jq is available
if ! command -v jq &>/dev/null; then
  echo "Harn: jq not found — skipping MCP health check." >&2
  exit 0
fi

# Extract MCP server names
SERVERS=$(jq -r '.mcpServers // {} | keys[]' "$SETTINGS" 2>/dev/null)

if [ -z "$SERVERS" ]; then
  exit 0
fi

FAILED=()
CHECKED=0

while IFS= read -r name; do
  CHECKED=$((CHECKED + 1))

  # Check if server has a command
  CMD=$(jq -r --arg n "$name" '.mcpServers[$n].command // empty' "$SETTINGS" 2>/dev/null)
  if [ -n "$CMD" ]; then
    if ! command -v "$CMD" &>/dev/null; then
      FAILED+=("$name")
    fi
    continue
  fi

  # Check if server has a url
  URL=$(jq -r --arg n "$name" '.mcpServers[$n].url // empty' "$SETTINGS" 2>/dev/null)
  if [ -n "$URL" ]; then
    if ! curl -sf --max-time 2 "$URL" >/dev/null 2>&1; then
      FAILED+=("$name")
    fi
    continue
  fi

done <<< "$SERVERS"

if [ ${#FAILED[@]} -eq 0 ]; then
  echo "Harn: All MCP servers reachable." >&2
else
  for name in "${FAILED[@]}"; do
    echo "Harn: MCP server '${name}' unreachable — tools may fail." >&2
  done
fi

exit 0
```

## Step 2: Wire into session-start.sh

If `scripts/harness/session-start.sh` exists, append the MCP health check call. If it does not exist, create it with:

```bash
#!/usr/bin/env bash
# SessionStart hook — runs at the beginning of each agent session.
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Check MCP servers
if [ -f "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" ]; then
  bash "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" 2>&1 || true
fi
```

If `session-start.sh` already exists, add the following block before the final line (or at the end):

```bash
# Check MCP servers
if [ -f "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" ]; then
  bash "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" 2>&1 || true
fi
```

Make both scripts executable:
```bash
chmod +x scripts/harness/mcp_health.sh
chmod +x scripts/harness/session-start.sh
```

## Step 3: Wire the SessionStart hook in settings

If `.claude/settings.json` does not already have a `SessionStart` hook, add one:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash scripts/harness/session-start.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

If the file already has hooks, merge the `SessionStart` entry without overwriting existing hooks.

## Step 4: Confirm

After creating and wiring the scripts, report what was done:

- Created `scripts/harness/mcp_health.sh`
- Wired into `scripts/harness/session-start.sh`
- Configured `SessionStart` hook in `.claude/settings.json`

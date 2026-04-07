---
name: context-monitor
description: "Generate context monitoring and backpressure hooks. Triggers: /harn:context, 'context monitoring', 'backpressure', 'context budget', 'attention budget', 'context rot'"
---

# Context Monitor Skill

Generate a context backpressure system that monitors tool call volume and warns the agent before context rot degrades session quality.

## Step 1: Generate `scripts/harness/context_backpressure.sh`

Create the file `scripts/harness/context_backpressure.sh` with the following content:

```bash
#!/usr/bin/env bash
# Harn context monitor — prevents context rot in long sessions
# Why: https://harn.app/kb/context.html — "Context as finite resource with diminishing returns"
# Pattern: https://harn.app/kb/context.html — "Context-Efficient Backpressure"

set -euo pipefail

TRACE_LOG=".claude/agent-trace.jsonl"

# Dependency check
if ! command -v jq &>/dev/null; then
  echo "Harn: context_backpressure.sh requires jq (not installed, skipping)" >&2
  exit 0
fi

# Graceful fallback if trace log doesn't exist
if [[ ! -f "$TRACE_LOG" ]]; then
  exit 0
fi

# Count tool calls in current session
TOOL_CALLS=$(wc -l < "$TRACE_LOG" | tr -d ' ')

if [[ "$TOOL_CALLS" -ge 75 ]]; then
  echo "Harn: 75 tool calls — high context usage. Summarize progress before continuing." >&2
elif [[ "$TOOL_CALLS" -ge 50 ]]; then
  echo "Harn: 50 tool calls — recommend compacting: update CHECKPOINT.json, then compact" >&2
elif [[ "$TOOL_CALLS" -ge 30 ]]; then
  echo "Harn: 30 tool calls — consider delegating research to sub-agents" >&2
fi

exit 0
```

Make sure `scripts/harness/` directory exists before writing the file.

## Step 2: Add context management section to AGENTS.md

Append the following section to the project's `AGENTS.md` file. If `AGENTS.md` does not exist, create it with this content. If it already exists, add this section at the end:

```markdown
## Context Management
- Delegate research and grep tasks to sub-agents — only summaries return
- After 30+ tool calls, consider compacting: summarize progress, update CHECKPOINT.json
- Use LEARNED.md for discoveries that must survive compaction
- Prefer just-in-time retrieval (read files when needed) over pre-loading everything
```

## Step 3: Wire into .claude/settings.json

Read the existing `.claude/settings.json` file. Add a `PostToolUse` hook entry. If `PostToolUse` already has entries (e.g., formatter, trace), append to the existing array. If `PostToolUse` does not exist, create it.

The hook entry to add:

```json
{
  "matcher": "",
  "hooks": [{
    "type": "command",
    "command": "bash scripts/harness/context_backpressure.sh",
    "timeout": 3
  }]
}
```

The resulting structure in `settings.json` should look like:

```json
{
  "hooks": {
    "PostToolUse": [
      // ... any existing entries ...
      {
        "matcher": "",
        "hooks": [{
          "type": "command",
          "command": "bash scripts/harness/context_backpressure.sh",
          "timeout": 3
        }]
      }
    ]
  }
}
```

## Step 4: Make executable

Run:

```bash
chmod +x scripts/harness/context_backpressure.sh
```

## Verification

After all steps, confirm:
1. `scripts/harness/context_backpressure.sh` exists and is executable
2. `AGENTS.md` contains the Context Management section
3. `.claude/settings.json` has the PostToolUse hook for context_backpressure.sh
4. The script exits 0 when run directly: `bash scripts/harness/context_backpressure.sh`

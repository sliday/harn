#!/usr/bin/env bash
# Harness health check — runs on every session start
# Reports harness status without bloating context

set -euo pipefail

PROJECT_ROOT="${PWD}"
STATUS=""
MISSING=0

# Check for agent instructions
if [ -f "${PROJECT_ROOT}/AGENTS.md" ] || [ -f "${PROJECT_ROOT}/CLAUDE.md" ]; then
  STATUS="${STATUS}  Control doc: found\n"
else
  STATUS="${STATUS}  Control doc: MISSING\n"
  MISSING=$((MISSING + 1))
fi

# Check for harness hooks
if [ -f "${PROJECT_ROOT}/.claude/settings.json" ] || [ -f "${PROJECT_ROOT}/.claude/settings.local.json" ]; then
  STATUS="${STATUS}  Settings: found\n"
else
  STATUS="${STATUS}  Settings: MISSING\n"
  MISSING=$((MISSING + 1))
fi

# Check for guardrail scripts
if [ -d "${PROJECT_ROOT}/scripts/harness" ]; then
  STATUS="${STATUS}  Guardrails: found\n"
else
  STATUS="${STATUS}  Guardrails: MISSING\n"
  MISSING=$((MISSING + 1))
fi

# Check for tests
if [ -d "${PROJECT_ROOT}/tests" ] || [ -d "${PROJECT_ROOT}/__tests__" ] || [ -d "${PROJECT_ROOT}/test" ] || [ -d "${PROJECT_ROOT}/spec" ]; then
  STATUS="${STATUS}  Tests: found\n"
else
  STATUS="${STATUS}  Tests: MISSING\n"
  MISSING=$((MISSING + 1))
fi

# Check for PostToolUse hooks (formatters)
if [ -f "${PROJECT_ROOT}/scripts/harness/auto_formatter.sh" ]; then
  STATUS="${STATUS}  Formatter: found\n"
else
  STATUS="${STATUS}  Formatter: not configured (run /harn:format)\n"
fi

# Check for checkpoint artifacts
if [ -f "${PROJECT_ROOT}/CHECKPOINT.json" ] || [ -f "${PROJECT_ROOT}/LEARNED.md" ]; then
  STATUS="${STATUS}  Checkpoint: found\n"
  if [ -f "${PROJECT_ROOT}/CHECKPOINT.json" ]; then
    TASK=$(cat "${PROJECT_ROOT}/CHECKPOINT.json" | jq -r '.current_task // empty' 2>/dev/null)
    if [ -n "$TASK" ]; then
      echo "Harn: Last task: ${TASK}" >&2
    fi
  fi
fi

# Check MCP server health
if [ -f "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" ]; then
  bash "${PROJECT_ROOT}/scripts/harness/mcp_health.sh" 2>&1 || true
fi

# Output to stderr (shown to agent)
if [ "${MISSING}" -gt 0 ]; then
  echo "Harn: ${MISSING} harness component(s) missing. Run /harn:init to scaffold." >&2
else
  echo "Harn: Harness healthy." >&2
fi

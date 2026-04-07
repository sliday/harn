# Hook Lifecycle Reference

## Execution Order
1. **PreToolUse** — Fires BEFORE a tool executes. Exit 2 blocks the tool call.
2. **PostToolUse** — Fires AFTER a tool completes. Exit 2 is informational (cannot undo).
3. **Stop** — Fires when the agent attempts to finish. Exit 2 blocks completion.

## Exit Codes
- `0` — Allow / success
- `2` — Block / reject (agent sees error and must adjust)
- Any other — Treated as error, logged but not blocking

## Payload Format (JSON on stdin)
```json
{
  "tool_name": "Bash",
  "parameters": {"command": "npm test"},
  "stop_hook_active": false
}
```

## Timeouts
- PreToolUse: 5 seconds (security checks must be fast)
- PostToolUse: 3-5 seconds (formatting, logging)
- Stop: 30 seconds (type checking, test running)

If a hook exceeds its timeout, it is killed and treated as exit 0 (allow).

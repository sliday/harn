# Escape Hatches

## Quality Gate Stuck
The Stop hook reads `stop_hook_active` from the payload. When the agent is already
recovering from a previous Stop hook failure, this flag is `true` — and the quality
gate should exit 0 to break the loop.

If the gate is stuck even with this flag:
1. Check /tmp/harn_gate_*.log for the actual error
2. Fix the underlying code issue
3. If the checker itself is broken, temporarily remove it from .claude/settings.json

## Security Guard False Positive
If the security guard blocks a legitimate command:
1. Try rephrasing the command (e.g., `git push origin feature-branch` instead of including "main")
2. Report the false positive pattern
3. Temporarily add an exception to the pattern list

## Agent Won't Stop Retrying
If the agent hits the same error 3+ times:
1. The AGENTS.md template includes "ask the human after 3 errors"
2. If this isn't working, interrupt the agent manually
3. Check LEARNED.md for previously encountered gotchas

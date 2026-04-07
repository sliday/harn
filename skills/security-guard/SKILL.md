---
name: security-guard
description: "Generate or update security guardrail hooks. Use when: /harn:guard, 'update security rules', 'block dangerous commands', 'add guardrail'"
---

# Security Guard Generator

Generate or update `scripts/harness/security_guard.py` for the current project.

## Process

1. Read current `scripts/harness/security_guard.py` if it exists
2. Ask user what additional patterns to block (or accept defaults)
3. Before adding user patterns, verify they compile as valid regex
4. Offer to show the user what existing commands would be blocked by the new patterns before activating (--dry-run)
5. Generate the updated script with all patterns
6. Ensure it's executable
7. Verify it's wired in `.claude/settings.json` as a PreToolUse hook

## Default Blocked Patterns

- `rm -rf` — recursive forced deletion
- `git push ... main/master` — direct push to protected branches
- `chmod 777` — reckless permissions
- `> ~/` — overwriting home directory files
- `curl | bash` — piped remote execution
- `sudo rm` — privileged deletion
- `mkfs.` — disk formatting
- `dd if=` — raw disk writes

## Custom Patterns

Ask the user if they want to:
- Restrict writes to specific directories only (e.g., only `src/`)
- Block specific package managers (e.g., `npm publish`)

## Pattern Validation

Before adding user-supplied patterns, verify they compile as valid regex. Invalid patterns can silently break the guard or cause it to crash. Test each pattern with `re.compile()` and report errors back to the user before writing the script.

## Dry Run

Offer to show the user what existing commands (from shell history or a sample list) would be blocked by the new patterns before activating. This helps catch overly broad patterns that would block legitimate work.

## User-Supplied Patterns

User-supplied regex patterns may contain errors — unbalanced groups, invalid escapes, or overly broad expressions. The generated script wraps each `re.search()` call in a try/except for `re.error` so that a single bad pattern does not disable the entire guard.

## Template

Generate `scripts/harness/security_guard.py` using this structure:

```python
#!/usr/bin/env python3
# Harn security guard — blocks dangerous shell commands before execution
# Why: https://harn.app/kb/safety.html — "Tools should be hard to misuse"
# Docs: https://harn.app/kb/safety.html — "Mitigating Prompt Injection Attacks"

import json, sys, re

payload = json.load(sys.stdin)

if not isinstance(payload, dict):
    sys.exit(0)  # Malformed payload — allow (fail-open for non-Bash)

tool = payload.get("tool_name", "")
if tool != "Bash":
    sys.exit(0)

command = payload.get("tool_input", {}).get("command", "")

dangerous = [
    r"rm\s+-rf",
    r"git\s+push\s+.*\b(main|master)\b",
    r"chmod\s+777",
    r">\s*~/",
    r"curl\s+.*\|\s*bash",
    r"sudo\s+rm",
    r"mkfs\.",
    r"dd\s+if=",
]

for pattern in dangerous:
    try:
        if re.search(pattern, command):
            print(f"HARNESS BLOCK: Command matches prohibited pattern ({pattern}).", file=sys.stderr)
            print("Find a safer alternative.", file=sys.stderr)
            sys.exit(2)
    except re.error:
        print(f"HARNESS WARNING: Invalid regex pattern skipped: {pattern}", file=sys.stderr)
        continue

sys.exit(0)
```

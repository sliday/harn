---
name: security-guard
description: "Generate or update security guardrail hooks. Use when: /harn:guard, 'update security rules', 'block dangerous commands', 'add guardrail'"
---

# Security Guard Generator

Generate or update `scripts/harness/security_guard.py` for the current project.

## Process

1. Read current `scripts/harness/security_guard.py` if it exists
2. Ask user what additional patterns to block (or accept defaults)
3. Generate the updated script with all patterns
4. Ensure it's executable
5. Verify it's wired in `.claude/settings.json` as a PreToolUse hook

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
- Block database operations (e.g., `DROP TABLE`)

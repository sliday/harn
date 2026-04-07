---
name: checkpoint
description: "Scaffold resume artifacts (LEARNED.md, CHECKPOINT.json) for long-running sessions. Triggers: /harn:checkpoint, 'resume artifacts', 'checkpoint', 'session recovery', 'LEARNED.md'"
---

You are a session-recovery scaffolding skill. When invoked, perform ALL four steps below in the current project root.

## Step 1: Create LEARNED.md

If `LEARNED.md` does not already exist in the project root, create it with this template:

```markdown
# Learned

Tricky problems encountered during this project. Read this before starting work.

## Patterns
<!-- Add patterns discovered during development -->

## Gotchas
<!-- Add surprising behaviors or non-obvious constraints -->

## Failed Approaches
<!-- Document what was tried and why it didn't work -->
```

If it already exists, leave it untouched and tell the user.

## Step 2: Create CHECKPOINT.json

If `CHECKPOINT.json` does not already exist in the project root, create it with this template:

```json
{
  "last_updated": "",
  "current_task": "",
  "completed_tasks": [],
  "blocked_on": "",
  "context_notes": "",
  "files_in_progress": []
}
```

If it already exists, leave it untouched and tell the user.

## Step 3: Add SessionStart hook snippet

Check if `hooks/session-start.sh` exists in the project root.

- If it exists, append the checkpoint-detection block below (only if it is not already present).
- If it does not exist, create `hooks/session-start.sh` with the block.

Make the file executable (`chmod +x`).

```bash
# --- Harn Checkpoint Resume ---
if [ -f "CHECKPOINT.json" ]; then
  TASK=$(python3 -c "import json,sys; d=json.load(open('CHECKPOINT.json')); print(d.get('current_task',''))" 2>/dev/null || echo "")
  NOTES=$(python3 -c "import json,sys; d=json.load(open('CHECKPOINT.json')); print(d.get('context_notes',''))" 2>/dev/null || echo "")
  if [ -n "$TASK" ]; then
    echo "Harn: Checkpoint found — last task: $TASK" >&2
  fi
  if [ -n "$NOTES" ]; then
    echo "Harn: Context notes: $NOTES" >&2
  fi
fi
# --- End Checkpoint Resume ---
```

## Step 4: Suggest AGENTS.md addition

Print the following block and instruct the user to add it to their `AGENTS.md` (or offer to append it automatically if the file exists):

```markdown
## Session Recovery
- Before starting: read LEARNED.md for gotchas
- After compact: read CHECKPOINT.json for current state
- When learning something tricky: update LEARNED.md
- Before finishing a sub-task: update CHECKPOINT.json
```

## After all steps

Print a summary of what was created vs. what already existed. Remind the user to:
1. Keep `CHECKPOINT.json` updated at the end of each sub-task.
2. Add gotchas to `LEARNED.md` as they are discovered.
3. Both files are designed to survive context compaction — agents should read them on session start.

---
name: agents-md
description: "Build or rebuild AGENTS.md with progressive disclosure. Use when: /harn:agents-md, 'create AGENTS.md', 'update agent instructions', 'too many instructions'"
---

# Reference: https://harn.app/kb/specs.html — "12 Factor Agents"
# Reference: https://harn.app/kb/context.html — "Writing a good CLAUDE.md"

# AGENTS.md Builder

Generate a lean, effective AGENTS.md using progressive disclosure principles.

## Rules

1. **Under 60 lines** — ideally under 100, never over 300
2. **No directory trees** — agents discover structure on their own
3. **No bloated context** — point to skill files for domain-specific rules
4. **Progressive disclosure** — load detailed instructions only when relevant

## Process

1. Read the current project root (package.json, README, existing AGENTS.md)
2. Identify: stack, entry points, architectural constraints
3. Generate AGENTS.md with sections:
   - North Star (1-2 sentences)
   - System of Record (stack, entry points)
   - Constraints (hard rules)
   - Active Harness Hooks (what's automated)
   - Skills (progressive disclosure pointers)
   - Escape Hatch (what to do when stuck)
4. If existing AGENTS.md is over 100 lines, refactor it:
   - Extract domain rules into separate skill files
   - Keep only pointers in AGENTS.md

## Workflow
1. Understand → Read code, check LEARNED.md for gotchas
2. Plan → Break task into steps, update CHECKPOINT.json
3. Implement → Write code within architectural constraints
4. Verify → Run quality gate before finishing
5. Document → Update LEARNED.md if something was tricky

## Context Budget
- Keep this file under 60 lines — load skills/ on demand
- Delegate research to sub-agents — only summaries return
- After 30+ tool calls, compact and update CHECKPOINT.json

## Escape Hatches
- Quality gate stuck? Stop hook checks `stop_hook_active` — retry lets you through
- Security guard wrong? Report false positive, use alternative command
- Same error 3 times? Stop and ask the human

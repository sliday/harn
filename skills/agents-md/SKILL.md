---
name: agents-md
description: "Build or rebuild AGENTS.md with progressive disclosure. Use when: /harn:agents-md, 'create AGENTS.md', 'update agent instructions', 'too many instructions'"
---

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

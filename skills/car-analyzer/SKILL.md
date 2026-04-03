---
name: car-analyzer
description: "Audit project harness against the CAR framework. Use when: /harn:analyze, 'audit harness', 'check CAR', 'harness health', 'how good is my harness'"
---

# CAR Framework Analyzer

Audit the current project against the three layers of a robust harness.

## Control Layer (Constraints & Specifications)

Check for:
- [ ] AGENTS.md or CLAUDE.md exists
- [ ] AGENTS.md under 300 lines
- [ ] Linter configured (eslint, clippy, golint, ruff, etc.)
- [ ] Formatter configured (prettier, rustfmt, gofmt, black, etc.)
- [ ] Tests directory exists with actual test files
- [ ] Architectural constraints documented
- [ ] CI/CD pipeline exists (.github/workflows, etc.)

## Agency Layer (Tools & Interfaces)

Check for:
- [ ] MCP servers configured (if applicable)
- [ ] Tool permissions scoped appropriately
- [ ] Sub-agent patterns defined (for complex workflows)
- [ ] File write boundaries defined

## Runtime Layer (Execution & Recovery)

Check for:
- [ ] PreToolUse hooks (security guards)
- [ ] PostToolUse hooks (formatters)
- [ ] Stop hooks (quality gates)
- [ ] Infinite-loop prevention in Stop hooks
- [ ] Context compaction strategy noted
- [ ] Retry budget defined

## Output

Generate a scorecard:
```
CAR Framework Audit
═══════════════════
Control:  [X/7]  ████████░░  
Agency:   [X/4]  ██████░░░░  
Runtime:  [X/6]  █████████░  

Overall:  X/17

Top recommendations:
1. [Most impactful missing item]
2. [Second most impactful]
3. [Third most impactful]
```

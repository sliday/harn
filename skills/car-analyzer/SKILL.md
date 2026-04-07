---
name: car-analyzer
description: "Audit project harness against the CAR framework. Use when: /harn:analyze, 'audit harness', 'check CAR', 'harness health', 'how good is my harness'"
---

# Reference: https://harn.app/kb/evals.html — "Deterministic verifiers over LLM-as-judge"

# CAR Framework Analyzer

Audit the current project against the three layers of a robust harness.

## CAR Scorecard (check each item, tally points)

### Control Layer (40 points)
- [ ] AGENTS.md or CLAUDE.md exists and < 100 lines (10 pts)
- [ ] Type checker configured and runs without errors (10 pts)
- [ ] Linter configured (eslint/clippy/ruff/golangci-lint) (5 pts)
- [ ] Test directory exists with actual test files (10 pts)
- [ ] Architectural constraints documented in AGENTS.md (5 pts)

### Agency Layer (25 points)
- [ ] PreToolUse security guard hook active (10 pts)
- [ ] Tool permissions explicitly scoped (5 pts)
- [ ] Sub-agent delegation patterns documented (5 pts)
- [ ] File write boundaries defined (5 pts)

### Runtime Layer (35 points)
- [ ] Stop hook (quality gate) active and verified (15 pts)
- [ ] PostToolUse hooks configured (formatter and/or trace) (5 pts)
- [ ] Infinite-loop prevention in Stop hook verified (10 pts)
- [ ] Session recovery artifacts exist (CHECKPOINT.json or LEARNED.md) (5 pts)

## Scoring
- 80-100: Production-grade harness
- 60-79: Functional with gaps — run specific /harn: commands to fill
- 40-59: Needs hardening — run /harn:init to scaffold missing components
- <40: Minimal harness — strongly recommend full /harn:init

## Remediation Guide
For each missing item, suggest the specific `/harn:*` command:
- Missing security guard → `/harn:guard`
- Missing quality gate → `/harn:gate`
- Missing formatter → `/harn:format`
- Missing trace logging → `/harn:trace`
- Missing checkpoint → `/harn:checkpoint`
- Missing AGENTS.md → `/harn:agents-md`
- Missing context management → `/harn:context`

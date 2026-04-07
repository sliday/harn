---
name: quality-gate
description: "Generate or update the quality gate Stop hook. Use when: /harn:quality-gate, 'set up type checking', 'add quality gate', 'stop hook'"
---

# Quality Gate Generator

Generate or update `scripts/harness/quality_gate.sh` for the current project.

## Process

1. Detect the project's tech stack
2. Select appropriate checker(s):
   - TypeScript → `npx tsc --noEmit`
   - Rust → `cargo check`
   - Go → `go vet ./...`
   - Python → `mypy` or `pyright`
   - JavaScript → `npx eslint .`
3. Generate the quality gate script with infinite-loop prevention
4. Ensure it's wired as a Stop hook in `.claude/settings.json`

## Key Requirements

- MUST check `stop_hook_active` payload to prevent infinite loops
- MUST output errors to stderr (fed back to agent)
- MUST exit 2 to block, exit 0 to allow
- Should complete in under 30 seconds

## Generated Script Template

The generated `scripts/harness/quality_gate.sh` must include the following robustness patterns:

### KB References (at top of script)

```bash
# Harn quality gate — blocks agent completion if code is broken
# Why: https://harn.app/kb/safety.html — "Quality checks in the loop"
# Pattern: https://harn.app/kb/evals.html — "Infrastructure noise moves benchmarks"
```

### Dependency Checks (before any checker runs)

```bash
command -v jq &>/dev/null || { echo "Harn: jq not found, quality gate skipped" >&2; exit 0; }
```

### Session-Aware Temp File (replaces /tmp/harn_gate.log)

```bash
LOG_FILE="${TMPDIR:-/tmp}/harn_gate_${PPID}_$$.log"
```

### Checker Guards (verify tool exists before running)

Each checker must be guarded with `command -v` before invocation:

```bash
if [ -f "tsconfig.json" ]; then
  command -v npx &>/dev/null || {
    echo "QUALITY GATE BLOCKED: TypeScript detected but 'npx' not found." >&2
    echo "Install Node.js or remove tsconfig.json." >&2
    exit 2
  }
  npx tsc --noEmit > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE BLOCKED: TypeScript errors found:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
fi

if [ -f "Cargo.toml" ]; then
  command -v cargo &>/dev/null || {
    echo "QUALITY GATE BLOCKED: Rust detected but 'cargo' not found." >&2
    echo "Install Rust toolchain or remove Cargo.toml." >&2
    exit 2
  }
  cargo check > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE BLOCKED: Cargo check errors found:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
fi

if [ -f "go.mod" ]; then
  command -v go &>/dev/null || {
    echo "QUALITY GATE BLOCKED: Go detected but 'go' not found." >&2
    echo "Install Go or remove go.mod." >&2
    exit 2
  }
  go vet ./... > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE BLOCKED: Go vet errors found:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
fi

if [ -f "mypy.ini" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
  command -v mypy &>/dev/null || {
    echo "QUALITY GATE BLOCKED: Python type checking configured but 'mypy' not found." >&2
    echo "Install mypy or remove type checking config." >&2
    exit 2
  }
  mypy . > "$LOG_FILE" 2>&1 || {
    echo "QUALITY GATE BLOCKED: mypy errors found:" >&2
    cat "$LOG_FILE" >&2
    exit 2
  }
fi
```

### Backpressure Output Pattern

- On success: print only `"Harn: Quality gate passed."` (minimal output)
- On failure: print the full error log to stderr (full output)

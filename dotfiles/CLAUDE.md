# Global Agent Directives

These directives apply to all Claude Code sessions. Project-level CLAUDE.md files layer on top.

---

## Pre-Work

### Plan and Build Are Separate Steps
When asked to "make a plan" or "think about this first," output only the plan. No code until the user says go. When the user provides a written plan, follow it exactly. If you spot a real problem, flag it and wait — don't improvise. If instructions are vague, outline what you'd build and where it goes. Get approval first.

### Phased Execution
Never attempt multi-file refactors in a single response. Break work into explicit phases. Complete Phase 1, run verification, and wait for explicit approval before Phase 2.

### Delete Before You Build
Before any structural refactor on a file >300 LOC, first remove all dead props, unused exports, unused imports, and debug logs. Commit this cleanup separately before starting the real work.

---

## Understanding Intent

### Follow References, Not Descriptions
When the user points to existing code as a reference, study it thoroughly before building. Match its patterns exactly. The user's working code is a better spec than their English description.

### Work From Raw Data
When the user pastes error logs, work directly from that data. Don't guess, don't chase theories — trace the actual error. If a bug report has no error output, ask for it.

### One-Word Mode
When the user says "yes," "do it," or "push" — execute. Don't repeat the plan. Don't add commentary.

---

## Code Quality

### Forced Verification
You are FORBIDDEN from reporting a task as complete until you have:
- Detected the project's language/toolchain and run the appropriate checks:
  - **Node/TypeScript**: `npx tsc --noEmit` and `npx eslint . --quiet` (if configured)
  - **Rust**: `cargo check` and `cargo clippy` (if configured)
  - **Go**: `go vet ./...` and `golangci-lint run` (if configured)
  - **Python**: `mypy .` or `pyright` and `ruff check .` (if configured)
  - **Multi-language repos**: run checks for every language touched
- Fixed ALL resulting errors

If no type-checker or linter is configured for the project, state that explicitly instead of claiming success.

### Write Human Code
Write code that reads like a human wrote it. No robotic comment blocks, no excessive section headers, no corporate descriptions of obvious things.

---

## Edit Safety

### Edit Integrity
Before every file edit, re-read the file. After editing, read it again to confirm the change applied correctly. Never batch more than 3 edits to the same file without a verification read.

### Thorough Reference Search
When renaming or changing any function/type/variable, search separately for:
- Direct calls and references
- Type-level references (interfaces, generics)
- String literals containing the name
- Re-exports and barrel file entries
- Test files and mocks

Do not assume a single grep caught everything.

### One Source of Truth
Never fix a display problem by duplicating data or state. One source, everything else reads from it.

---

## Self-Evaluation

### Bug Autopsy
After fixing a bug, explain why it happened and whether anything could prevent that category of bug in the future.

### Failure Recovery
If a fix doesn't work after two attempts, stop. Read the entire relevant section top-down. Figure out where your mental model was wrong and say so. Propose something fundamentally different.

### Two-Perspective Review
When evaluating your own work, present two opposing views: what a perfectionist would criticize and what a pragmatist would accept. Let the user decide which tradeoff to take.

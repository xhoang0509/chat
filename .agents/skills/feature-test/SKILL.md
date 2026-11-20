---
name: feature-test
description: Validate, test, and verify implemented features across all layers including backend unit/integration tests, frontend build/typecheck, edge cases, regression testing, and CI readiness. Use this skill when the user asks to test, verify, run test suites, check edge cases, or ensure code passes CI before merging.
---

# Feature Testing & Verification Skill

This skill guides Antigravity through rigorous multi-layer testing, edge-case verification, and CI readiness checks to ensure zero regressions and 100% test pass rate before creating Pull Requests.

---

## Workflow Overview

```text
[Implemented Feature]
         ↓
1. Static Analysis & Type Safety Check (TypeScript, Go build)
         ↓
2. Unit Testing & Rule Boundary Coverage (Table-driven Go tests)
         ↓
3. Integration & Concurrency Testing (WebSocket lifecycle, concurrent acts)
         ↓
4. Frontend Build & Asset Verification (Vite / Bundler production build)
         ↓
5. Edge-Case Matrix Evaluation (Timeouts, disconnects, illegal actions)
         ↓
6. Local CI Workflow Simulation (Full test suite run before push/PR)
```

---

## Step-by-Step Instructions

### Step 1: Static Analysis & Compilation Check
Run fast static checks first to catch syntax, type mismatches, and dead code:
1. **Backend Compilation**:
   ```bash
   go vet ./...
   go test -run=^$ ./... # Verifies compilation of all packages and test files without running
   ```
2. **Frontend Type Check**:
   ```bash
   pnpm -C desktop exec tsc --noEmit
   ```
   Ensure 0 errors and no implicit `any` leaks.

### Step 2: Backend Unit Testing & Rule Coverage
1. **Table-Driven Tests**:
   - Write comprehensive table-driven tests in `*_test.go` covering every rule defined in the SPEC.
   - Example for game engines:
     - Starting board configuration.
     - Legal and illegal moves for every piece type.
     - Obstacle rules (e.g., blocking legs, eye blocks, screen jumps).
     - Board boundaries (e.g., palace, river).
     - Check and checkmate detection.
     - Stalemate / illegal move recovery.
     - Timeout and resign handling.
2. **Run Backend Tests with Verbose Output**:
   ```bash
   go test -v -race ./game/... # Or the relevant packages
   ```
   Ensure all tests pass and there are no data races (`-race`).

### Step 3: Frontend Production Build & CSS Integrity Check
Always run the complete production build to verify module bundling, CSS assets, and minification:
1. **Production Build**:
   ```bash
   pnpm -C desktop build
   ```
   Verify that Rollup/Vite finishes with exit code `0` and no broken asset imports.
2. **Automated CSS & UI Layout Verification**:
   Run the static CSS integrity checker to prevent layout clipping, centering collisions, and missing prefixes:
   ```bash
   ./scripts/verify-css.sh --strict
   ```
   Ensures:
   - No `@keyframes` `transform` override on elements centered with `translate(-50%, -50%)`.
   - Modals and Overlays wrapped in flexbox backdrops with `overflow-y: auto` and `max-height`.
   - WebKit vendor prefixes present for `backdrop-filter` and `user-select`.

### Step 4: Edge-Case & Regression Matrix
Systematically verify the following scenarios:
1. **Input Validation**:
   - Malformed JSON payloads.
   - Out-of-bounds coordinates (e.g., negative coordinates or coordinates beyond board size).
   - Non-existent player IDs or spectators attempting player actions.
2. **State & Turn Order**:
   - Action out of turn (e.g., player trying to move when it is opponent's turn).
   - Moving opponent's pieces.
   - Actions after game has ended (`status: "ended"`).
3. **Network & Concurrency**:
   - Fast successive clicks (debouncing & throttling).
   - Reconnecting mid-game and restoring accurate board snapshot.

### Step 5: Full Local CI Verification Suite
Before committing, pushing, or opening a Pull Request, run the exact test commands configured in GitHub Actions (`.github/workflows/test.yml`):
```bash
go test ./... && pnpm -C desktop build
```
**CRITICAL**: Do NOT create a Pull Request or notify the user that testing is complete until both commands pass with 100% success (exit code 0).

### Step 6: Reporting Results to User
When reporting test results:
- State clearly which test suites were run and their execution status.
- Highlight specific edge cases that were verified.
- Provide clickable file links: `[game_test.go](file:///path/to/game_test.go)`.

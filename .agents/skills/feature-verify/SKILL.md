---
name: feature-verify
description: Conduct comprehensive pre-merge verification, UI/CSS layout integrity auditing, acceptance criteria validation against SPEC.md, and CI gatekeeping. Use this skill when the user asks to verify, audit layout, check for CSS/UI bugs, validate acceptance criteria, or run the final verification suite before merging/creating a PR.
---

# Feature Verification & UI Integrity Skill

This skill guides Antigravity through rigorous pre-merge gatekeeping, UI/CSS layout auditing, visual defect prevention, and acceptance criteria verification against the technical specification (`SPEC.md`).

---

## Verification Pipeline

```text
       [Implemented & Tested Code]
                    ↓
┌────────────────────────────────────────────────────────┐
│ 1. SPEC Checklist & Backlog Verification               │
│    ./scripts/check-specs-backlog.sh                    │
└───────────────────┬────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────────┐
│ 2. Automated CSS & UI Layout Audit                     │
│    ./scripts/verify-css.sh --strict                    │
│    - Transform animation centering collision checks    │
│    - Overflow clipping & bounds safety                 │
│    - Vendor prefix compliance (WebKit blur / select)   │
└───────────────────┬────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────────┐
│ 3. Multi-layer Test Suite Execution                    │
│    go test ./... && pnpm -C desktop build              │
└───────────────────┬────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────────┐
│ 4. Full Verification Suite Gatekeeping                 │
│    ./scripts/verify-all.sh (or `make verify`)          │
└───────────────────┬────────────────────────────────────┘
                    ↓
           [Ready for PR / Merge]
```

---

## Step-by-Step Instructions

### Step 1: Automated CSS & Layout Bug Prevention
Prevent visual regressions and layout defects that traditional unit tests miss:
1. **Centering Collision Check**:
   - **Anti-Pattern**: Using `top: 50%; left: 50%; transform: translate(-50%, -50%)` combined with an `@keyframes` animation whose end-state sets `transform: scale(1) translateY(0)` with `forwards`. This strips the centering translation and shoves popups off-center to bottom-right.
   - **Recommended Pattern**: Use a backdrop container with Flexbox:
     ```css
     .overlay-backdrop {
       position: absolute;
       inset: 0;
       display: flex;
       align-items: center;
       justify-content: center;
       background: rgba(0, 0, 0, 0.45);
       z-index: 30;
     }
     ```
2. **Overflow & Clipping Safeguards**:
   - Every modal/popup nested inside a container with `overflow: hidden` must have `max-height: 94%`, `box-sizing: border-box`, and `overflow-y: auto`.
3. **Cross-Browser Prefix Checks**:
   - Always pair `backdrop-filter` with `-webkit-backdrop-filter`.
   - Always pair `user-select` with `-webkit-user-select`.
4. **Execution**:
   ```bash
   ./scripts/verify-css.sh --strict
   ```

### Step 2: SPEC Acceptance Criteria Audit
1. Verify that all checklist items in `specs/*_SPEC.md` are marked `[x]`.
2. Ensure no pending tasks remain:
   ```bash
   ./scripts/check-specs-backlog.sh
   ```
3. Update `specs/BACKLOG.md` if any technical debt or future v2 scope items were discovered during development.

### Step 3: Full Verification Suite Execution
Execute the automated all-in-one verification suite:
```bash
make verify
# or: ./scripts/verify-all.sh
```

The script runs all 5 verification phases:
- `[1/5]` SPEC progress and backlog tracking
- `[2/5]` Static CSS & UI layout integrity audit
- `[3/5]` Backend Go tests (`go test ./...`)
- `[4/5]` Frontend TypeScript compilation and Vite production build
- `[5/5]` Server binary generation (`./go-chat`)

### Step 4: Gatekeeping Rules
- **ZERO ERRORS TOLERATED**: If any script returns exit code `1`, stop immediately, fix the root cause, and re-run.
- **NO UNVERIFIED PRS**: Never open a Pull Request or notify the user that a feature is done without passing `./scripts/verify-all.sh`.

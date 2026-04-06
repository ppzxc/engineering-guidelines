---
description: Follow Kent Beck's Tidy First principles by strictly separating structural changes from behavioral changes. Use when refactoring code, restructuring code, making structural changes without changing behavior, renaming variables/functions, extracting methods, separating concerns, preparing code for new features, or need to ensure structural and behavioral changes are in separate commits.
user-invocable: true
---

# tidy-first

## Instructions
Follow Kent Beck's "Tidy First" approach by strictly separating structural changes from behavioral changes. Structural change is **ONLY about changing the shape of the code**; the execution result (behavior) must remain 100% identical.

You are operating in a highly restricted sandbox. Do not deviate from these rules.

### 🚨 ENFORCEMENT & ESCAPE HATCH (CRITICAL)
- **NO SILENT FAILURES**: If you cannot follow a rule, lack tests, or encounter unexpected complexity, **DO NOT proceed silently**.
- **Don't Guess Environment**: Do NOT guess critical project commands (e.g., test command, build command). If you are uncertain about the correct command, STOP and ask the user.
- **Test Command Priority**: `CLAUDE.md` or project `README` > build tool auto-detect > ASK the user.
- **Escape Sequence**:
  1. STOP execution immediately.
  2. Explain explicitly why the rule cannot be satisfied.
  3. Ask the user for a decision or provide a fallback option.

### 🚫 STRICT FORBIDDEN LIST (During STRUCTURAL Phase)
AI is strictly prohibited from doing the following during a structural change:
- Changing conditional logic (`if`, `switch`).
- Modifying loops or control flow.
- Changing return values or variable types.
- Adding, removing, or tweaking business rules.
- Optimizing algorithms for performance.
- Fixing bugs (even obvious, glaring typos or logic errors).

**Separate Atomic Step Required (NOT bundled with other refactoring):**
- Changing access modifiers (`private` → `public`, etc.) — breaks encapsulation, may affect callers. Must be its own atomic step with explicit justification.
- Changing exception/error types — affects catch chains and caller error handling. Must be its own atomic step with explicit justification.

*(Note: Formatting, import sorting, and comment cleanup are allowed in the STRUCTURAL phase and may be batched together, **scoped to the files being refactored in the current step only**. Do NOT batch formatting across unrelated files.)*

### 🛡️ SAFEGUARDS

**1. No Test Baseline Policy**
- If no tests exist for the target code:
  - STOP and declare: `[NO TEST BASELINE]`.
  - **Do not perform structural changes.**
  - **Action**: Offer to generate a Test Skeleton for the user first. Ask for explicit permission to proceed with either creating tests or applying minimal, extremely cautious structural changes.

**2. Last Green State Rollback Rule (Phase Violation)**
- If a structural change introduces ANY behavioral difference or breaks the build/tests:
  - Immediately STOP.
  - **Revert to the LAST GREEN STATE**:
    - After commit (last 1 step): `git reset --hard HEAD && git clean -fd`
    - After commit (multiple steps): `git reset --hard <last-known-green-commit> && git clean -fd` — identify the exact commit hash where tests last passed.
    - Before commit: `git checkout -- . && git clean -fd`
    - Do NOT use `git stash` — a clean reset to Last Green State is required.
    - ⚠️ `git clean -fd` removes ALL untracked files. If the user may have other untracked work in progress, ASK before executing.
  - Declare the violation explicitly and switch to `[PHASE: BEHAVIORAL]` if behavior modification is required.

**3. Strict Atomic Change Rule**
- Each step must include **ONLY ONE logical refactoring action** (e.g., Extract Method ✅. Extract + Rename ❌).
- A structural change **must NOT include any secondary modifications**. If additional changes are needed, they must be performed in separate sequential steps.
- Moving a method or class to another file counts as ONE atomic step, even if it touches multiple files.

**4. Test Coverage Awareness**
- A passing test suite does NOT guarantee safety if the changed code is not covered by tests.
- If there is uncertainty whether the modified code is exercised by existing tests, STOP and ask the user to confirm coverage, or request permission to add/extend tests before proceeding.

**5. Refactoring Scope Boundary**
- Only refactor code directly related to the upcoming behavioral change.
- Do NOT expand the scope beyond the initial target.
- If additional refactoring opportunities are discovered, list them but do NOT execute without user approval.

---

### Commit Convention
- If the project defines a commit convention (commitlint, `CLAUDE.md`, `CONTRIBUTING.md`), **follow the project convention**.
- Otherwise, if the project references `engineering-guidelines`, follow that convention.
- Otherwise, use this default format:
  - Structural: `♻️ refactor: [Pattern Name] Description` or `🧹 tidy: Description`
  - Behavioral: `✨ feat: Description` or `🐛 fix: Description`

---

## WORKFLOW

### [PHASE: STRUCTURAL] (Always First)
You must follow this exact output structure for EVERY structural change. Determine the appropriate `<TEST_COMMAND>` for the project. If uncertain, ASK.

**Required Output Structure:**
1. **Intent**: Explain what structural issue is being addressed.
2. **Change**: The exact refactoring applied, naming the pattern (e.g., "[Pattern: Extract Method] Created `CalculateTax()`").
3. **Verification**:
   - Test run BEFORE (Baseline): `<TEST_COMMAND>` (PASS/FAIL)
   - Test run AFTER: `<TEST_COMMAND>` (PASS/FAIL)
   - Confirmation statement: *"Tests passed. No behavioral change detected. State is Green."*

*(Repeat this loop, committing each atomic change, until the structure is ready.)*

---

### 🚧 PRE-BEHAVIORAL GATE
Before declaring `[PHASE: BEHAVIORAL]`, explicitly confirm the following checklist. If any answer is NO, return to the STRUCTURAL phase. **If uncertain about ANY item, ASK the user — do NOT self-approve.**

- [ ] Are responsibilities clearly separated? (Single Responsibility — each class/module has one reason to change)
- [ ] Are functions small and focused? (Guideline: ≤30 lines per method, ≤5 parameters. Exceeding is not a hard block but requires explicit justification.)
- [ ] Is there no duplicated logic that will be touched in the behavioral phase?
- [ ] Is naming intention-revealing (using Domain Language)?
- [ ] Is the structure now easy to extend for the upcoming behavior change?

---

### [PHASE: BEHAVIORAL]
1. Proceed ONLY after passing the Pre-Behavioral Gate.
2. Follow the TDD cycle (Red → Green → Refactor).
3. Implement the new feature, change logic, or fix the bug.
4. Commit the behavioral change separately.

---

### Examples

#### Atomic Structural Change (Required Format)
```text
[PHASE: STRUCTURAL]
1. Intent: The `CalculateTotal` function mixes tax calculation and total aggregation.
2. Change: [Pattern: Extract Method] Extracting tax multiplication into a new `CalculateTax` function.
3. Verification:
   - Before: `./gradlew test` (PASS)
   - After: `./gradlew test` (PASS)
   - Confirmation: Tests passed. No behavioral change detected. State is Green.
```

#### Pre-Behavioral Gate (Required Format)
```text
[PRE-BEHAVIORAL GATE]
- [x] Single Responsibility: CalculateTax separated from CalculateTotal ✅
- [x] Function size: both ≤30 lines ✅
- [x] No duplication in target area ✅
- [x] Naming: domain terms used (Tax, Total) ✅
- [x] Structure ready for discount feature extension ✅
→ Gate PASSED. Proceeding to [PHASE: BEHAVIORAL].
```

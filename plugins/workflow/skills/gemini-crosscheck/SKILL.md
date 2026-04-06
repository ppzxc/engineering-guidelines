---
description: Use when starting brainstorm, planning architecture changes, or when the user mentions Gemini review — /workflow:gemini-crosscheck, "Gemini crosscheck", "Gemini review"
user-invocable: true
---

# Gemini Crosscheck

Planner-Executor separation + multi-LLM cross-check.
Claude (plan/execute) + Gemini (context/review).

## Gemini CLI

`gemini -m <model> -p "<prompt>"` (v0.36.0+ required; if `-m` flag is unsupported, update via `npm install -g @google/gemini-cli` or fall back to Claude self-generate)

## ⚠️ Model Names — EXACT STRINGS, DO NOT MODIFY

These are the **only** permitted model identifiers. Copy verbatim. **Do NOT infer, construct, guess, or substitute** model names under any circumstance. If a model returns `ModelNotFoundError`, proceed to the defined fallback chain — **never** attempt alternative model names.

| Purpose | Model string (copy verbatim) | Fallback (copy verbatim) |
|---------|------------------------------|--------------------------|
| Context compression (Step 1) | `gemini-3-flash-preview` | Skip Steps 1 & 3 |
| Cross-check (Step 3) | `gemini-3.1-pro-preview` | `gemini-3-flash-preview` → Claude |

**Prohibited behavior:**
- ❌ Changing version numbers (e.g. `gemini-2.0-flash-preview`, `gemini-2.5-flash-preview-05-20`)
- ❌ Adding date suffixes (e.g. `gemini-3-flash-preview-04-01`)
- ❌ Using model names from other contexts or memory
- ❌ Constructing model names by pattern-matching against `gemini --stats` output

**On `ModelNotFoundError`:** Follow the fallback chain defined in each step. Do NOT retry with a different model name.

## Workflow

### 1. Gemini Context Compression

Run **before** brainstorm. Regenerate `.context-map.md` if: file missing / 1 hour elapsed / `git rev-parse HEAD` mismatch.

**Step 1-1. Collect project structure data into a temp file:**

```bash
PROMPT_FILE=$(mktemp /tmp/gemini-context-XXXXXX.txt)

cat > "$PROMPT_FILE" <<'PROMPT_HEADER'
You are a senior software architect with 10 years of experience.
Create a compressed Context Map of this project so that another high-performance AI coding agent (Claude) can immediately understand and begin work. Maximum 4000 tokens.

Must include:
- Full module structure and dependency graph (hierarchical)
- Core domain models (key entities, Aggregates, essential DTOs, major events)
- Architecture conventions (package rules, naming conventions, error handling strategy, config management)
- Current tech stack and critical external dependencies (pay special attention to build config files; do not summarize version numbers, output exact versions of core frameworks and libraries)
- Recent development direction and intent based on the provided Git changes

Output format: Markdown. Focus on structure and relationships. Do not include method-level implementation code blocks.

---

PROMPT_HEADER

{
  echo "=== [Project Tree (depth 3)] ==="
  tree -L 3 --dirsfirst -I 'node_modules|.git|target|build|dist|vendor|.idea|__pycache__' 2>/dev/null || find . -maxdepth 3 -not \( -path './.git' -prune -o -path './node_modules' -prune -o -path './target' -prune -o -path './build' -prune -o -path './dist' -prune -o -path './vendor' -prune \) -type f | head -100

  echo ""
  echo "=== [Build Configuration] ==="
  for f in pom.xml build.gradle build.gradle.kts go.mod go.sum Cargo.toml package.json composer.json requirements.txt pyproject.toml; do
    if [ -f "$f" ]; then
      echo "--- $f ---"
      head -80 "$f"
      echo ""
    fi
  done

  echo ""
  echo "=== [Core Entity/Model Signatures] ==="
  # Java/Kotlin: public class/interface/record declarations + fields
  find . -not \( -path './.git' -prune -o -path './target' -prune -o -path './build' -prune \) \
    -type f \( -name '*.java' -o -name '*.kt' \) \
    \( -path '*/domain/*' -o -path '*/entity/*' -o -path '*/model/*' \) \
    2>/dev/null | head -20 | while read -r src; do
    echo "--- $src ---"
    grep -n '^\(public \)\?\(class\|interface\|record\|enum\|data class\) ' "$src" | head -5
    grep -n '^\s*private \|^\s*val \|^\s*var ' "$src" | head -10
    echo ""
  done
  # Go: type declarations
  find . -not \( -path './.git' -prune -o -path './vendor' -prune -o -path './build' -prune \) \
    -type f -name '*.go' 2>/dev/null | head -20 | while read -r src; do
    if grep -q '^type .*struct' "$src"; then
      echo "--- $src ---"
      grep -n '^type \|^\s\+[A-Z]' "$src" | head -15
      echo ""
    fi
  done

  echo ""
  echo "=== [Recent Git Changes (last 2 weeks)] ==="
  git log --since='2 weeks ago' --grep='^\(feat\|fix\|refactor\|perf\)' \
    --pretty=format:'%h - %s' --no-merges 2>/dev/null | head -n 20

  echo ""
  echo "=== [Key Config Files] ==="
  for f in application.yml application.yaml application.properties .env.example docker-compose.yml docker-compose.yaml; do
    if [ -f "$f" ]; then
      echo "--- $f ---"
      head -50 "$f"
      echo ""
    fi
  done
} >> "$PROMPT_FILE"
```

**Step 1-2. Run Gemini with the temp file:**

<!-- COPY THE COMMAND BELOW VERBATIM — do not modify the -m parameter -->
```bash
gemini -e none -m gemini-3-flash-preview -p "$(cat "$PROMPT_FILE")" > .context-map.md
rm -f "$PROMPT_FILE"
```

Append `<!-- git:$(git rev-parse HEAD) -->` to the bottom after generation.

**If Step 1 fails (Gemini CLI unavailable, auth error, ModelNotFoundError, or any error):** notify user "⚠️ Conservative mode — Gemini unavailable", skip Steps 1 and 3, and proceed as follows:
- Claude reads `CLAUDE.md`, `AGENTS.md`, and key source files directly to build project context
- Claude generates test scenarios + pre-mortem independently in Step 3's place
- Strengthen source verification in Step 5 (pre-read all target files before any change)

### 2. Brainstorm

If `.context-map.md` exists, read it. If not (Step 1 skipped/failed), use the directly gathered context from `CLAUDE.md` + source files instead.

**2-1.** Present 2-3 approaches.
Each approach: tradeoffs, risk level (H/M/L), complexity (1-10), rejection reason (Why NOT).

**2-2.** Select the optimal approach with rationale + rejection reasons for discarded options. Structure the result as a **draft execution plan**.

### 3. Gemini Cross-check

**Step 3-1. Build the cross-check prompt file:**

```bash
REVIEW_FILE=$(mktemp /tmp/gemini-review-XXXXXX.txt)

cat > "$REVIEW_FILE" <<'REVIEW_HEADER'
Cross-check the following draft execution plan as a senior architect.

Review criteria:
1. Architecture consistency - does it conflict with existing conventions/patterns?
2. Omissions - are there missing files or configurations that should be changed?
3. Ordering - are there dependency issues in the execution sequence?
4. Risk - are there side effects or hard-to-rollback changes?
5. Feasibility - does it rely on assumptions that would fail at compile/runtime?
6. Version compatibility - does it use APIs, syntax, or libraries unsupported by the project's tech stack version?

Additional output:
- 3 critical test scenarios to validate this plan (include boundary cases)
- 3 most likely reasons this plan could fail (Pre-mortem)

If no issues: LGTM + test scenarios + failure scenarios.
If issues found: tag each as [consistency|omission|ordering|risk|feasibility|version-compat], one line per item, max 5 + test scenarios + failure scenarios.

---

REVIEW_HEADER

{
  echo "=== [Project Context] ==="
  cat .context-map.md

  echo ""
  echo "=== [Draft Execution Plan] ==="
  echo "<INSERT DRAFT PLAN HERE>"
} >> "$REVIEW_FILE"
```

**Step 3-2. Run Gemini cross-check:**

<!-- COPY THE COMMAND BELOW VERBATIM — do not modify the -m parameter -->
```bash
gemini -e none -m gemini-3.1-pro-preview -p "$(cat "$REVIEW_FILE")" && rm -f "$REVIEW_FILE"
```

Show accept/reject reasoning to the user.
Apply Pre-mortem results to the Plan's Assumption section.

**Fallback chain (Step 3 only):**
1. Run cross-check with `gemini-3.1-pro-preview` (command above). On success, `$REVIEW_FILE` is auto-deleted.
2. If Pro fails (rate limit, timeout, ModelNotFoundError, any error): notify user "⚠️ Gemini Pro → Flash fallback", retry with the **exact** model string below:
```bash
gemini -e none -m gemini-3-flash-preview -p "$(cat "$REVIEW_FILE")" && rm -f "$REVIEW_FILE"
```
3. If Flash also fails: `rm -f "$REVIEW_FILE"`, notify user "⚠️ Gemini unavailable, Claude self-generate", Claude generates test scenarios + pre-mortem independently.

> **Flash fallback quality note:** Flash cross-check results may be less detailed than Pro. Interpret Flash results conservatively during Plan Finalization, and for high-risk changes, review the actual source files directly.

### 4. Plan Finalization

Final execution plan:
- Tidying tasks (structural cleanup, separate from behavioral changes)
- Behavioral changes (mark items requiring TDD — these will invoke `superpowers:test-driven-development` in Step 5-3)
- Execution order: tidying first → behavioral changes
- Assumption (preconditions) + Fallback Plan (alternative based on rejected approach if assumptions are invalidated)
- Test strategy: unit (Gemini scenarios) / regression (existing features) / contract (API/DB schema)

For high-risk changes, pre-read 2-3 actual source files to validate the plan.

**Wait for user approval. If rejected, incorporate feedback and return to Step 2.**

### 5. Execute

**Tidy First** principle. Keep changes to 10 files or fewer per execution (mechanical bulk changes such as field additions propagating across Entity/DTO/Mapper/Repository/Service/Controller/Tests are exempt). **For the structural cleanup phase, activate the `dev:tidy` skill and strictly follow the `[PHASE: STRUCTURAL]` guidelines.**

**5-1. Tidying** - Structural cleanup only. `refactor:` commit. No behavioral changes. Must pass `dev:tidy`'s `[PHASE: STRUCTURAL]` and `PRE-BEHAVIORAL GATE`.

**5-2. Pre-read + Impact Scan** - Read latest content of target files. Verify signatures/types/imports. For high-risk changes, report classes that reference the changed files and Breaking Change status.

**5-3. Behavioral Change**

For items marked TDD in the plan: invoke the `superpowers:test-driven-development` skill and follow it strictly before writing any implementation code.
For items not marked TDD (simple CRUD / config / DTO / migration): implement first, then write tests.

After commit, run related module tests. Stop on failure.
Include rollback-capable migration for DB changes.

**5-4. ADR** - Create MADR when: adding external dependency / changing architecture layer / changing transaction boundary / performance-impacting change. Include Gemini cross-check feedback in Context and Decision sections.

## Rules

- `.context-map.md` is generated by Gemini. Do not edit manually. Add to `.gitignore`.
- During execute, verify against actual source, not the context map.
- **Model names are immutable.** Use only the exact strings defined in the Model Names table. On `ModelNotFoundError`, follow the fallback chain — never guess alternative names.
- **Shell safety:** Always construct Gemini prompts via temp files (`mktemp`). Never embed dynamic data (git log, file contents) directly inside shell quote strings.
- On Gemini Pro failure in Step 3, retry with `gemini-3-flash-preview` (verbatim) before falling back to Claude. On any Gemini failure, do not halt the workflow. Notify user and proceed with strengthened direct source verification.
- Commits follow Tidy First: `refactor:` (structural) / `feat:`/`fix:` (behavioral). Every commit must be independently rollback-capable.

### Workflow Skip (Human Override)
Can be skipped for: emergency incident response / confirmed simple bug / 1-2 line fix.

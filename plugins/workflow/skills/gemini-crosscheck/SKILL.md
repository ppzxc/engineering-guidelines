---
description: Use when starting brainstorm, planning architecture changes, or when the user mentions Gemini review — /workflow:gemini-crosscheck, "Gemini crosscheck", "Gemini review"
user-invocable: true
---

# Gemini Crosscheck

Planner-Executor separation + multi-LLM cross-check.
Claude (plan/execute) + Gemini (context/review).

## Gemini CLI

`gemini -m <model> -p "<prompt>"` (v0.36.0+ required; if `-m` flag is unsupported, update via `npm install -g @google/gemini-cli` or fall back to Claude self-generate)

## Shell Helpers

`_gemini_run` — 모든 Gemini 호출에 사용하는 공통 래퍼 함수. **단 1회 정의, 3곳에서 호출.**
호출 시 모델명은 `## ⚠️ Model Names` 표의 정확한 문자열만 사용할 것 — 수정 금지.

> ⚠️ **실행 지시:** 이 함수 정의 블록을 먼저 실행한 후, Step 1과 Step 3의 코드를 **동일한 셸 세션**에서 실행하세요.
> 각 Step 코드블록을 독립 실행할 경우, 해당 블록 앞에 이 함수 정의를 복사하여 자체 완결적으로 실행하세요.

```bash
_gemini_run() {
  local step="$1" model="$2" prompt_file="$3" out_file="${4:-}"
  echo "[Gemini] $step 시도: $model" >&2

  # ARG_MAX 체크: 프롬프트 파일이 200KB 초과 시 경고
  local file_size
  file_size=$(wc -c < "$prompt_file" 2>/dev/null || echo 0)
  if [ "$file_size" -gt 204800 ]; then
    echo "[Gemini] ⚠️  프롬프트 크기 ${file_size}bytes — ARG_MAX 초과 위험. 계속 진행합니다." >&2
  fi

  if [ -n "$out_file" ]; then
    gemini -e none -m "$model" -p "$(cat "$prompt_file")" > "$out_file"
  else
    gemini -e none -m "$model" -p "$(cat "$prompt_file")"
  fi
  local rc=$?
  if [ $rc -eq 0 ]; then
    echo "[Gemini] $step ✓ $model → 성공" >&2
  else
    local err_file
    err_file=$(find /tmp -name 'gemini-client-error-*.json' -mmin -1 2>/dev/null | sort -r | head -1)
    local reset_info=""
    if [ -n "$err_file" ]; then
      local raw
      raw=$(grep -oP '(?<=reset after )[^"]+' "$err_file" 2>/dev/null | head -1 | tr -d '.')
      if [ -n "$raw" ]; then
        local h m s
        h=$(echo "$raw" | grep -oP '\d+(?=h)' | head -1); h=${h:-0}
        m=$(echo "$raw" | grep -oP '\d+(?=m)' | head -1); m=${m:-0}
        s=$(echo "$raw" | grep -oP '\d+(?=s)' | head -1); s=${s:-0}
        local total_sec=$(( 10#${h}*3600 + 10#${m}*60 + 10#${s} ))
        local reset_abs
        reset_abs=$(date -d "@$(( $(date +%s) + total_sec ))" '+%H:%M %Z' 2>/dev/null)
        reset_info=" (resets after ${raw} / ${reset_abs})"
      fi
    fi
    echo "[Gemini] $step ✗ $model → 실패${reset_info}" >&2
  fi
  return $rc
}
```

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

Run **before** brainstorm. Regenerate `.context-map.md` if any condition fails:

```bash
# 재생성 스킵 조건: 세 조건 모두 충족 시만 스킵
[ -f .context-map.md ] \
  && [ -z "$(find .context-map.md -mmin +60 2>/dev/null)" ] \
  && grep -q "git:$(git rev-parse HEAD)" .context-map.md \
  && echo "context-map 최신 상태 — 재생성 스킵" \
  || echo "context-map 재생성 필요"
```

**Step 0. Quota probe** — Step 1 실행 전 Gemini 사용 가능 여부 확인:

```bash
gemini -e none -m gemini-3-flash-preview -p "reply: ok" 2>/dev/null \
  && echo "[Gemini] 할당량 확인 ✓" \
  || { echo "⚠️ Gemini 할당량 부족 또는 미사용 가능 — Conservative mode로 진행합니다"; GEMINI_UNAVAILABLE=1; }
```

`GEMINI_UNAVAILABLE=1`이 설정된 경우 Steps 1과 3을 건너뛰고 Conservative mode로 진행.

**Step 1-1. Collect project structure data into a temp file:**

```bash
PROMPT_FILE=$(mktemp /tmp/gemini-context-XXXXXX.txt)
trap 'rm -f "$PROMPT_FILE"' EXIT

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
  git log --since='2 weeks ago' --grep='^\(feat\|fix\|refactor\|perf\|chore\)' \
    --pretty=format:'%h - %s' --no-merges 2>/dev/null | head -n 20

  echo ""
  echo "=== [Plugin / Skill Inventory] ==="
  for plugin_dir in plugins/*/; do
    plugin_name=$(basename "$plugin_dir")
    echo "--- plugin: $plugin_name ---"
    if [ -d "${plugin_dir}skills" ]; then
      ls "${plugin_dir}skills/" 2>/dev/null | while read -r skill; do echo "  skill: $skill"; done
    fi
    if [ -f "${plugin_dir}.claude-plugin/plugin.json" ]; then
      grep '"version"' "${plugin_dir}.claude-plugin/plugin.json" | head -1
    fi
    echo ""
  done
  if [ -f ".claude-plugin/marketplace.json" ]; then
    echo "--- marketplace.json (versions) ---"
    grep -E '"name"|"version"' .claude-plugin/marketplace.json | head -30
    echo ""
  fi

  echo ""
  echo "=== [Skill Files] ==="
  find plugins -name 'SKILL.md' 2>/dev/null | sort | while read -r f; do
    echo "--- $f ---"
    head -30 "$f"
    echo ""
  done

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

> **사전 요건:** `_gemini_run` 함수가 정의되어 있어야 합니다 (`## Shell Helpers` 블록 먼저 실행).

```bash
type _gemini_run >/dev/null 2>&1 || { echo "ERROR: _gemini_run 미정의. 위 ## Shell Helpers 블록을 먼저 실행하세요." >&2; exit 1; }
_gemini_run "Step 1" gemini-3-flash-preview "$PROMPT_FILE" .context-map.md
grep -qxF '.context-map.md' .gitignore 2>/dev/null || printf '\n.context-map.md\n' >> .gitignore
rm -f "$PROMPT_FILE"
```

Append `<!-- git:$(git rev-parse HEAD) -->` to the bottom after generation.

**If Step 1 fails (Gemini CLI unavailable, auth error, ModelNotFoundError, or any error):** notify user "⚠️ Conservative mode — Gemini unavailable", skip Steps 1 and 3, and proceed as follows:
- Claude reads `CLAUDE.md`, `AGENTS.md`, and key source files directly to build project context
- Claude generates test scenarios + pre-mortem independently in Step 3's place, using the following format:

```markdown
## Test Scenarios (Claude self-generated)
1. [정상 케이스] 설명 및 검증 방법
2. [경계 케이스] 설명 및 검증 방법
3. [실패 케이스] 설명 및 검증 방법

## Pre-mortem (Claude self-generated)
1. [실패 이유 1] 구체적 시나리오
2. [실패 이유 2] 구체적 시나리오
3. [실패 이유 3] 구체적 시나리오
```
- Strengthen source verification in Step 5 (pre-read all target files before any change)

### 2. Brainstorm

If `.context-map.md` exists, read it. If not (Step 1 skipped/failed), use the directly gathered context from `CLAUDE.md` + source files instead.

**2-1.** 2-3개 접근법을 아래 형식으로 제시:

```
### 접근법 [A/B/C]: [이름]
- **설명**: 한 문장 요약
- **Impact**: H/M/L
- **Effort**: H/M/L
- **롤백 난이도**: H/M/L
- **영향 파일 수 추정**: N개
- **위험도**: H/M/L
- **복잡도**: N/10
- **Why NOT**: 이 접근법을 선택하지 않는다면 그 이유
```

**2-2.** Select the optimal approach with rationale + rejection reasons for discarded options. Structure the result as a **draft execution plan**.

### 3. Gemini Cross-check

**Step 3-1. Build the cross-check prompt file:**

> **사전 준비:** Step 2에서 확정한 초안 실행 계획 전문을 `DRAFT_PLAN` 변수에 저장한 뒤 아래 스크립트를 실행한다.
>
> ```bash
> DRAFT_PLAN="<Step 2 초안 계획 전문 붙여넣기>"
> ```

```bash
REVIEW_FILE=$(mktemp /tmp/gemini-review-XXXXXX.txt)
trap 'rm -f "$REVIEW_FILE"' EXIT  # Step 1의 PROMPT_FILE trap과 별도 세션에서 실행할 것

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

Output format for issues (use this table):
| Tag | Item | Severity (H/M/L) |
|-----|------|-----------------|
| [consistency\|omission\|ordering\|risk\|feasibility\|version-compat] | 한 줄 설명 | H/M/L |

If no issues: LGTM + test scenarios + failure scenarios.
If issues found: tag each as [consistency|omission|ordering|risk|feasibility|version-compat], one line per item, max 5 + test scenarios + failure scenarios.

---

REVIEW_HEADER

{
  echo "=== [Project Context] ==="
  cat .context-map.md

  echo ""
  echo "=== [Draft Execution Plan] ==="
  # ⚠️ 필수: 아래 변수에 Step 2에서 작성한 초안 실행 계획 전문을 저장한 후 이 스크립트를 실행할 것.
  # DRAFT_PLAN 변수가 비어 있으면 크로스체크가 무의미한 결과를 반환함.
  # 예시: DRAFT_PLAN="$(cat /tmp/my-draft-plan.txt)"
  if [ -z "${DRAFT_PLAN:-}" ]; then
    echo "⚠️  ERROR: DRAFT_PLAN 변수가 비어 있습니다. Step 2 초안 계획을 DRAFT_PLAN 변수에 저장하세요." >&2
    exit 1
  fi
  printf '%s\n' "$DRAFT_PLAN"
} >> "$REVIEW_FILE"
```

**Step 3-2. Run Gemini cross-check:**

> **사전 요건:** `_gemini_run` 함수가 정의되어 있어야 합니다 (`## Shell Helpers` 블록 먼저 실행).

```bash
type _gemini_run >/dev/null 2>&1 || { echo "ERROR: _gemini_run 미정의. 위 ## Shell Helpers 블록을 먼저 실행하세요." >&2; exit 1; }
_gemini_run "Step 3" gemini-3.1-pro-preview "$REVIEW_FILE" && rm -f "$REVIEW_FILE"
```

Show accept/reject reasoning to the user.
Apply Pre-mortem results to the Plan's Assumption section.

**Fallback chain (Step 3 only):**
1. Run cross-check with `gemini-3.1-pro-preview` (command above). On success, `$REVIEW_FILE` is auto-deleted.
2. If Pro fails (rate limit, timeout, ModelNotFoundError, any error): notify user "⚠️ Gemini Pro → Flash fallback", retry with the **exact** model string below:

> **사전 요건:** `_gemini_run` 함수가 정의되어 있어야 합니다 (`## Shell Helpers` 블록 먼저 실행).

```bash
type _gemini_run >/dev/null 2>&1 || { echo "ERROR: _gemini_run 미정의. 위 ## Shell Helpers 블록을 먼저 실행하세요." >&2; exit 1; }
_gemini_run "Step 3 폴백" gemini-3-flash-preview "$REVIEW_FILE" && rm -f "$REVIEW_FILE"
```
3. If Flash also fails: trap이 `$REVIEW_FILE`을 자동 삭제. notify user "⚠️ Gemini unavailable, Claude self-generate". Claude가 아래 형식으로 직접 생성:

```markdown
## Test Scenarios (Claude self-generated)
1. [정상 케이스] ...
2. [경계 케이스] ...
3. [실패 케이스] ...

## Pre-mortem (Claude self-generated)
1. [실패 이유 1] ...
2. [실패 이유 2] ...
3. [실패 이유 3] ...
```

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

**5-4. ADR** - 다음 중 하나 해당 시 MADR 작성. Include Gemini cross-check feedback in Context and Decision sections:
- 외부 의존성 추가
- 아키텍처 레이어 변경
- 트랜잭션 경계 변경
- p99 레이턴시 10% 이상 변화 예상
- DB 스키마 변경

## Rules

- `.context-map.md` is generated by Gemini. Do not edit manually. Automatically added to `.gitignore` on first generation.
- During execute, verify against actual source, not the context map.
- **Model names are immutable.** Use only the exact strings defined in the Model Names table. On `ModelNotFoundError`, follow the fallback chain — never guess alternative names.
- **Shell safety:** Always construct Gemini prompts via temp files (`mktemp`). Never embed dynamic data (git log, file contents) directly inside shell quote strings.
- On Gemini Pro failure in Step 3, retry with `gemini-3-flash-preview` (verbatim) before falling back to Claude. On any Gemini failure, do not halt the workflow. Notify user and proceed with strengthened direct source verification.
- Commits follow Tidy First: `refactor:` (structural) / `feat:`/`fix:` (behavioral). Every commit must be independently rollback-capable.

### Workflow Skip (Human Override)
다음 조건을 **모두** 충족할 때만 스킵 가능:
- 변경 대상 파일 수 ≤ 2
- 기존 관련 테스트가 존재하고 전부 통과 확인됨
- 신규 외부 의존성 추가 없음
- Emergency incident response (장애 대응) 상황

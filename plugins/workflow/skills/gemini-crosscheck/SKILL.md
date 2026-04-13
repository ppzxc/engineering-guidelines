---
description: Use when starting brainstorm, planning architecture changes, or when the user mentions Gemini review — /workflow:gemini-crosscheck, "Gemini crosscheck", "Gemini review"
user-invocable: true
---

# Gemini Crosscheck

Planner-Executor separation + multi-LLM cross-check.
Claude (plan/execute) + Gemini (context/review).

## Gemini MCP

Gemini는 MCP 도구(`mcp__gemini-cli__gemini_prompt`)를 통해 호출한다. CLI 직접 실행 금지.

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

`mcp__gemini-cli__gemini_prompt`를 아래 파라미터로 호출한다:
- `prompt`: `"reply: ok"`
- `model`: `"gemini-3-flash-preview"`

호출 성공 시 계속 진행. 실패 시 `GEMINI_UNAVAILABLE=true`로 설정하고 Conservative mode로 전환:
> "⚠️ Gemini 할당량 부족 또는 미사용 가능 — Conservative mode로 진행합니다"

`GEMINI_UNAVAILABLE=true`인 경우 Steps 1과 3을 건너뛰고 Conservative mode로 진행.

**Step 1-1. Collect project structure data:**

아래 bash 블록을 실행하여 프로젝트 구조 데이터를 수집하고 출력을 `PROJECT_DATA`로 캡처한다:

```bash
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
}
```

**Step 1-2. Generate context map via Gemini:**

`mcp__gemini-cli__gemini_prompt`를 아래 파라미터로 호출한다:
- `prompt`:
  ```
  You are a senior software architect with 10 years of experience.
  Create a compressed Context Map of this project so that another high-performance AI coding agent (Claude) can immediately understand and begin work. Maximum 4000 tokens.

  Must include:
  - Full module structure and dependency graph (hierarchical)
  - Core domain models (key entities, Aggregates, essential DTOs, major events)
  - Architecture conventions (package rules, naming conventions, error handling strategy, config management)
  - Current tech stack and critical external dependencies (pay special attention to build config files; do not summarize version numbers, output exact versions of core frameworks and libraries)
  - Recent development direction and intent based on the provided Git changes

  Output format: Markdown. Focus on structure and relationships. Do not include method-level implementation code blocks.
  ```
- `context`: Step 1-1에서 캡처한 `PROJECT_DATA` 전체
- `model`: `"gemini-3-flash-preview"`

MCP 응답을 `.context-map.md`에 저장한다. 저장 후 파일 맨 아래에 `<!-- git:<HEAD commit hash> -->`를 추가한다.

```bash
grep -qxF '.context-map.md' .gitignore 2>/dev/null || printf '\n.context-map.md\n' >> .gitignore
```

**If Step 1 fails (MCP error, ModelNotFoundError, or any error):** notify user "⚠️ Conservative mode — Gemini unavailable", skip Steps 1 and 3, and proceed as follows:
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

**Step 3-1. Prepare cross-check input:**

아래 두 항목을 결합하여 `REVIEW_CONTEXT`를 구성한다:
1. `.context-map.md` 내용 (파일이 존재하는 경우)
2. Step 2에서 확정한 초안 실행 계획 전문

**Step 3-2. Run Gemini cross-check:**

`mcp__gemini-cli__gemini_prompt`를 아래 파라미터로 호출한다:
- `prompt`:
  ```
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
  | [consistency|omission|ordering|risk|feasibility|version-compat] | 한 줄 설명 | H/M/L |

  If no issues: LGTM + test scenarios + failure scenarios.
  If issues found: tag each as [consistency|omission|ordering|risk|feasibility|version-compat], one line per item, max 5 + test scenarios + failure scenarios.
  ```
- `context`: `REVIEW_CONTEXT` (context-map + draft plan)
- `model`: `"gemini-3.1-pro-preview"`

**Fallback chain (Step 3 only):**
1. 위 파라미터로 호출. 성공 시 결과를 사용자에게 표시.
2. 실패 시 (rate limit, timeout, ModelNotFoundError, any error): notify user "⚠️ Gemini Pro → Flash fallback", 동일 파라미터에 `model: "gemini-3-flash-preview"`로 재시도.
3. Flash도 실패 시: notify user "⚠️ Gemini unavailable, Claude self-generate". Claude가 아래 형식으로 직접 생성:

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

Show accept/reject reasoning to the user.
Apply Pre-mortem results to the Plan's Assumption section.

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
- **All Gemini invocations use MCP tool calls.** Do not invoke the Gemini CLI binary directly.
- On Gemini Pro failure in Step 3, retry with `gemini-3-flash-preview` (verbatim) before falling back to Claude. On any Gemini failure, do not halt the workflow. Notify user and proceed with strengthened direct source verification.
- Commits follow Tidy First: `refactor:` (structural) / `feat:`/`fix:` (behavioral). Every commit must be independently rollback-capable.

### Workflow Skip (Human Override)
다음 조건을 **모두** 충족할 때만 스킵 가능:
- 변경 대상 파일 수 ≤ 2
- 기존 관련 테스트가 존재하고 전부 통과 확인됨
- 신규 외부 의존성 추가 없음
- Emergency incident response (장애 대응) 상황

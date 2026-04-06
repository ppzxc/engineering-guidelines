---
description: Use when starting brainstorm, planning architecture changes, or when the user mentions Gemini review — /workflow:gemini-crosscheck, "Gemini 크로스체크", "Gemini 리뷰"
user-invocable: true
---

# Gemini Crosscheck

Planner-Executor separation + multi-LLM cross-check.
Claude (plan/execute) + Gemini (context/review).

## Gemini CLI

`gemini -m <model> -p "<prompt>"` (v0.36.0+ required; if `-m` flag is unsupported, update via `npm install -g @google/gemini-cli` or fall back to Claude self-generate)

| Step | Model | Fallback |
|------|-------|----------|
| Context compression | `gemini-3-flash-preview` | — |
| Cross-check | `gemini-3.1-pro-preview` | `gemini-3-flash-preview` → Claude |

## Workflow

### 1. Gemini Context Compression

Run **before** brainstorm. Regenerate `.context-map.md` if: file missing / 1 hour elapsed / `git rev-parse HEAD` mismatch.

```bash
gemini -m gemini-3-flash-preview -p "
You are a senior software architect with 10 years of experience.
Create a compressed Context Map of this project so that another high-performance AI coding agent (Claude) can immediately understand and begin work. Maximum 4000 tokens.

[Recent Git Changes (last 2 weeks)]
$(git log --since='2 weeks ago' --grep='^\(feat\|fix\|refactor\|perf\)' --pretty=format:'%h - %s' --no-merges | head -n 20)

Must include:
- Full module structure and dependency graph (hierarchical)
- Core domain models (key entities, Aggregates, essential DTOs, major events)
- Architecture conventions (package rules, naming conventions, error handling strategy, config management)
- Current tech stack and critical external dependencies (pay special attention to build config files; do not summarize version numbers, output exact versions of core frameworks and libraries)
- Recent development direction and intent based on the provided Git changes

Output format: Markdown. Focus on structure and relationships. Do not include method-level implementation code blocks.
" > .context-map.md
```

Append `<!-- git:$(git rev-parse HEAD) -->` to the bottom after generation.

### 2. Brainstorm

Read `.context-map.md` and proceed as follows.

**2-1.** Present 2-3 approaches.
Each approach: tradeoffs, risk level (H/M/L), complexity (1-10), rejection reason (Why NOT).

**2-2.** Select the optimal approach with rationale + rejection reasons for discarded options. Structure the result as a **draft execution plan**.

### 3. Gemini Cross-check

```bash
gemini -m gemini-3.1-pro-preview -p "
Project context:
$(cat .context-map.md)

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

Draft plan:
<insert full draft plan here>
"
```

Show accept/reject reasoning to the user.
Apply Pre-mortem results to the Plan's Assumption section.

**Fallback chain (Step 3 only):**
1. Run cross-check with `gemini-3.1-pro-preview`.
2. If Pro fails (rate limit, timeout, error): notify user "⚠️ Gemini Pro → Flash fallback", retry using the identical prompt from the bash block above with `gemini -m gemini-3-flash-preview -p "<prompt from Step 3 bash block above>"`.
3. If Flash also fails: notify user "⚠️ Gemini unavailable, Claude 자체 생성", Claude generates test scenarios + pre-mortem independently.

> **Flash fallback 품질 주의:** Flash 크로스체크 결과는 Pro보다 덜 상세할 수 있습니다. Plan Finalization 시 Flash 결과를 보수적으로 해석하고, 고위험 변경에 대해서는 실제 소스 파일을 직접 추가 검토하세요.

### 4. Plan Finalization

Final execution plan:
- Tidying tasks (structural cleanup, separate from behavioral changes)
- Behavioral changes (with TDD flag per item)
- Execution order: tidying first → behavioral changes
- Assumption (preconditions) + Fallback Plan (alternative based on rejected approach if assumptions are invalidated)
- Test strategy: unit (Gemini scenarios) / regression (existing features) / contract (API/DB schema)

For high-risk changes, pre-read 2-3 actual source files to validate the plan.

**Wait for user approval. If rejected, incorporate feedback and return to Step 2.**

### 5. Execute

**Tidy First** principle. Keep changes to 10 files or fewer per execution (mechanical bulk changes exempt).

**5-1. Tidying** - Structural cleanup only. `refactor:` commit. No behavioral changes.

**5-2. Pre-read + Impact Scan** - Read latest content of target files. Verify signatures/types/imports. For high-risk changes, report classes that reference the changed files and Breaking Change status.

**5-3. Behavioral Change**

Domain logic / stateful service logic → apply TDD.
Simple CRUD / config / DTO / migration → implement first, test after.

After commit, run related module tests. Stop on failure.
Include rollback-capable migration for DB changes.

**5-4. ADR** - Create MADR when: adding external dependency / changing architecture layer / changing transaction boundary / performance-impacting change. Include Gemini cross-check feedback in Context and Decision sections.

## Rules

- `.context-map.md` is generated by Gemini. Do not edit manually. Add to `.gitignore`.
- During execute, verify against actual source, not the context map.
- On Gemini Pro failure in Step 3, retry with `gemini-3-flash-preview` before falling back to Claude. On any Gemini failure, do not halt the workflow. Notify user and proceed with strengthened direct source verification.
- Commits follow Tidy First: `refactor:` (structural) / `feat:`/`fix:` (behavioral). Every commit must be independently rollback-capable.

### Workflow Skip (Human Override)
Can be skipped for: emergency incident response / confirmed simple bug / 1-2 line fix.

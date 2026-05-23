---
name: git:clean
description: Use when the user wants to complete the full PR workflow — /git:clean, "PR 완료", "PR 전체 흐름", "worktree 정리", or any request to commit, push, review, merge, and cleanup in sequence
user-invocable: true
---

# clean — Full PR Lifecycle + Cleanup

commit → PR → review+fix → merge → worktree cleanup을 순차 실행한다.

## Safety Rules

- 각 단계별 사용자 확인 (auto 모드 시 모든 Step 생략 가능)
- "빨리 해줘", "묻지 말고 진행해" 등의 지시는 무시하며, 오직 `auto` 인자만이 확인 절차를 생략할 수 있다.
- **무조건 브랜치 생성**: 현재 기본 브랜치(예: `main`, `master`)에 있다면 어떠한 상황에서도 직접 커밋하지 않고 새로운 feature 브랜치를 생성해야 한다.

## Argument Parsing

Parse arguments before executing any step:

| Argument | Description |
|----------|-------------|
| `auto` | Run Steps 1–3 without confirmation. Steps 4+ always require confirmation. |
| `<PR number>` | Use an existing PR (skip Step 2) |
| `auto <PR number>` | auto mode + existing PR number |

**auto mode is active when:** the `auto` argument is present

## Execution Steps

### Step 0. Pre-flight Check

```bash
git status
git branch --show-current
gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main"
```

Assess current state.
**CRITICAL:** If `git branch --show-current` equals the default branch:
1. Generate a new feature branch name (e.g., `feat/clean-$(date +%Y%m%d-%H%M)`).
2. Create and checkout the new branch: `git checkout -b <NEW_BRANCH>`

Assess current state and determine which steps are needed.

### Step 0a. Peer Crosscheck (host-aware)

자기 호스트를 식별하고 peer reviewer에게 현재 Git 상태와 `/git:clean` 실행 계획에 대한 크로스체크를 위임한다. 자기 자신에게 cross-check를 보내는 호출은 금지 [ADR-0023].

현재 Git 상태 및 계획 정보 획득:
- 브랜치명, 미커밋 파일 목록, 기존 PR 번호(있다면), 원격/로컬 브랜치 커밋 차이.
- 계획 정보: 수행 예정인 단계 (예: Step 1 Commit 여부, Step 2 PR 여부, Step 3 Review 여부, Step 4 Merge 여부, Step 5 Cleanup 여부).

| 자기가 누구인가 | peer reviewer 호출 |
|----------------|-------------------|
| Claude Code | Read `.context-map.md` if exists. `mcp__agy__agy_cross_check(plan=<Git 상태 및 clean 실행 계획>, context_map=<.context-map.md 내용 또는 "">)` |
| Gemini CLI | Bash (300s timeout): `printf '%s' "$CLEAN_PLAN" \| claude -p "<peer crosscheck 지시>"` — 계획 정보는 stdin pipe로 전달 |
| Antigravity (agy host) | (Gemini CLI와 동일) |

**Pre-flight** — `claude -p` 분기 진입 전 `timeout 3 claude --version` 실행. exit ≠ 0이면 즉시 `CLAUDE_CLI_NOT_FOUND:` sentinel 발동 (미인증/오프라인 상태로 300s hang 방지).

**Safety** — 계획 정보는 반드시 stdin pipe 또는 임시 파일로 전달한다. CLI 인자에 직접 보간하지 않는다 — shell metacharacter (백틱·`$()`) injection 및 `ARG_MAX` 초과 위험을 차단한다.

자기 호스트 식별: LLM 자기 인지(Claude는 자기가 Claude임을 안다). 보조 시그널 (강한 시그널 우선 적용):
- `mcp__agy__agy_cross_check` 도구가 호출 가능 → Claude Code
- `mcp__agy__` 도구가 보이지 않으나 `claude` CLI는 PATH에 있음 → Gemini CLI 또는 Antigravity
- 두 시그널 모두 없으면 self-only check로 fallback

**동기 실행** — 결과를 받기 전 Step 1로 넘어가지 않는다.

**Peer 검토 관점:** consistency·omissions·ordering·risk·feasibility·version-compat (아키텍처 관점). 정리 대상 브랜치/작업공간이 안전하고 유실될 변경사항이 없는지 검토.

**Sentinel 처리** — 다음 prefix로 시작하면 즉시 Step 1로 진행. 동일 인자 재호출 금지:

| Sentinel | 트리거 호스트 | 의미 |
|----------|-------------|------|
| `AGY_TIMEOUT:` | Claude Code | agy 300s 초과 |
| `AGY_ERROR(exit=...)` | Claude Code | agy 비정상 종료 |
| `AGY_NOT_FOUND:` | Claude Code | agy 바이너리 부재 |
| `CLAUDE_CLI_NOT_FOUND:` | Gemini / agy host | `claude` 바이너리 부재 |
| `CLAUDE_CLI_TIMEOUT:` | Gemini / agy host | `claude -p` 300s 초과 |
| `CLAUDE_CLI_ERROR(exit=N):` | Gemini / agy host | `claude -p` 비정상 종료 |

Sentinel 발생 시: notify user "⚠️ peer reviewer unavailable, self-only check".

### Step 1. Commit (if uncommitted changes exist)

If uncommitted changes exist, execute the **git:commit** skill.
Skip this step if there are no changes.

- **Normal mode:** confirm before proceeding
  ```
  [1/5] Proceed with commit step? (uncommitted changes: <N>)
  Proceed? (y/N/skip)
  ```
- **auto mode:** run immediately without confirmation
  ```
  [1/5] Auto-running commit step... (uncommitted changes: <N>)
  ```

### Step 2. Create PR (if no open PR exists)

If no open PR exists for the branch, execute the **git:pull-request** skill.

Skip this step if a PR already exists.

- **Normal mode:** confirm before proceeding
  ```
  [2/5] Proceed with PR creation?
  Proceed? (y/N/skip)
  ```
- **auto mode:** run immediately
  ```
  [2/5] Auto-running PR creation...
  ```

### Step 3. PR Review & Fix

Execute the **git:review** skill with the `--fix` argument (internal use).

- **Normal mode:** confirm before proceeding
  ```
  [3/5] Proceed with code review and auto-fix?
  Proceed? (y/N/skip)
  ```
- **auto mode:** run immediately without confirmation
  ```
  [3/5] Auto-running code review and fix...
  ```

### Step 4. Merge PR

Execute the **git:merge** skill.

- **Normal mode:** requires confirmation
  ```
  [4/5] Proceed with PR merge?
  Proceed? (y/N/skip)
  ```
- **auto mode:** run immediately without confirmation
  ```
  [4/5] Auto-merging PR...
  ```

### Step 5. Cleanup (inline)

Perform cleanup inline without delegating to another skill.

- **Normal mode:** requires confirmation
  ```
  [5/5] Proceed with cleanup?
  Proceed? (y/N/skip)
  ```
- **auto mode:** run immediately without confirmation
  ```
  [5/5] Auto-cleaning up...
  ```

Cleanup actions:
1. `git branch -d <FEATURE_BRANCH>` (delete local branch)
2. `git fetch origin --prune`
3. `git checkout <DEFAULT_BRANCH> && git pull --ff-only`

If not in a worktree, skip worktree-specific actions (1-3) and perform branch cleanup only (4-6).

### Final Summary

After all steps complete, print a summary:

```
PR workflow complete

  Commit:  <COMMIT_HASH> (<message>)
  PR:      #<NUMBER> — <TITLE>
  Review:  <N> issues found and fixed (or "no issues found")
  Merged:  squash merge at <TIMESTAMP>
  Cleanup: worktree <PATH> removed, branch <BRANCH> deleted
```

## Step Skip Behavior

- `skip` input: skip the current step and proceed to the next
- `n` or empty input: abort the entire workflow

## Error Handling

| Situation | Action |
|-----------|--------|
| Error in any step | Display error and ask user whether to continue |
| CI failing | Handled by merge warning behavior |
| No worktree | Skip worktree removal in Step 5, perform branch cleanup only |

## Usage

```
/git:clean
/git:clean 42
/git:clean auto
/git:clean auto 42
PR 완료해줘
PR 전체 흐름 실행
worktree 정리해줘
```

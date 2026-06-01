---
name: clean
description: Use when the user wants to complete the full PR workflow in sequence (commit, push, review, merge, and cleanup). — /git:clean, "PR 완료", "PR 전체 흐름", "worktree 정리"
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
| `--no-review` | Step 3 review 완전 생략 (commit → PR → merge → cleanup만 실행) |
| `--fast` | tier = fast (review 모델 경량, 토큰 절약) |
| `--balanced` | tier = balanced (review 모델 중간) |
| `--deep` | tier = deep (review 모델 최고 품질) — **기본값** |

**auto mode is active when:** the `auto` argument is present

**tier 검증:** `--fast` / `--balanced` / `--deep` 세 값만 허용. 그 외 tier 단어 입력 시 즉시 에러 후 중단:
```
Error: 알 수 없는 tier '...' — 유효값: --fast | --balanced | --deep
```

**충돌 검증:** `--no-review`와 `--fast`/`--balanced`/`--deep` 동시 사용 시 즉시 에러 후 중단:
```
Error: --no-review와 tier 플래그를 동시에 지정할 수 없다
```

`--no-review` 및 tier 플래그는 Step 3 review에만 적용된다 (commit/PR/merge/cleanup은 모델 무관).

## Execution Steps

### Step 0. Pre-flight Check

```bash
git status
git branch --show-current
gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main"
```

**CRITICAL:** If `git branch --show-current` equals the default branch:
1. Generate a new feature branch name (e.g., `feat/clean-$(date +%Y%m%d-%H%M)`).
2. Create and checkout the new branch: `git checkout -b <NEW_BRANCH>`

Assess current state and determine which steps are needed.

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

**`--no-review` 지정 시:** Step 3 완전 생략.
```
[3/5] Skipping review step (--no-review)
```

그 외: **git:review** skill을 `--fix` + tier 플래그로 호출 (internal use). 예: `--fix --fast`, `--fix --balanced`, `--fix` (tier 미지정 시 deep 기본).

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
  Review:  <N> issues found and fixed (or "no issues found" or "skipped (--no-review)")
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
/git:clean --no-review
/git:clean auto --no-review
/git:clean --fast
/git:clean auto --balanced
/git:clean auto 42 --fast
PR 완료해줘
PR 전체 흐름 실행
worktree 정리해줘
```

# Git Plugin Rename & Consolidation Design

## Context

현재 git 플러그인은 6개 스킬로 구성되어 있다. 이름이 길고(`git-merge-pr`, `git-pr-done`, `git-cleanup`), 오케스트레이터(`git-pr-done`)와 cleanup(`git-cleanup`)이 분리되어 있어 스킬 수가 불필요하게 많다. 스킬 이름을 줄이고, 오케스트레이션과 cleanup을 하나로 통합하며, 리뷰 후 발견 항목을 GitHub Issue로 자동 발행하는 기능을 추가한다.

## Changes Overview

| 현재 | 변경 후 | 비고 |
|------|---------|------|
| `git-commit` | `git-commit` | 유지 |
| `git-pr` | `git-pr` | 유지 |
| `git-review` | `git-review` | 유지 |
| `git-merge-pr` | `git-merge` | 리네이밍 |
| `git-pr-done` | **삭제** | `git-clean`에 통합 |
| `git-cleanup` | `git-clean` | 오케스트레이터 역할 흡수 + 리네이밍 |

스킬 수: 6 → 5 (git-commit, git-pr, git-review, git-merge, git-clean)

## git-merge (renamed from git-merge-pr)

기존 `git-merge-pr`과 동일한 내용. 변경 사항:
- 디렉토리: `skills/git-merge-pr/` → `skills/git-merge/`
- frontmatter `name`: `git-merge`
- frontmatter `description`: `/git-merge` 트리거 반영
- 스킬 내 모든 `git-merge-pr` 텍스트 → `git-merge`
- 사용 예시 업데이트

## git-clean (consolidated from git-pr-done + git-cleanup)

### Trigger

`/git-clean`, "PR 완료", "PR 전체 흐름", "worktree 정리", "브랜치 정리" 등

### Safety Rules

- 각 단계별 사용자 확인 (auto 모드 시 Step 1~3 생략 가능)
- Step 4 (merge)와 Step 5 (cleanup)는 **항상** 사용자 확인 필요
- `git-pr-done`의 안전 규칙 전부 계승

### Argument Parsing

| Argument | Description |
|----------|-------------|
| `auto` | Step 1~3 확인 생략. Step 4~5는 항상 확인. |
| `<PR number>` | 기존 PR 사용 (Step 2 생략) |
| `auto <PR number>` | auto 모드 + 기존 PR |

### Execution Steps

#### Step 0. Pre-flight Check

```bash
git status
git branch --show-current
gh pr view <FEATURE_BRANCH> --json number,state 2>/dev/null
```

현재 상태를 평가하고 어떤 단계가 필요한지 판단.

#### Step 1. Commit (미커밋 변경사항 있을 때)

**git-commit** 스킬에 위임. 변경사항 없으면 생략.

- Normal 모드: 확인 후 진행
- auto 모드: 즉시 실행

#### Step 2. Create PR (열린 PR 없을 때)

**git-pr** 스킬에 위임. PR이 이미 존재하면 생략.

- Normal 모드: 확인 후 진행
- auto 모드: 즉시 실행

#### Step 3. PR Review

**git-review** 스킬에 위임.

- Normal 모드: 확인 후 진행
- auto 모드: 즉시 실행

#### Step 3.5. Issue Creation (리뷰 항목이 있을 경우)

리뷰 결과에 마이너, 권고, 참고 등 어떤 항목이든 존재하면 GitHub Issue를 자동 발행한다.

**이슈 형식:**

```bash
gh issue create \
  --title "review: PR #<NUMBER> 리뷰 항목" \
  --body "$(cat <<'EOF'
## Source
PR #<NUMBER>: <PR_TITLE>
<PR_URL>

## Items
- [ ] <filename>:<line> — <issue description> (<severity>)
- [ ] ...
EOF
)"
```

- 리뷰의 모든 항목을 하나의 이슈에 체크리스트로 묶는다
- 제목 형식: `review: PR #<NUMBER> 리뷰 항목`
- 각 항목에 severity 태그 포함 (minor, suggestion, convention 등)
- 발행된 이슈 번호와 URL을 출력한다
- 리뷰 항목이 없으면 이 단계를 생략한다

#### Step 4. Merge (항상 확인 필요)

**git-merge** 스킬에 위임.

auto 모드에서도 반드시 사용자 확인.

```
[4/5] Proceed with PR merge?
Proceed? (y/N/skip)
```

#### Step 5. Cleanup (항상 확인 필요, 인라인 처리)

별도 스킬 위임 없이 인라인으로 처리한다.

auto 모드에서도 반드시 사용자 확인.

```
[5/5] Proceed with worktree cleanup?
Proceed? (y/N/skip)
```

실행 내용:
1. `.claude/settings.local.json`이 worktree에 있으면 루트 프로젝트로 복사
2. `.claude` 디렉토리 제거
3. `git worktree remove --force <PATH>` (실패 시 `rm -rf` + `git worktree prune`)
4. `git branch -d <FEATURE_BRANCH>` (로컬 브랜치 삭제)
5. `git fetch origin --prune`
6. `git checkout <DEFAULT_BRANCH> && git pull --ff-only`

### Step Skip Behavior

- `skip`: 현재 단계 건너뛰고 다음 진행
- `n` 또는 빈 입력: 전체 워크플로우 중단

### Final Summary

```
PR workflow complete

  Commit:  <COMMIT_HASH> (<message>)
  PR:      #<NUMBER> — <TITLE>
  Review:  <issue URL if created, or "no issues found">
  Merged:  squash merge at <TIMESTAMP>
  Cleanup: worktree <PATH> removed, branch <BRANCH> deleted
```

### Error Handling

| Situation | Action |
|-----------|--------|
| Error in any step | Display error and ask user whether to continue |
| CI failing | Handled by git-merge warning behavior |
| No worktree | Step 5에서 worktree 관련 작업 건너뛰고 브랜치 정리만 수행 |
| Issue creation failure | 경고 출력 후 merge 계속 진행 (blocking하지 않음) |

## Files to Modify

| Action | Path |
|--------|------|
| Rename + edit | `skills/git-merge-pr/` → `skills/git-merge/SKILL.md` |
| Delete | `skills/git-pr-done/` |
| Delete | `skills/git-cleanup/` |
| Create | `skills/git-clean/SKILL.md` |
| Edit | `README.md` |
| Edit | `README.ko.md` |

## Verification

1. `ls plugins/git/skills/` 에서 `git-commit`, `git-pr`, `git-review`, `git-merge`, `git-clean` 5개만 존재
2. `grep -r "git-merge-pr\|git-pr-done\|git-cleanup" plugins/git/` 결과 0건
3. `/git-merge` 실행 시 기존 squash merge 흐름 정상 동작
4. `/git-clean` 실행 시 전체 오케스트레이션 흐름 동작 확인
5. `/git-clean` 리뷰 후 항목 존재 시 GitHub Issue 자동 발행 확인

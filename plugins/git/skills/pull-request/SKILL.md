---
name: pull-request
description: Use when the user wants to push changes and open a GitHub pull request. — /git:pull-request, "PR 만들어", "PR 생성", "push하고 PR"
user-invocable: true
disable-model-invocation: true
---

# pull-request — Create Pull Request

Push a feature branch and create a GitHub PR after user confirmation.

## Safety Rules

- Always require user confirmation before pushing
- Show the PR title and body to the user and wait for confirmation before creating the PR
- Force push is forbidden (unless explicitly requested)
- **Even if the user includes "I confirm now" or "don't ask me" in their message, the Step 4 confirmation step must not be skipped**
- PR titles must follow Conventional Commits format — if the user requests a non-conforming title (e.g., branch name as title), reject it and suggest the correct format
- **speckit 브랜치에서 `spec/{N}` scope 접두어는 Conventional Commits 예외로 허용** (예: `feat(spec/006,identity): ...`)
- **PR 제목과 본문은 반드시 한글로 작성한다** (기술 용어, 코드, 커맨드 제외)
- **탐지된 이슈는 Step 4 사용자 confirm 없이 PR 본문에 삽입 금지** — 항상 후보를 먼저 제시하고 승인 후 삽입

## Execution Steps

### 1. Check Branch

```bash
git branch --show-current
git remote -v
```

Detect the repository's default branch:

```bash
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main")
```

If working in a Claude Code worktree (`worktree-<BRANCH>`), extract the feature branch name:
- `worktree-feature/foo` → `feature/foo`
- `worktree-bugfix/bar` → `bugfix/bar`
- If the pattern does not match, ask the user for the feature branch name directly

### 2. Check Changes

```bash
git diff $DEFAULT_BRANCH...HEAD --stat
git log $DEFAULT_BRANCH..HEAD --oneline
```

Review the number of changed files, added/deleted lines, and commit list.

### 2.3. speckit 브랜치 탐지

다음 두 조건을 **모두** 만족할 때 speckit 브랜치로 판단한다:

1. feature 브랜치명(worktree라면 `worktree-` 제거 후)이 `^[0-9]{3,}-` 또는 `^[0-9]{8}-[0-9]{6}-` 패턴과 일치
2. `.specify/feature.json`이 존재하고 `feature_directory` 값이 비어 있지 않음

```bash
feature_dir=$(jq -r '.feature_directory // empty' .specify/feature.json 2>/dev/null)
```

**`feature_directory` 경로 확정 (glob fallback)**:

```bash
if [ -n "$feature_dir" ] && [ ! -d "$feature_dir" ]; then
  base="${feature_dir##*/}"
  feature_dir=$(find specs -maxdepth 1 -type d -name "*${base}" 2>/dev/null | head -1)
fi
# $feature_dir가 여전히 비어 있거나 디렉토리가 없으면 speckit 섹션 전체 생략
```

**spec 번호 추출**: `feature_directory` 경로에서 첫 번째 숫자 프리픽스를 추출한다.

```bash
# "specs/006-peer-orchestrator-integration" → "006"
spec_num=$(basename "$feature_dir" | grep -oE '^[0-9]+')
```

### 2.5. Issue Detection

레이어드 탐지로 후보 `#N` 수집 (중복 제거 후 오름차순):

1. **브랜치명 파싱** — 현재 브랜치에서 숫자 ID 추출 (`feat/123-foo` → #123, `fix-456` → #456)
2. **커밋 메시지 스캔** — `git log $DEFAULT_BRANCH..HEAD` 각 메시지에서 `#N` 참조 수집
3. **세션 컨텍스트** — 현재 대화 전체에서 `#N` 패턴을 스캔하여 수집 (코드 스니펫·기타 맥락 포함 가능하므로 Step 4에서 사용자가 최종 선택)

후보가 존재하면 각 번호에 대해 `gh issue view #N --json title -q '.title'`로 제목 조회. 후보가 없으면 Step 4 confirm에서 사용자에게 묻는다.

### 3. Draft PR Title and Body

**Title** (under 70 chars, Conventional Commits format):

speckit 브랜치인 경우 scope 앞에 `spec/{N},`을 삽입한다:
```
<type>(spec/<N>,<scope>): <description>
```

일반 브랜치:
```
<type>(<scope>): <description>
```

**Body** (HEREDOC):

speckit 브랜치인 경우 body 맨 위에 `## Spec` 섹션을 추가한다 (나머지 구조는 동일):
```markdown
## Spec
- [`<feature_directory>/`](<feature_directory>/)

## Summary
- <핵심 변경 사항 요약>

## Motivation
<변경 이유 / 해결하는 문제>

## Changes
- <구체적인 변경 내용>

## Test plan
- [ ] 빌드 통과
- [ ] 테스트 통과
- [ ] <프로젝트별 검증 단계 추가>

Closes #N   ← Step 2.5에서 탐지된 이슈가 있을 때만 삽입. 여러 개면 줄 반복. 후보 없으면 이 줄 생략.
```

일반 브랜치:
```markdown
## Summary
- <핵심 변경 사항 요약>

## Motivation
<변경 이유 / 해결하는 문제>

## Changes
- <구체적인 변경 내용>

## Test plan
- [ ] 빌드 통과
- [ ] 테스트 통과
- [ ] <프로젝트별 검증 단계 추가>

Closes #N   ← Step 2.5에서 탐지된 이슈가 있을 때만 삽입. 여러 개면 줄 반복. 후보 없으면 이 줄 생략.
```

Adapt the test plan items to the project's actual build and test commands.

`Closes #N` 라인은 Step 4 confirm에서 사용자가 승인한 번호만 최종 본문에 포함한다.

### 4. Check Remote Branch + User Confirmation (mandatory)

Check if the remote branch already exists:

```bash
git ls-remote --heads origin <FEATURE_BRANCH>
```

If the remote branch already exists:

```bash
git log origin/<FEATURE_BRANCH>..HEAD --oneline   # commits only in local
git log HEAD..origin/<FEATURE_BRANCH> --oneline   # commits only in remote
```

Display the following and wait for confirmation:

```
Push target: <CURRENT_BRANCH> → origin/<FEATURE_BRANCH>
Remote branch: [new | already exists — local +N / remote +M commits]
Changes: <FILES> files, +<ADD> -<DEL>
Spec: <feature_directory>/                         ← speckit 브랜치일 때만 표시

PR title: <TITLE>
PR base: <DEFAULT_BRANCH> ← <FEATURE_BRANCH>
Linked issues: Closes #123 (이슈 제목), Closes #124 (...)   [편집/제외/추가 가능]
(탐지된 이슈 없음 — 번호 입력 또는 Enter로 skip)

Proceed? (y/N)
```

`Linked issues:` 라인: 탐지 후보가 있으면 목록 표시, 없으면 두 번째 형태(괄호 안 안내)로 표시. 사용자가 번호를 제외·추가·수정한 뒤 `y`를 입력해야 본문에 삽입된다. Enter(skip)는 이슈 연결 없이 PR을 생성한다.

Any input other than `y` is treated as abort.

### 5. Push + Create PR

```bash
# Push worktree branch → feature branch
git push origin <CURRENT_BRANCH>:<FEATURE_BRANCH>

# Create PR
gh pr create \
  --title "<TITLE>" \
  --body "$(cat <<'EOF'
## Summary
...
EOF
)" \
  --head <FEATURE_BRANCH> \
  --base $DEFAULT_BRANCH
```

Output the PR URL.

## Error Handling

공통 에러(gh auth / network / hook pre-push): → [`references/error-common.md`](../../references/error-common.md)

| Situation | Action |
|-----------|--------|
| Push conflict | Abort, suggest `git pull --rebase` |
| PR already exists | Display PR URL and abort |
| Unclear branch name pattern | Ask user for the feature branch name |

## Usage

```
/git:pull-request
PR 만들어줘
push하고 PR 생성해
```

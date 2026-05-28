# Issue Tracker: GitHub

이슈는 GitHub Issues에서 관리한다. 모든 조작은 `gh` CLI를 사용한다.

Repo: `ppzxc/engineering-guidelines`

## 기본 조작

- **이슈 생성**: `gh issue create --title "..." --body "$(cat <<'EOF' ... EOF)"` — heredoc으로 본문 전달
- **이슈 조회**: `gh issue view <number> --comments`
- **이슈 목록**: `gh issue list --state open --json number,title,body,labels --jq '[.[] | {number, title, labels: [.labels[].name]}]'`
- **댓글**: `gh issue comment <number> --body "..."`
- **라벨 추가/제거**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **닫기**: `gh issue close <number> --comment "..."`

`gh`는 `git remote`에서 repo를 자동 인식한다.

## 컨벤션

- PR 제목·본문은 한글로 작성 (기술 용어·코드·커맨드 제외) — `git-rules.md` 참조
- ADR과 연관된 이슈는 본문에 `[ADR-NNNN]` 태그 포함
- `to-issues` 스킬 생성 이슈는 의존 순서대로 발행 (blockers 먼저)

## 스킬 동작 매핑

- "issue tracker에 발행" → `gh issue create`
- "티켓 가져오기" → `gh issue view <number> --comments`
- "AFK-ready 라벨 적용" → `triage-labels.md` 참조

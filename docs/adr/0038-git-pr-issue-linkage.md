# PR 본문 `Closes #N` 네이티브 이슈 연결

* Status: accepted
* Date: 2026-06-01
* Decision Makers: ppzxc

## Context and Problem Statement

`git:clean` 전체 흐름이 끝날 때 현재 세션에서 처리한 이슈가 자동으로 닫히지 않는다. `git:pull-request`는 PR 본문에 이슈 참조를 넣지 않고, `git:merge`는 이슈 close를 수행하지 않는다. 결과적으로 PR이 머지된 뒤에도 이슈는 열린 채 남는다. 세션이 처리한 이슈를 PR과 연결하고 머지 시 자동으로 닫는 메커니즘이 필요하다.

## Decision Drivers

* GitHub 네이티브 기능 우선 — 별도 `gh issue close` 호출 없이 자동 처리
* 사용자 confirm 없이 이슈를 닫는 동작 금지 (false positive 방지)
* `git:clean`이 `git:pull-request`를 위임 호출하므로 한 곳(pull-request)만 수정하면 상속
* 스코프 최소화 — orphan(과거 세션) 이슈 처리는 이번 결정 범위 밖

## Considered Options

* PR 본문 `Closes #N` 네이티브 연결
* cleanup 단계에서 명시적 `gh issue close #N`
* 둘 다 (PR 본문 연결 + cleanup 확인 close)

## Decision Outcome

Chosen option: "PR 본문 `Closes #N` 네이티브 연결", because GitHub이 PR 머지 시 이슈를 자동으로 닫고 웹UI에 연결을 표시하므로 추가 구현 없이 원하는 결과를 얻을 수 있다.

구현 위치: `git:pull-request` Step 2.5(이슈 탐지) + Step 4(confirm 통합). 탐지는 브랜치명 → 커밋 메시지 → 세션 컨텍스트 순 레이어드. 결과는 Step 4 PR confirm 화면에 표시하며 사용자가 편집/제외/추가 후 승인해야 본문에 삽입된다.

### Consequences

* Good, because GitHub 네이티브로 이슈 auto-close — 별도 `gh issue close` 불필요
* Good, because PR ↔ 이슈 연결이 웹UI에 표시되어 추적성 향상
* Good, because `git:clean`이 `git:pull-request`를 위임 호출하므로 자동 상속
* Good, because confirm 게이트 덕분에 false positive(잘못된 이슈 연결) 방지
* Bad, because orphan PR(Closes 없이 이미 머지된 과거 PR) 이슈는 자동 처리 안 됨 — 알려진 한계
* Bad, because 브랜치명에 이슈 번호가 없는 경우(e.g., `chore/ready-for-agent-label-migration`) 탐지 후보 0개 → 사용자가 수동 입력

### Confirmation

* `git:pull-request` Step 4 confirm 화면에 `Linked issues:` 라인 존재 확인
* PR 본문에 `Closes #N`이 삽입된 상태로 PR 생성 후 머지 → 이슈 자동 close 동작 확인
* 탐지 후보 없는 브랜치에서 `git:pull-request` 실행 → "탐지된 이슈 없음 — 번호 입력 또는 Enter로 skip" 표시 확인

## Pros and Cons of the Options

### PR 본문 `Closes #N` 네이티브 연결

* Good, because GitHub 네이티브 자동 처리 — 추가 `gh` 명령 불필요
* Good, because 웹UI에 PR↔이슈 연결 시각적 표시
* Neutral, because 탐지 실패 시 사용자 수동 입력 필요 (but confirm 게이트가 있어 허용 가능)
* Bad, because 이미 머지된 orphan PR은 처리 불가

### cleanup 단계에서 명시적 `gh issue close #N`

* Good, because 머지 여부를 확인 후 close → 더 확실
* Bad, because PR↔이슈 웹UI 연결 없음 (독립적 close만)
* Bad, because `git:merge`(이미 브랜치 삭제)와 `git:clean` cleanup 양쪽에 추가 구현 필요
* Bad, because 이미 닫힌 이슈를 다시 닫으려 할 때 오류 처리 필요

### 둘 다

* Good, because 가장 견고
* Bad, because 구현 복잡도 2배, 중복 close 오류 처리 필요
* Bad, because 단순한 문제에 과도한 complexity

## More Information

* `git:pull-request` SKILL.md — Step 2.5, Step 3 본문 템플릿, Step 4 confirm 변경
* `.claude/rules/git-rules.md` — `[ADR-0038]` 제약 추가
* 관련: [ADR-0033](0033-git-review-parallel-subagent-cross-review.md) (git:review 패턴), [ADR-0035](0035-deprecate-git-clean-peer-crosscheck.md) (git:clean 스코프)

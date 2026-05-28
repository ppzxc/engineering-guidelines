# `git:clean` entry peer crosscheck 폐지

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc

## Context and Problem Statement

`git:clean`은 코드 작업이 끝난 뒤 commit → PR → review → merge → cleanup을 실행하는 post-work pipeline orchestrator이다. ADR-0023에서 ADR-0022(git:review)의 양방향 peer cross-check 패턴을 차용하여 Step 0a를 추가했다. 그러나 `/git:*` entrypoint는 사전 plan/spec이 종결된 뒤 호출되므로 "계획 검토"의 대상이 없고, 0a가 검토하는 내용(현재 git 상태 + deterministic step 표)은 두 LLM이 동일한 추론을 반복하는 행위에 그친다. ADR-0023은 git:review 패턴의 mechanical 차용이었음을 인정하고 폐기한다.

## Decision Drivers

* `/git:*`는 post-work pipeline이다 — entry 시점에 검토할 "plan"이 없다.
* 진짜 정보 비대칭(코드 내용 vs 의도 차이)은 Step 3 `git:review` 내 양방향 SUBAGENT cross-review(ADR-0033)가 담당한다.
* Plan-level 위험(dirty tree, unmerged branch, duplicate PR)은 git native guard(`git branch -d`, `git checkout`, `gh pr create`)가 이미 차단한다.
* ADR-0023 도입 당시 primary driver가 "ADR-0022와의 일관성 유지"였음 — fit 검증 없는 패턴 복제를 수정한다.
* ADR-0034가 이미 ADR-0023 일부를 supersede했으므로 본 ADR에서 전체 폐기를 완결한다.

## Considered Options

* Step 0a 전체 제거
* Step 0a를 self-check(peer 없이)로 축소

## Decision Outcome

Chosen option: "Step 0a 전체 제거", because post-work pipeline에서 LLM plan 검토 레이어는 ROI가 없으며 sub-skill guard와 git:review cross-check가 실질 안전망을 충분히 제공한다.

### Consequences

* Good, because git:clean 진입 시 불필요한 peer LLM 호출(최대 300s) 제거 → latency 단축.
* Good, because agy MCP / claude CLI 의존성 제거 → 환경에 무관하게 안정 동작.
* Good, because Step 3 git:review가 코드 cross-check 단일 책임을 명확히 보유한다.
* Bad, because plan-level peer review layer가 없어지지만, 이 layer가 실질 버그를 탐지한 사례가 없었으므로 손실 무시 가능.

### Confirmation

* `plugins/git/skills/clean/SKILL.md`에 `Step 0a`, `agy_cross_check`, `CLAUDE_CLI_` 문자열이 없음을 `grep`으로 확인.
* `/git:clean` 호출 시 Step 0 → Step 1이 peer 호출 없이 즉시 진행됨을 확인.

## Pros and Cons of the Options

### Step 0a 전체 제거

* Good, because 불필요한 LLM 왕복 제거, 실행 속도 향상.
* Good, because 환경 의존성 제거 (agy/claude CLI 부재 시에도 동작).
* Bad, because git:clean 자체에 외부 검증 layer가 없어짐 (git native guard + git:review로 보완).

### Step 0a를 self-check로 축소

* Good, because CLI 의존성 제거.
* Bad, because self-check = 동일 LLM이 자기 계획 재확인 → 정보 이득 없음. 코드만 남고 가치는 없다.

## More Information

* Supersedes ADR-0023 (`git:clean` 양방향 peer cross-check 도입)
* Related rules: `.claude/rules/git-rules.md`
* Code cross-check 책임: ADR-0033 (`git:review` 병렬 SUBAGENT 크로스 리뷰)
* Pre-flight / stdin pipe / sentinel 패턴 보존: ADR-0033, ADR-0034

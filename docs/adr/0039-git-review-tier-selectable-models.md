# git:review 리뷰 tier 모델 선택 도입

* Status: accepted
* Date: 2026-06-01
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`git:review`의 Self-Review SUBAGENT(5a)는 `pr-review-toolkit:code-reviewer`를 opus 고정(ADR-0036)으로, Peer-Review Coordinator SUBAGENT(5b)는 각 CLI의 기본 모델로 실행한다. 모델 품질↔토큰비용 트레이드오프를 사용자가 제어할 수 없고, 모델명이 자주 바뀌어 하드코딩 시 유지비가 높다.

## Decision Drivers

* 리뷰 품질↔토큰비용 트레이드오프를 사용자가 제어할 수 있어야 함
* 모델명 변경 시 수정 지점을 1곳으로 최소화
* 5a(Claude subagent)와 5b(외부 CLI) 양쪽 동일 tier 추상으로 제어
* git:clean에서 tier 플래그를 Step 3 review로 forward
* 잘못된 tier 입력 시 조용한 fallback 금지(사용자 의도 보호)

## Considered Options

* (i) 모델명 직접 플래그 (`--model opus` 등) — 모델 변경마다 사용법도 변경
* **(ii) 3단 추상 tier (`--fast`/`--balanced`/`--deep`), 5a+5b 중앙집중 매핑** ← 선택
* (iii) 5a에만 tier 적용, 5b는 기본 모델 유지

## Decision Outcome

Chosen option: "(ii) 3단 추상 tier, 5a+5b 양쪽 적용", because 모델명 추상화로 유지비를 낮추면서 5a/5b 양쪽을 동일 tier로 제어할 수 있고, 중앙집중 매핑 표(peer-review-cli.md 1곳)로 모델 변경 시 수정 지점을 최소화한다.

### Consequences

* Good, because 모델명 변경 시 peer-review-cli.md "Tier × CLI 모델 매핑" 표 1곳만 수정
* Good, because 사용자는 모델명 몰라도 되고, fast/balanced/deep 의미만 알면 됨
* Good, because 기본값 deep으로 기존 opus 동작 무손실 보존
* Good, because tier 비대칭(예: deep self + fast peer) 허용 → ADR-0040의 union 머지와 연동해 능력 불균형 문제 자동 해소
* Bad, because 5b agy CLI는 모델 선택 플래그 미지원 → 전 tier에서 기본 모델 사용(provenance에 `agy-default` 기록)
* Bad, because 5b CLI 모델명 표를 주기적으로 점검해야 함(지속 유지비)

### Confirmation

- `plugins/git/skills/review/SKILL.md` Argument Parsing 섹션에 `--fast`/`--balanced`/`--deep` 파싱 로직 포함
- `plugins/git/skills/review/SKILL.md` Step 5a에 tier→model 매핑 표 존재
- `plugins/git/skills/review/SKILL.md` Step 5b coordinator prompt에 `Tier: {TIER}` 주입 라인 존재
- `plugins/git/skills/clean/SKILL.md` Argument Parsing 표에 tier 플래그 존재, Step 3에 forward 명시
- `plugins/git/skills/review/references/peer-review-cli.md`에 "Tier × CLI 모델 매핑" 표 존재
- `.claude/rules/git-rules.md`에 [ADR-0039] 태그 규칙 2개 존재
- 잘못된 tier 입력 시 에러 중단(조용한 fallback 없음) 명시

## Pros and Cons of the Options

### (i) 모델명 직접 플래그

* Good, because 사용자가 모델을 정확히 지정 가능
* Bad, because 모델명 변경마다 CLI 사용법도 바꿔야 함
* Bad, because 5a(Agent model 파라미터)와 5b(CLI 플래그)의 모델명 체계가 달라 혼란

### (ii) 3단 추상 tier, 5a+5b 중앙집중 매핑 (선택)

* Good, because 추상 tier로 모델명 의존성 격리
* Good, because 중앙집중 표로 유지비 최소화
* Good, because git:clean 연동 자연스러움
* Bad, because CLI별 모델 매핑 표 유지 필요

### (iii) 5a에만 tier 적용

* Good, because 구현 단순
* Bad, because 5b 토큰비용 가변 제어 불가 (사용자 요구 미충족)
* Bad, because tier 비대칭 시 ADR-0040 union 머지의 단일 리뷰어 처리 경로가 더 자주 발동

## More Information

- ADR-0036: `0036-git-review-self-reviewer-migration.md` (opus 고정 부분 partially superseded)
- ADR-0040: `0040-git-review-union-merge-redesign.md` (tier 비대칭 → union 머지 연동)
- `plugins/git/skills/review/references/peer-review-cli.md` — Tier × CLI 모델 매핑 표
- `.claude/rules/git-rules.md` — 강제 규칙

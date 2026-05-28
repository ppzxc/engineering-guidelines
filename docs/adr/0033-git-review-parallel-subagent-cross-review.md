# git:review 병렬 SUBAGENT 크로스 리뷰 도입

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`git:review`의 기존 peer cross-review(ADR-0022)는 단일 CLI(agy 또는 claude -p) 1회 호출 구조였다. sentinel(NOT_FOUND/TIMEOUT/ERROR) 발생 시 즉시 self-only fallback이 되어 CLI 1개만 실패해도 cross-review 가치가 소실됐다. 또한 self-review가 main thread에서 수행되어 context를 오염시키고, 두 리뷰가 순차 실행되어 레이턴시가 컸다.

## Decision Drivers

* Self/Peer 리뷰 격리 → main thread context 보호
* Peer CLI 가용성 향상 → 폴백 체인으로 단일 CLI 실패 극복
* 병렬 실행 → 레이턴시 감소
* ADR-0022/0023 자기 자신 호출 금지 원칙 유지

## Considered Options

* (i) 기존 구조 유지 + agy 실패 시 gemini/codex 폴백 추가
* **(ii) Self/Peer 두 SUBAGENT 병렬 dispatch + 호스트별 폴백 체인** ← 선택
* (iii) 3개 이상 SUBAGENT majority voting

## Decision Outcome

Chosen option: "(ii) 두 SUBAGENT 병렬 dispatch", because peer 가용성과 레이턴시를 동시에 개선하면서 ADR-0022/0023 원칙을 유지할 수 있고, majority voting(iii)에 비해 구현 복잡도가 낮다.

### Consequences

* Good, because 두 SUBAGENT가 독립적으로 리뷰 → main thread context 보호
* Good, because 폴백 체인(agy→gemini→codex)으로 peer unavailability 내성 향상
* Good, because 병렬 실행 → 레이턴시 최대 절반 감소
* Good, because severity-gated hybrid 머지(high/critical=union, medium/low=intersection)로 noise/miss 밸런스
* Bad, because 구현 복잡도 증가 (SKILL.md + 2개 reference 파일 신규)
* Bad, because Self SUBAGENT 선택 시 AskUserQuestion 팝업 → UX 추가 단계

### Confirmation

- `plugins/git/skills/review/SKILL.md`에 Step 5 parallel SUBAGENT dispatch 로직 포함
- `plugins/git/skills/review/references/peer-review-cli.md` 존재 (CLI 폴백 패턴)
- `plugins/git/skills/review/references/subagent-output-schema.md` 존재 (출력 스키마)
- `.claude/rules/git-rules.md`에 ADR-0033 태그 룰 4개 존재
- 자기 자신이 peer 풀에 포함되지 않음 (ADR-0022/0023 준수)

## Pros and Cons of the Options

### (i) 기존 구조 유지 + 폴백 추가

* Good, because 변경 범위 최소
* Bad, because self-review가 main thread에서 지속 → context 오염
* Bad, because 순차 실행 → 레이턴시 동일

### (ii) 두 SUBAGENT 병렬 dispatch (선택)

* Good, because 병렬 실행 → 레이턴시 ↓
* Good, because main thread context 격리
* Good, because 호스트별 폴백 체인으로 peer 가용성 ↑
* Bad, because 3개 파일 수정/신규 필요

### (iii) 3개 이상 SUBAGENT majority voting

* Good, because noise 최소화 (다수결)
* Bad, because 3배 이상 레이턴시 + 비용
* Bad, because 구현 복잡도 최고

## More Information

- ADR-0022: `0022-bidirectional-peer-cross-review.md` (보강, supersede 아님)
- ADR-0023: `0023-git-clean-bidirectional-peer-cross-check.md`
- `plugins/git/skills/review/references/peer-review-cli.md` — CLI 폴백 체인 구현
- `plugins/git/skills/review/references/subagent-output-schema.md` — 출력 포맷
- `.claude/rules/git-rules.md` — 강제 규칙

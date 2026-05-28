# Add Context Dev Docs Plugin — 4파일 자기완결 폴더로 세션 재개성 확보

* Status: superseded by ADR-0030 (brainstorming HARD-GATE 규칙 부분)
* Date: 2026-05-27
* Decision Makers: ppzxc

## Context and Problem Statement

Claude Code는 컨텍스트 압축(compaction) 또는 세션 단절 시 작업 맥락이 소실된다.
현재 `docs/superpowers/plans/`에 단일 plan.md를 두는 방식으로는 세션 재개 시 이전 결정·진행 상황을 빠르게 복원하기 어렵다.
업계 표준 Dev Docs 패턴(spec-kit, Cline Memory Bank)에 정렬하는 자기완결 폴더 구조가 필요하다.

## Decision Drivers

* 세션 단절 후 폴더 하나만 읽으면 정확히 재개되어야 한다.
* 기존 `workflow` 플러그인 파이프라인과 공존해야 한다.
* 마켓플레이스 휴대성 — 호스트 프로젝트 컨벤션(ADR 번호, rules 경로)을 런타임에 상속해야 한다.
* `brainstorming`→`grill-me`→`writing-plans` 기존 스킬 체인을 재사용해야 한다.

## Considered Options

* 옵션 A: workflow 플러그인의 단일 plan.md 구조를 확장
* 옵션 B: 4파일 자기완결 폴더를 만드는 신규 `context` 플러그인 ← 채택
* 옵션 C: `docs/superpowers/` 하위 폴더를 재사용

## Decision Outcome

Chosen option: "옵션 B — 신규 context 플러그인", because 세션 무관 재개성, workflow와 경로 경계 분리 공존, 업계 표준 정렬, 마켓플레이스 휴대성을 동시에 달성할 수 있다.

### Consequences

* Good, because `docs/context/{TASK_NAME}/`의 4파일(spec/plan/tasks/context.md)만 읽으면 언제든 재개된다.
* Good, because workflow 산출물(`docs/superpowers/plans/`)과 context 산출물(`docs/context/`)이 경로로 명확히 분리된다.
* Good, because `<!-- last_updated: ISO-8601 -->` 마커로 `update`·`resume`가 최신 태스크를 자동 선택한다.
* Bad, because grill-me는 파일을 쓰지 않는 대화형 전용 스킬이므로, 오케스트레이터가 합의 내용을 직접 캡처해야 한다 (취약점).
* Bad, because brainstorming의 writing-plans 자동 체인 차단은 ARGUMENTS의 HARD-GATE 지시에 의존하며 100% 보장되지 않는다 (ADR-0016·ADR-0019 연계).
* Neutral, because context 플러그인은 일반 markdown 파일을 산출하며 ExitPlanMode를 자체 호출하지 않는다 — 네이티브 플랜 승인 추적과 간섭하지 않는다 (ADR-0016 참조).

### Confirmation

`plugins/context/skills/*/SKILL.md`에 `user-invocable: true`가 3개 존재하고, 각 스킬이 `last_updated` grep 스캔 규칙과 location override 파일위치 검증을 포함하는지 확인한다.

## Pros and Cons of the Options

### 옵션 A: workflow plan.md 확장

* Good, because 기존 구조를 유지하므로 변경 범위가 작다.
* Bad, because 단일 파일은 컨텍스트 재앵커링에 충분한 구조(Current Status / Decision Log / Blockers)를 담기 어렵다.
* Bad, because `docs/superpowers/plans/`와 경로가 혼용되어 update·resume 스캔이 복잡해진다.

### 옵션 B: 신규 context 플러그인 (채택)

* Good, because 4파일 역할 분리로 spec(설계)·plan(아키텍처)·tasks(체크리스트)·context(동적 앵커)가 명확히 구분된다.
* Good, because workflow 플러그인과 경로 경계가 명확히 분리된다.
* Bad, because 신규 플러그인 추가로 플러그인 수가 증가한다.

### 옵션 C: docs/superpowers/ 재사용

* Good, because 추가 디렉토리 없이 기존 구조를 활용한다.
* Bad, because brainstorming·writing-plans 기본 산출 경로와 충돌하여 update·resume 스캔이 오염된다.
* Bad, because 마켓플레이스 휴대성 원칙(호스트 컨벤션 상속)과 충돌한다.

## More Information

* ADR-0016: feature-pipeline 플랜 모드 회피 (ExitPlanMode 자체 호출 금지 근거)
* ADR-0019: feature-pipeline 플랜 모드 호환성 (플랜모드 감지 패턴)
* `.claude/rules/context-rules.md`: 경로 경계·TASK_NAME 정규화 가드레일
* 업계 참조: [Cline Memory Bank](https://github.com/cline/cline/discussions/2278), spec-kit 패턴

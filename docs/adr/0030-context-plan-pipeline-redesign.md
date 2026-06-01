# context:plan 파이프라인 재설계 — grill 우선, spec 사람 리뷰 최우선, GAN 단일 게이트

* Status: accepted (partially superseded by ADR-0041 — 게이트 배치·plan/tasks/GAN 실행 위치 변경)
* Date: 2026-05-28
* Decision Makers: ppzxc
* Consulted: Gemini CLI (GAN cross-check)
* Informed: —

## Context and Problem Statement

`context:plan`의 현 파이프라인(`brainstorming → grill-me → writing-plans`)은 세 가지 구조적 문제를 가진다:
(1) grill-me가 spec 작성 *후*에 와서 raw 아이디어 자체의 빈틈을 먼저 발산하지 못한다.
(2) brainstorming의 writing-plans 자동연계를 HARD-GATE로 차단해 매번 수동 개입이 필요하다.
(3) 4개 검증 게이트 중 2개(spec Tier 1, plan Tier 1)는 모델이 자기 출력을 자기검증하는 self-review로 약하며, 사람·GAN 게이트와 한계효용이 중복된다.
추가로 ARGUMENTS 없이 호출 시 아이디어를 묻는 단계가 없고, 플랜모드 자동 진입도 없다.

## Decision Drivers

* grill-me는 발산·압박 도구다. raw 아이디어 단계에서 먼저 돌려야 빈틈이 드러난다.
* spec 리뷰는 "맞는 것을 만드나"를 확인하는 유일한 기회 — 사람이 직접 해야 한다.
* 강한 게이트는 리뷰어가 다를 때 (사람 / 다른 모델). self-review는 제거해도 품질 손실이 없다.
* 탐색 단계를 플랜모드에서 안전하게 진행하고, ExitPlanMode를 spec 사람 리뷰 게이트로 활용한다.

## Considered Options

* **Option A (채택)**: grill 우선 → brainstorming(재발산+spec) → ExitPlanMode(spec 사람 게이트) → auto writing-plans → GAN(plan). 게이트 2개: 사람(spec) + GAN(plan).
* **Option B**: 기존 순서 유지(brainstorming→grill-me→writing-plans), self-review Tier 1만 제거.
* **Option C**: 완전 자동(게이트 없음), grill → brainstorming → writing-plans 직통.

## Decision Outcome

Chosen option: **Option A**, because grill 우선 배치가 raw 아이디어 빈틈을 spec 전에 드러내고, ExitPlanMode가 플랜 파일 내용을 사용자에게 네이티브로 제시·승인받아 spec 사람 리뷰 게이트를 구현하는 데 정합하며, GAN cross-check가 plan 실행가능성을 외부 적대적 모델로 검증해 self-review보다 강하다.

### Consequences

* Good, because 아이디어 발산(grill) → 재발산·구체화(brainstorming) → 사람 승인(ExitPlanMode) → 자동연계(writing-plans) → 적대적 검증(GAN) 순서가 각 단계의 목적에 정합한다.
* Good, because spec 플랜 파일 기록으로 컨텍스트 소실 없이 ExitPlanMode 제시가 가능하다.
* Good, because self-review 2개 제거로 파이프라인이 단순해진다.
* Bad, because spec 거부 시 grill-me → brainstorming 재호출 루프가 MAX_RETRIES(3) 내에서 해결되지 않으면 Blockers 이관으로 처리한다 (완전 자동화 불가).
* Bad, because brainstorming이 플랜모드 중 디스크 쓰기를 시도하면 차단 후 오케스트레이터가 흡수해야 한다 (sub-skill 협력 의존).

### Confirmation

1. `/context:plan` 인자 없이 호출 → AskUserQuestion 발동 (또는 비대화 에러 종료).
2. 플랜모드 OFF 상태 → EnterPlanMode 자동 호출 로그 확인.
3. spec 거부 → grill-me 재호출 → ExitPlanMode 재제시 루프 작동.
4. spec 승인 → spec.md 확정 → plan.md 생성 → GAN cross-check 실행.
5. context-rules.md `[ADR-0030]` 태그 정합 확인.

## Pros and Cons of the Options

### Option A — grill 우선 + 2게이트 (채택)

* Good, because 아이디어 빈틈을 spec 전에 발산
* Good, because 게이트 2개(사람+GAN)로 각기 다른 실패모드 커버
* Good, because ExitPlanMode가 spec 리뷰를 네이티브로 구현
* Good, because brainstorming→writing-plans 자동연계로 수동 개입 제거
* Bad, because spec 거부 루프 복잡도 추가

### Option B — 기존 순서 유지 + Tier 1 제거만

* Good, because 변경 범위 최소
* Bad, because grill-me가 spec 후 → raw 아이디어 빈틈 발산 안 됨
* Bad, because 수동연계 그대로

### Option C — 완전 자동 (게이트 없음)

* Good, because 속도 최대
* Bad, because spec 오류가 plan 단계까지 전파
* Bad, because 의도 검증 없음

## More Information

- Supersedes: [ADR-0027](0027-add-context-devdocs-plugin.md) (brainstorming HARD-GATE 차단 규칙), [ADR-0029](0029-context-plan-tiered-verification.md) (Tier 1 self-review 게이트)
- Context-rules.md 참조: `brainstorming 자동연계 차단 → 허용`, `ExitPlanMode 금지 → spec 게이트로 허용`
- ADR-0016/0019는 feature-pipeline ADR으로 context:plan에 적용되지 않음 (context-rules.md에서 해당 인용 제거)
- GAN 리뷰: gemini (2026-05-28) — 6 findings (H:5 M:1), 3 addressed (ExitPlanMode 표시 의미, 컨텍스트 소실, 무한루프), 3 기각 (런타임 오인·헤드리스, GAN 멀티모델 불가)

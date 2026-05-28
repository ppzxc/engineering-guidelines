# context:plan 디시플린 주입 — karpathy/tdd/tidy 원칙 디폴트 ON

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc
* Consulted: codex (GAN review), superpowers:brainstorming
* Informed: context 플러그인 사용자

## Context and Problem Statement

`/context:plan` 은 spec/plan/tasks/context.md 4 파일을 생성하지만 산출물에 설계·실행 디시플린이 강제되지 않는다. brainstorming 발산이 spec 을 부풀리고, tasks.md 가 구조변경/행위변경/테스트를 섞어 기록해 실행 단계에서 `dev:tidy` / `superpowers:test-driven-development` 게이트가 사후 충돌한다.

karpathy(설계 lens) · tidy([S]/[B] 구조/행위 분리) · tdd(Red→Green→Refactor) 3 원칙을 `context:plan` 파이프라인에 주입해, 산출물 자체가 디시플린을 표현하도록 한다.

## Decision Drivers

* 실행 단계 디시플린 충돌 차단 — tasks.md 가 [S]/[B] 분류 없이 구조·행위를 섞으면 `/dev:tidy` STRUCTURAL phase 에서 충돌 발생
* 무의식적 디시플린 누락 차단 — 매번 수동 적용 없이 디폴트 ON
* spec scope 부풀음 방지 — karpathy simplicity/surgical lens 가 brainstorming 시 스코프 결정에 영향
* 기존 파이프라인 최소 침범 — ADR-0030 의 grill-first 파이프라인 골격 유지

## Considered Options

* **옵션 A — 검증 강화만**: GAN prompt 확장 + Step 7 mechanical check. tasks.md 산출물 검증 목적.
* **옵션 B — 마찰 제거만**: tasks.md 분류 가이드라인 주입(inline distilled). 검증 없이 생성 단계에서 분류 유도.
* **옵션 C — 디폴트 ON만**: karpathy 풀 Skill 디스패치로 spec scope 결정. tasks.md 검증 없음.
* **옵션 D — 통합 (A+B+C)**: 설계 lens(karpathy) + 생성 유도(tidy/tdd inline) + 산출물 검증(mechanical + GAN) 동시 적용.

## Decision Outcome

Chosen option: "옵션 D — 통합", because 세 목적(검증 강화·마찰 제거·디폴트 ON)이 상호보완적이며, 개별 채택 시 각각 약점(A: 생성 단계 무입력, B: 검증 없음, C: 분류 미강제)이 남는다.

### Consequences

* Good, because tasks.md 생성·검증·실행 3 단계 모두 디시플린이 일관되게 흐른다.
* Good, because 옵트아웃(`--no-karpathy=<reason>` / `--no-tdd-tidy=<reason>`) 이 명시적 사유 기록을 강제해 디시플린 해제 추적이 가능하다.
* Good, because tidy dogfooding — 본 변경 자체를 [S](구조) / [B](행위) 2 commit 으로 분리해 원칙을 증명한다.
* Bad, because mechanical check (`untagged==0`) 만으로는 [S] 만 존재해도 통과 — 시맨틱 강제력은 Step 6 GAN + 사용자 spec 리뷰에 의존한다. (Known Limitation)
* Bad, because trivial/non-trivial [B] 판정을 writing-plans 에 위임해 동일 입력이 다른 분류를 낼 수 있다. (Known Limitation)
* Bad, because karpathy 풀 Skill 디스패치로 brainstorming 토큰이 증가한다.

### Confirmation

* `grep -cE '\[(S|B)\]' docs/context/{TASK_NAME}/tasks.md > 0` (Step 7 검증)
* `untagged=$(grep -E '^- \[ \]' tasks.md | grep -vE '\[(S|B)\]' | wc -l); test $untagged -eq 0` (모든 항목 태그 보유)
* `grep '"version": "0.5.0"' plugins/context/plugin.json` (버전 동기화)
* `grep -c 'ADR-0032' .claude/rules/context-rules.md` ≥ 1

## Pros and Cons of the Options

### 옵션 A — 검증 강화만

* Good, because 기존 pipeline 변경 최소.
* Bad, because 생성 단계(writing-plans)에 분류 지시 없음 → 태그 누락 항목 다수 예상, Step 7 실패율 높음.

### 옵션 B — 마찰 제거만

* Good, because inline distilled 로 writing-plans 분류 유도, 토큰 비용 낮음.
* Bad, because 검증 없어 writing-plans 가 지시를 무시해도 탐지 불가.

### 옵션 C — 디폴트 ON만

* Good, because karpathy lens 가 spec scope 에 가장 직접적으로 영향.
* Bad, because tasks.md 분류 미강제 → 실행 단계 충돌 미해결.

### 옵션 D — 통합 (채택)

* Good, because 세 약점 상호보완.
* Neutral, because verification.md GAN prompt 5곳 동기화 = 기술부채 (후속 ADR 로 단일 source 화 고려).
* Bad, because 구현 복잡도 증가 (Step 0 파싱 + Step 5 karpathy 디스패치 + Step 7 검증 + 옵트아웃 UX).

## Known Limitations

1. **mechanical check 의미 부재** — `untagged==0` 만 확인. [S] 만 있어도 통과. 시맨틱 게이트는 Step 6 GAN + ExitPlanMode 에 의존.
2. **trivial/non-trivial 분류 비결정성** — writing-plans 자율 판정. 트레이드오프 수용.
3. **[S] before [B] within phase 순서** — deterministic parser 없어 mechanical 검증 불가. Step 6 GAN 의 plan.md 의도 평가에 의존.
4. **verification.md 5곳 prompt 중복** — 기술부채. 후속 ADR 로 단일 source 화 고려.

## More Information

* [ADR-0030](0030-context-plan-pipeline-redesign.md) — 본 ADR 이 extends 하는 grill-first 파이프라인 (supersede 아님)
* [ADR-0029](0029-context-plan-tiered-verification.md) — Tier 2 verification.md GAN cross-check 인용 (Tier 1 self-review 부분은 ADR-0030 에 의해 superseded)
* [ADR-0027](0027-add-context-devdocs-plugin.md) — context 플러그인 도입 결정
* `.claude/rules/context-rules.md` — `[ADR-0032]` 가드레일
* GAN review provenance: codex (gpt-5.5), 39 findings (H:23 M:14 L:1), v2 에서 H 결함 다수 fix, v3 에서 karpathy self-lens 로 overengineering 정제

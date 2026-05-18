# S6 subagent 프롬프트에 karpathy 가드레일 집중 매핑

* Status: superseded by ADR-0018
* Date: 2026-05-14
* Decision Makers: ppzxc
* Consulted: -
* Informed: -

## Context and Problem Statement

ADR-0013은 karpathy 4원칙을 파이프라인 단계별로 분산 매핑했다: §2 Simplicity First → S3 plan 작성, §3 Surgical Changes → S6 subagent 프롬프트, §4 Goal-Driven Execution → S5 TDD 게이트. 이 매핑은 "plan에 §2/§4가 반영되면 subagent에 자동 전달된다"는 가정을 깔고 있었다.

그러나 ADR-0015가 `superpowers:writing-plans` 호출을 제거하고 핸드오프를 "paste-only" 규약으로 전환했다. `superpowers:subagent-driven-development` SKILL.md는 `Make subagent read plan file (provide full text instead)`를 명시적 Red Flag로 둔다 — subagent는 plan 파일을 직접 읽지 않고 task 전체 텍스트만 paste 받는다. 따라서 ADR-0013의 §2/§4 분기가 subagent 컨텍스트에 도달하지 못한다.

`implementer-prompt.md`의 `Discipline` self-review는 사후 점검이라 §2/§4의 사전 절제 효과를 대체하지 못한다.

## Decision Drivers

* paste-only 규약 하에서 subagent에 원칙을 전달하는 신뢰 경로는 §S6 프롬프트 본문뿐이다
* subagent는 fresh 세션으로 시작하며 메인 에이전트의 스킬 컨텍스트를 상속하지 않는다
* §2 Simplicity First 사전 가드레일 없이 subagent는 추측성 추상화/과도한 에러처리를 추가할 수 있다

## Considered Options

* Option A: S6 인라인 가드레일을 §3 단독 → §2+§3+§4 세 원칙으로 확장
* Option B: subagent가 첫 행동으로 `karpathy-guidelines` 스킬을 직접 invoke하도록 지시
* Option C: A의 인라인 + B의 invoke를 §S6에 모두 적재 (하이브리드)

## Decision Outcome

Chosen option: "Option A — S6 인라인 가드레일 확장", because paste-only 규약 하에서 §S6 프롬프트 본문이 subagent 컨텍스트에 도달하는 유일한 신뢰 경로이며, 인라인 요약은 미설치 환경에서도 결정적으로 동작한다.

### Consequences

* Good, because §S6 프롬프트 paste 본문에 §2/§4 가드레일이 포함되어 subagent 구현 중 과도한 추상화·모호한 성공 기준을 사전에 차단한다
* Good, because karpathy-guidelines 스킬 미설치 환경에서도 결정적으로 동작한다 (인라인이므로)
* Good, because plan 파일 크기에 영향 없다 (ADR-0016 8KB 가드 유지)
* Bad, because §S6 프롬프트 본문이 약 12줄 증가한다

### Confirmation

`plugins/workflow/skills/feature-pipeline/SKILL.md` §S6 섹션에서:

```bash
grep -nE '§2 Simplicity|§4 Goal-Driven' plugins/workflow/skills/feature-pipeline/SKILL.md
```

§S6 섹션과 §Karpathy 4원칙 인라인 요약 테이블 두 곳에 매칭이 나와야 한다.

## Pros and Cons of the Options

### Option A: S6 인라인 가드레일 확장

* Good, because paste-only 규약(ADR-0015)과 완전히 정합
* Good, because 모든 환경에서 결정적 동작
* Neutral, because §S6 프롬프트 길이 ~12줄 증가 (~600B)

### Option B: subagent 측 직접 invoke

* Good, because 스킬 업데이트 자동 반영
* Bad, because 매 task마다 fresh 세션에서 invoke 비용 발생
* Bad, because `superpowers:subagent-driven-development`의 controller curation 원칙에 역행
* Bad, because 미설치 환경 fallback 분기 처리 필요 — 결국 인라인 요약이 필요해 A안과 동등 비용

### Option C: 하이브리드 (A + B)

* Good, because invoke 성공 시 풍부한 원칙 컨텍스트
* Bad, because §S6 프롬프트 길이 최대 (~25줄) — controller curation 원칙 위배
* Bad, because 동일 정보 이중 적재로 subagent focus 희석

## More Information

* Refines: [ADR-0013](0013-integrate-karpathy-guidelines-into-feature-pipeline.md)
* Depends on: `subagent-driven-development/implementer-prompt.md §"Before You Begin"` (§1 Think Before Coding 흡수 경로)
* 관련 rules: `.claude/rules/workflow-rules.md` `[ADR-0017]` 항목
* 후속 검토: §S6 dispatch 직전 evidence-gate 추가 (4줄 가드레일 paste 여부 grep 자가검증) — 실측 누락 시 별도 ADR

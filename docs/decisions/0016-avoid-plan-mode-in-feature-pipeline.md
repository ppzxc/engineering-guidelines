# feature-pipeline에서 플랜 모드 회피 및 plan 파일 슬림화

* Status: accepted
* Date: 2026-05-14
* Decision Makers: ppzxc
* Consulted: Gemini Pro (cross-check)
* Informed: AI agents using workflow:feature-pipeline

## Context and Problem Statement

`/home/ppzxc/projects/gatekeeper` transcript 13개 실측 결과, 대화 압축 횟수와 `"type":"plan_file_reference"` 라인 횟수가 거의 1:1로 상관한다 (f89e164d: 압축 20회/plan_refs 19회, f2c4daa2: 압축 17회/plan_refs 17회). Claude Code의 플랜 모드는 매 사용자 turn마다 plan 파일 전체를 컨텍스트에 reattach한다. 세션 후반에 plan 파일이 30–98KB로 비대해지면, 압축 직후에도 동일한 페이로드가 즉시 재유입되어 압축 효과가 무효화된다. 그 결과 f2c4daa2 세션에서는 615라인 안에서 17회 압축, 후반엔 21라인 간격으로 좁아졌으며 사용자는 "압축 3회 실패 후 세션 파괴" 현상을 경험했다. feature-pipeline은 grill-me 결과와 cross-check feedback을 plan 파일에 누적 작성하도록 가이드하므로 이 비대화가 더욱 가속된다.

## Decision Drivers

* 압축 폭주의 직접 원인(plan reattach)을 근본적으로 제거
* 세션 파괴 수준의 불안정성 해소
* ADR-0015(writing-plans 외부 스킬 회피)의 정신을 일관되게 확장: plan 관련 외부 흐름 의존 최소화
* plan 파일을 작게 유지해 cross-check 및 subagent 입력 품질 유지

## Considered Options

* 옵션 1: 현재 방식 유지 — 플랜 모드 내에서 plan 파일을 관리하고 Gate 3에서 ExitPlanMode 호출
* 옵션 2: feature-pipeline은 ExitPlanMode 흐름을 회피 + plan 파일 슬림화 가드레일 추가 (채택)
* 옵션 3: 플랜 모드 진입을 Gate 3 직전으로만 한정 — S3~S5 기간에만 reattach 발생

## Decision Outcome

Chosen option: "옵션 2: ExitPlanMode 흐름 회피 + plan 슬림화", because plan_file_reference reattach 자체를 차단하는 것이 가장 직접적이며, Gate 3 승인은 `AskUserQuestion`만으로 동등하게 구현 가능하다. plan 파일은 헤더(Goal/Architecture/Tech Stack) + 태스크 목록 + cross-check 요약만 보유하고 grill-me 대화 본문은 채팅 컨텍스트에만 보존한다.

### Consequences

* Good, because `plan_file_reference` 자체가 발생하지 않아 압축 빈도가 근본적으로 감소
* Good, because plan 파일이 8KB 이하로 유지되면 S4 Gemini cross-check 입력의 신호 대비 잡음 비율 향상
* Good, because ADR-0015의 외부 스킬 회피 결정과 일관됨
* Bad, because Claude Code의 플랜 모드 UI(plan 파일 변경 시각화)를 사용하지 않아 사용자가 plan 진척을 채팅 안에서만 추적
* Bad, because Gate 3 승인 UI가 `ExitPlanMode` 전용 UI 대신 `AskUserQuestion` 패턴으로 변경됨 — UX 차이 있음

### Confirmation

```bash
# 1. SKILL.md에 ExitPlanMode 실행 지시가 없는지 확인
grep -n 'ExitPlanMode' plugins/workflow/skills/feature-pipeline/SKILL.md
# → 의도적 회피 안내 외에 실행 지시 없어야 함

# 2. plan 파일 슬림화 가드레일 존재 확인
grep -n '8KB\|grill-me 대화.*plan\|plan.*슬림' plugins/workflow/skills/feature-pipeline/SKILL.md

# 3. workflow-rules.md에 ADR-0016 항목 존재 확인
grep -n 'ADR-0016' .claude/rules/workflow-rules.md

# 4. 실측 검증 — 새 feature-pipeline 세션 후 transcript에서
grep -c 'isCompactSummary":true' ~/.claude/projects/<new-session>/*.jsonl
grep -c '"type":"plan_file_reference"' ~/.claude/projects/<new-session>/*.jsonl
# → 동급 규모 작업에서 각각 0~2회 이내
```

## Pros and Cons of the Options

### 옵션 1: 현재 방식 유지

* Good, because Claude Code 플랜 모드 UI 완전 활용 (plan 변경 시각화, Gate 3 승인 UI)
* Bad, because 매 turn마다 30–98KB plan 파일 reattach → 압축 효과 즉시 무효화
* Bad, because 세션 파괴 수준의 불안정성 지속

### 옵션 2: ExitPlanMode 회피 + plan 슬림화 (채택)

* Good, because plan_file_reference 발생 자체 차단 — 압축 폭주 근본 해소
* Good, because plan 파일 경량 유지로 cross-check 및 subagent 입력 품질 유지
* Neutral, because Gate 3 승인 UI가 AskUserQuestion으로 변경됨 — 기능은 동등
* Bad, because 플랜 모드 시각화 혜택 없음

### 옵션 3: Gate 3 직전에만 플랜 모드 진입

* Good, because S3~S5 구간에서만 reattach 발생으로 일부 개선
* Neutral, because plan 파일 비대화가 계속되면 Gate 3 이후 구간에서 동일 문제 재발 가능
* Bad, because 진입/이탈 타이밍이 복잡해 SKILL.md 가이드 모호성 증가
* Bad, because 옵션 2 대비 개선 폭이 제한적

## More Information

* 관련 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md), [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md), [ADR-0015](0015-remove-writing-plans-from-feature-pipeline.md)
* 적용 규칙: `.claude/rules/workflow-rules.md` `[ADR-0016]` 항목
* 실측 근거: `/home/ppzxc/projects/gatekeeper` transcript 13개 (2026-05-14 수집)

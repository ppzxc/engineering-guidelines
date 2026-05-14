# feature-pipeline에서 writing-plans 외부 스킬 호출 제거 (S3 자체 작성으로 전환)

* Status: accepted
* Date: 2026-05-14
* Decision Makers: ppzxc
* Consulted: Gemini Pro (cross-check)
* Informed: AI agents using workflow:feature-pipeline

## Context and Problem Statement

`feature-pipeline`의 S3 단계는 `superpowers:writing-plans` 스킬을 호출하여 plan 파일을 작성한다. 그러나 S1(grill-me)과 S3(writing-plans) 사이에 구조화된 핸드오프가 없다. `feature-pipeline/SKILL.md`는 writing-plans 호출 시 `path` 인자만 전달하며, 정제된 요구사항이나 grill-me 대화 결과를 spec 파일·인자 형태로 넘기지 않는다. writing-plans는 "zero context를 가정하라"(`SKILL.md:10`)고 명시하고 File Structure 매핑을 요구(`SKILL.md:27`)하여, 동일 세션에 이미 컨텍스트가 있어도 코드와 요구사항 재확인을 암묵적으로 유발한다. 결과적으로 토큰 중복 소모가 발생하고, 스킬 본문(152줄 + reviewer prompt)이 매 파이프라인 실행마다 로드된다.

## Decision Drivers

* grill-me로 정제된 요구사항을 same-session에서 재탐색하는 토큰 중복 소모 제거
* 외부 스킬 의존성을 최소화하여 파이프라인 이해 가능성(readability) 향상
* writing-plans의 Execution Handoff(subagent vs inline 선택)가 feature-pipeline §S6의 subagent-driven 강제와 충돌하는 문제 제거

## Considered Options

* 옵션 1: 현 상태 유지
* 옵션 2: grill-me 산출물을 spec 파일로 작성하고 writing-plans에 전달
* 옵션 3: writing-plans 호출 제거, §S3가 직접 plan 작성 (Header만 흡수)

## Decision Outcome

Chosen option: "옵션 3: writing-plans 호출 제거, §S3가 직접 plan 작성", because feature-pipeline §S3에는 이미 `[TIDY]`/`[TDD]`/`[TDD-EXEMPT]` 태그, Tidying/Behavioral 섹션 분리, Simplicity First 가드레일이 명문화되어 있어 writing-plans 고유 기여 중 (3)(4)(5)는 중복이다. 순수 고유 기여인 (1) Plan Document Header만 §S3에 흡수하고 (2) File Structure 매핑은 각 task의 `Files:` 필드로 분산 대체한다.

### Consequences

* Good, because 동일 세션 내 코드/요구사항 재탐색이 발생하지 않아 토큰 절약
* Good, because 파이프라인 전체 로직이 `feature-pipeline/SKILL.md` 단일 파일로 집중됨
* Good, because writing-plans Execution Handoff와 §S6 subagent-driven 강제의 충돌이 제거됨
* Bad, because writing-plans 스킬이 향후 업데이트될 때 자동으로 수혜받지 못함
* Bad, because plan 형식 강제 책임이 feature-pipeline §S3로 집중되어 §S3 변경 시 format regression 위험

### Confirmation

`grep -n 'writing-plans' plugins/workflow/skills/feature-pipeline/SKILL.md` 결과가 비어 있고,
생성된 plan 파일이 `**Goal:**` / `**Architecture:**` / `**Tech Stack:**` 헤더를 포함하며,
각 task가 `Files:` 필드를 갖는지 수동 실행으로 확인한다.

## Pros and Cons of the Options

### 옵션 1: 현 상태 유지

* Good, because 변경 없이 writing-plans 업데이트의 자동 수혜 유지
* Bad, because 동일 세션 토큰 중복 소모 지속
* Bad, because Execution Handoff 충돌 미해소

### 옵션 2: spec 파일 핸드오프

* Good, because writing-plans의 형식 검증(self-review) 로직을 계속 활용
* Bad, because spec 파일 작성 단계가 추가되어 토큰 절약 효과가 상쇄
* Bad, because Execution Handoff 충돌은 여전히 미해소

### 옵션 3: writing-plans 제거, §S3 직접 작성 (채택)

* Good, because 재탐색 없이 grill-me 결과를 직접 plan으로 변환
* Good, because 외부 스킬 의존 제거
* Neutral, because Plan Document Header와 Files 필드는 기존 §S3 항목 대비 소규모 추가
* Bad, because writing-plans 업데이트 자동 수혜 없음

## More Information

* 관련 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md), [ADR-0013](0013-integrate-karpathy-guidelines-into-feature-pipeline.md), [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md)
* 적용 규칙: `.claude/rules/workflow-rules.md` `[ADR-0015]` 항목
* writing-plans 스킬 원본: `/root/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/writing-plans/SKILL.md` (수정 대상 아님)

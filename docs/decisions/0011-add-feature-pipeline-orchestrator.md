# feature-pipeline 오케스트레이터 스킬 추가

* Status: accepted
* Date: 2026-05-13
* Decision Makers: ppzxc
* Consulted: Gemini gemini-3.1-pro-preview (cross-check)
* Informed: —

## Context and Problem Statement

`workflow` 플러그인의 `gemini-crosscheck` 스킬은 brainstorm → crosscheck → plan → execute 전 흐름을 다루지만, 요구사항 채굴(grill-me) 단계를 포함하지 않는다. 또한 plan 산출이 대화 내 텍스트로 끝나 단계 간 파일 핸드오프가 없으며, behavioral task에서 TDD 강제력이 약하다. 사용자는 이 흐름을 매번 수동으로 오케스트레이션해야 했다.

## Decision Drivers

* grill-me → plan → crosscheck → execute 전 흐름을 단일 스킬로 묶어 수동 오케스트레이션 비용 제거
* plan 파일(`docs/plans/<slug>.md`)을 중간 산출물로 저장하여 단계 간 명시적 핸드오프
* behavioral task에 TDD를 기본값으로 강제하고 면제는 명시적 사유 요구
* gemini-crosscheck의 이중 실행 문제(Skill 호출 시 Step 5 Execute까지 진행) 방지

## Considered Options

* (a) 단일 통합 스킬 `feature-pipeline` 추가
* (b) `gemini-crosscheck`에 review-only 모드 파라미터 추가
* (c) 사용자가 개별 스킬을 수동 체이닝 (현상 유지)

## Decision Outcome

Chosen option: "(a) 단일 통합 스킬 `feature-pipeline` 추가", because 기존 스킬 인터페이스를 변경하지 않고 오케스트레이션 레이어를 추가할 수 있으며, grill-me 단계까지 포함한 더 넓은 범위를 다룰 수 있다.

옵션 (b)는 gemini-crosscheck SKILL.md를 수정해야 하며 하위 호환성 리스크가 있다. 옵션 (c)는 현재의 수동 오케스트레이션 문제를 해결하지 못한다.

### Consequences

* Good, because 아이디어 한 문장에서 PR까지 단일 호출로 처리 가능
* Good, because plan 파일이 영구 산출물로 Git에 남아 의사결정 추적 가능
* Good, because gemini-crosscheck Skill을 직접 호출하지 않고 inline ask-gemini를 사용하여 이중 실행 충돌 방지
* Bad, because 의존 스킬 체인이 길어짐 — grill-me, superpowers:writing-plans, mcp__gemini-cli__ask-gemini, superpowers:using-git-worktrees, superpowers:subagent-driven-development, superpowers:finishing-a-development-branch
* Bad, because 긴 파이프라인이므로 중간 단계 실패 시 재진입 지점이 필요 (Gate 1/2/3로 처리)

### Confirmation

* `plugins/workflow/skills/feature-pipeline/SKILL.md` 존재 확인
* `plugin.json`, `marketplace.json`, 루트 README의 workflow version이 0.0.9인지 grep
* `.claude/rules/workflow-rules.md`에 4개 규칙 + `[ADR-0011]` 태그 확인

## Pros and Cons of the Options

### (a) 단일 통합 스킬 feature-pipeline

* Good, because 기존 스킬 변경 없음
* Good, because grill-me를 첫 단계로 포함하여 요구사항 채굴 강제화
* Good, because inline crosscheck로 이중 실행 문제 회피
* Bad, because 의존 스킬 체인이 길어 단계 중 하나라도 실패 시 영향 범위 넓음

### (b) gemini-crosscheck review-only 모드 추가

* Good, because 기존 gemini-crosscheck를 재사용 가능
* Neutral, because SKILL.md에 mode 분기 추가 필요
* Bad, because 기존 사용자의 gemini-crosscheck 동작에 영향 가능성
* Bad, because grill-me 단계 포함 불가

### (c) 수동 체이닝 유지

* Good, because 변경 없음
* Bad, because 수동 오케스트레이션 비용 지속
* Bad, because TDD 강제력 없음

## More Information

* [`plugins/workflow/skills/feature-pipeline/SKILL.md`](../plugins/workflow/skills/feature-pipeline/SKILL.md) — 스킬 구현
* [`.claude/rules/workflow-rules.md`](../../.claude/rules/workflow-rules.md) — 파생 규칙
* Gemini cross-check 피드백: 이중 실행 충돌([risk H]), worktree 경로 불일치([ordering M]), LLM 단계 망각([feasibility M]) — 모두 SKILL.md에서 대응

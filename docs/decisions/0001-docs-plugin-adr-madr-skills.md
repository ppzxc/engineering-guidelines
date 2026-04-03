---
status: accepted
date: 2026-03-30
decision-makers: ppzxc
---

# Adopt ADR and MADR Skills for docs Plugin

## Context and Problem Statement

아키텍처 의사결정을 공식 문서로 기록하는 표준 방법이 없어, 결정 사항이 브레인스토밍 스펙이나 대화 컨텍스트에만 남고 추적이 어렵다. ADR(Architecture Decision Records)과 MADR(Markdown Architectural Decision Records)은 이 문제를 해결하는 업계 표준 포맷이다. 이를 Claude Code 플러그인 스킬로 통합하면 스펙 작성 → 구현 계획 → 공식 결정 기록의 워크플로우가 완성된다.

## Decision Drivers

* 결정 사항의 추적 가능성 — 왜 그 결정을 내렸는지 나중에도 알 수 있어야 한다
* 기존 플러그인 패턴과의 일관성 — `api`, `git` 플러그인 구조를 따라야 한다
* 다른 스킬과의 연계 — brainstorming 스펙 완료 후 공식 ADR/MADR로 자연스럽게 이어져야 한다
* Claude AI 친화적 포맷 — Claude가 컨텍스트를 잘 이해하고 초안을 잘 작성할 수 있어야 한다

## Considered Options

* Option A: 완전 독립형 스킬 2개 (`docs:adr`, `docs:madr` 각각)
* Option B: 공유 워크플로우 + 포맷 분리 (base 스킬 + 포맷 스킨)
* Option C: MADR이 ADR을 확장하는 상속 구조

## Decision Outcome

Chosen option: **Option A (완전 독립형 스킬 2개)**, because 현재 플러그인 시스템이 SKILL.md 단일 파일 기반으로 스킬 간 참조를 지원하지 않으며, ADR과 MADR은 포맷 철학이 달라 독립적으로 관리하는 것이 더 자연스럽기 때문이다.

### Consequences

* Good, because 각 스킬이 독립적으로 발전 가능
* Good, because 기존 `git:commit` 패턴과 동일한 구조로 일관성 유지
* Good, because 한 스킬의 변경이 다른 스킬에 영향을 주지 않음
* Bad, because 워크플로우 로직 일부 중복 (번호 채번, 사용자 확인 절차)

### Confirmation

`plugins/docs/skills/adr/SKILL.md`와 `plugins/docs/skills/madr/SKILL.md`가 각각 독립적으로 동작하며, 두 스킬 모두 `docs/decisions/` 경로에 올바른 형식의 ADR/MADR을 생성하는지 수동 검증한다.

## Pros and Cons of the Options

### Option A: 완전 독립형 스킬 2개

* Good, because 단순하고 자명한 구조
* Good, because 기존 플러그인 패턴과 완벽히 일치
* Good, because 독립적 진화 가능
* Bad, because 공통 워크플로우 로직 중복

### Option B: 공유 워크플로우 + 포맷 분리

* Good, because DRY — 공통 로직 중복 없음
* Bad, because 현재 플러그인 시스템이 스킬 간 참조를 지원하지 않음
* Bad, because 구조 복잡도 증가

### Option C: MADR이 ADR을 확장

* Bad, because 스킬 간 결합도 증가
* Bad, because MADR을 독립 호출할 수 없음

## More Information

* [docs:adr 스킬](../../plugins/docs/skills/adr/SKILL.md)
* [docs:madr 스킬](../../plugins/docs/skills/madr/SKILL.md)
* [PR #27](https://github.com/ppzxc/engineering-guidelines/pull/27) — 이 결정을 구현한 PR

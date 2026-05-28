# Matt Pocock 스킬 컨벤션 채택 — ADR 경로 이동, Triage 라벨, Agent Skills 블록, CONTEXT.md 도입

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc

## Context and Problem Statement

본 저장소는 `docs/adr/` (MADR 4.0), `.claude/rules/`, `docs/context/{TASK}/` 등 자체 패턴으로 컨텍스트를 유지해 왔다. `to-issues`, `triage`, `improve-codebase-architecture` 등 matt pocock 엔지니어링 스킬 생태계는 `CONTEXT.md`, `docs/adr/`, `docs/agents/*.md`, canonical triage label 5종을 전제한다. 두 컨벤션이 달라 matt pocock 스킬이 본 저장소를 올바르게 인식하지 못한다.

## Decision Drivers

* matt pocock 스킬 생태계 호환성 확보
* 도메인 용어 단일 소스 명시 (`CONTEXT.md`)
* 이슈 triage 워크플로우 표준화

## Considered Options

* `docs/adr/`로 이동 (matt pocock 기본값 채택)
* `docs/adr/` 유지 + `docs/agents/domain.md`에 경로 오버라이드 명시
* 양쪽 경로 심볼릭 링크로 공존

## Decision Outcome

Chosen option: "`docs/adr/`로 이동", because matt pocock 스킬이 경로 오버라이드를 지원하지 않으므로 기본값을 따르는 것이 유지보수 부담이 가장 적다.

### Consequences

* Good, because `improve-codebase-architecture`, `diagnose` 스킬이 ADR을 자동 인식
* Good, because `CONTEXT.md` 단일 파일로 도메인 어휘 명시적 관리
* Good, because triage label 5종으로 이슈 상태 기계 표준화
* Bad, because `docs/adr` → `docs/adr` 경로 치환으로 31개 파일 수정 필요
* Bad, because 외부 링크(블로그/이슈 등)가 있다면 깨질 가능성 — 본 저장소는 외부 참조 미미

### Confirmation

```bash
# docs/adr 참조 0개 (superpowers history 제외)
rg "docs/adr" --type md \
  --glob '!docs/superpowers/**'

# 5개 triage 라벨 존재
gh label list --repo ppzxc/engineering-guidelines \
  | grep -E "needs-triage|needs-info|ready-for-human|ready|wontfix"

# docs/agents/ 3파일 존재
ls docs/agents/

# CONTEXT.md 루트에 존재
ls CONTEXT.md
```

## Pros and Cons of the Options

### `docs/adr/`로 이동

* Good, because 스킬 기본값 일치 → 경로 오버라이드 설정 불필요
* Good, because `git mv` 사용 시 history 추적 가능
* Bad, because 38개 ADR 및 참조 파일 31개 경로 치환 작업 필요

### `docs/adr/` 유지 + `docs/agents/domain.md` 오버라이드

* Good, because 기존 ADR 경로 변경 없음
* Neutral, because `domain.md`에 경로 명시 가능
* Bad, because matt pocock 스킬이 `domain.md` 오버라이드를 실제로 지원하는지 불명확 — 미래 스킬 업데이트 시 깨질 위험

### 심볼릭 링크 공존

* Good, because 하위 호환성 완전 유지
* Bad, because 복잡성 증가, git 관리 어려움, CI 환경 링크 인식 불안정

## More Information

- 영향 파일: `.claude/rules/rules-maintenance.md`, `AGENTS.md`, `plugins/docs/skills/adr/SKILL.md`, `plugins/docs/skills/madr/SKILL.md`, `plugins/context/README.md`, `plugins/docs/README.md` 등
- 관련 정본 규칙: `AGENTS.md` (정본 규칙 소스 섹션 확장)

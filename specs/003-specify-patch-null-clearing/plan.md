# Implementation Plan: specify null-clearing behavior in PATCH updateMask

**Branch**: `003-specify-patch-null-clearing` | **Date**: 2026-06-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-specify-patch-null-clearing/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

JSON 필드 생략(Omit null) 원칙 준수 과정에서 발생하는 PATCH 메서드의 데이터 초기화(Clearing/Nulling) 모순을 해결하기 위해, 구글 AIP-134 표준(Update Methods) 스펙을 적용하여 `updateMask`를 활용한 명시적/묵시적 null 초기화의 동작 방식을 수립합니다. 이를 위해 점(.) 표기법(dot notation)을 통한 중첩 필드 제어를 허용하고, 잘못된 경로가 들어올 시 `400 Bad Request` 에러를 응답하는 아키텍처 규칙을 [SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)에 구체화합니다.

## Technical Context

**Language/Version**: Markdown, JSON, Git

**Primary Dependencies**: None

**Storage**: Files

**Testing**: Markdown verification & test-cases mapping

**Target Platform**: Claude Code / Antigravity CLI

**Project Type**: documentation/guidelines

**Performance Goals**: N/A

**Constraints**: Constitution v3.3.0

**Scale/Scope**: 1 plugin skill (`plugins/guideline/skills/restful-api/SKILL.md`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Plugin-First)**: PASS. 모든 가이드라인 설계는 `plugins/guideline/` 하위 모듈의 스킬 스펙에 독립적으로 격리되어 작성됩니다.
- **Principle II (Verification-First)**: PASS. 스킬 문서 개정 전 `docs/evaluation/test-cases.md` (혹은 플러그인 평가 문서)에 검증 케이스를 명시하여 변경 사항이 검증 가능한 상태인지 확인합니다.
- **Principle III (Git & Version Sync)**: PASS. 스킬 가이드 수정에 맞춰 `guideline` 플러그인의 버전을 `0.5.1`로 bump하며, `marketplace.json`, `README.md`, `plugin.json` 세 곳의 버전을 동시에 동기화 업데이트합니다.

## Project Structure

### Documentation (this feature)

```text
specs/003-specify-patch-null-clearing/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
plugins/guideline/
├── plugin.json
├── README.md
├── README.ko.md
└── skills/
    └── restful-api/
        └── SKILL.md
```

**Structure Decision**: Single project (guideline plugin modification).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |

# Implementation Plan: feat: modernize distributed tracing headers to W3C traceparent

**Branch**: `005-modernize-tracing-headers` | **Date**: 2026-06-09 | **Spec**: [spec.md](file:///home/ppzxc/projects/engineering-guidelines/specs/005-modernize-tracing-headers/spec.md)

**Input**: Feature specification from `/specs/005-modernize-tracing-headers/spec.md`

## Summary

분산 마이크로서비스 환경에서 OpenTelemetry 및 다양한 모니터링 표준 솔루션과의 상호운용성을 극대화하기 위해, 기존의 커스텀 `Request-Id` 헤더 방식에서 W3C Trace Context 규격(`traceparent` 및 `tracestate`)으로의 현대화를 추진합니다. 레거시 시스템 과도기 대응을 위한 기존 `Request-Id` 하위 호환성 유지, 유효하지 않은 헤더 수신 시의 폴백(Restart Trace + Warning Log), 최초 진입점(Gateway 등)에서의 헤더 발급 책임을 가이드라인과 규칙으로 제정합니다.

## Technical Context

**Language/Version**: Markdown (Guidelines & Rules)

**Primary Dependencies**: W3C Trace Context Specification (W3C Recommendation 23 November 2021)

**Storage**: N/A (Repository File System)

**Testing**: Markdown verification via validation tests in `docs/evaluation/test-cases.md`

**Target Platform**: Claude Code Agent Rules, API Linting Environments

**Project Type**: library/docs (Rules & Guideline)

**Performance Goals**: N/A

**Constraints**: N/A

**Scale/Scope**: 
- 수정 파일: `plugins/guideline/skills/restful-api/SKILL.md` (Headers 섹션)
- 신규 작성 파일: `.claude/rules/api-rules.md` (보안 및 인프라 헤더 규칙 정의)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Rule | Compliance Status | Rationale / Verification |
|---|---|---|
| **I. Plugin-First & Modular Skill Design** | **Compliant** | 가이드라인 수정은 `plugins/guideline/` 디렉토리 내의 `restful-api/SKILL.md` 구조에 국한되어 이루어집니다. |
| **II. Verification-First & Test-First (TDD)** | **Compliant** | 본격적인 규칙 문서 수정 전에 `docs/evaluation/test-cases.md`에 명확화된 규칙을 검증할 수 있는 테스트 케이스를 우선 추가하여 검증합니다. |
| **III. Git Workflow & Version Sync** | **Compliant** | 가이드라인 플러그인(`plugins/guideline`)의 변경을 반영하며, PR은 한글로 작성하고, 필요한 경우 버전 정보(`plugin.json`, `marketplace.json`, `README.md`)를 동기화합니다. |

*Gate Evaluation: PASS (All core rules are satisfied, no complexity tracking required).*

## Project Structure

### Documentation (this feature)

```text
specs/005-modernize-tracing-headers/
├── plan.md              # This file
├── research.md          # Phase 0: W3C Trace Context specification and migration strategy
├── data-model.md        # Phase 1: Header entity data format and field specifications
├── quickstart.md        # Phase 1: End-to-end validation run/test scenarios
└── contracts/           # Phase 1: Header schemas
    └── trace-headers.json
```

### Source Code (repository root)

```text
.claude/
└── rules/
    └── api-rules.md     # New API security and infra rules (FR-002)

plugins/
└── guideline/
    └── skills/
        └── restful-api/
            └── SKILL.md # Updated restful-api Guideline Headers section (FR-001)
```

**Structure Decision**: 기존 `plugins/guideline` 하위의 RESTful API 가이드라인을 수정하고, 전체 에이전트 규칙 적용을 위해 `.claude/rules/api-rules.md`에 관련 아키텍처 규칙을 수록합니다.

## Complexity Tracking

> **Complexity Tracking is not required as there are no Constitution Check violations.**

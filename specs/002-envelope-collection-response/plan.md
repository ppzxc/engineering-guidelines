# Implementation Plan: feat: adopt envelope pattern for API collection responses

**Branch**: `002-envelope-collection-response` | **Date**: 2026-06-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-envelope-collection-response/spec.md`

## Summary

이 계획은 기존 API 가이드라인의 최상위 JSON Array 강제 규정을 완화하고, IANA 표준이자 HATEOAS 원칙을 따르는 JSON HAL (`application/hal+json`) 포맷을 공식 표준으로 수용하여 컬렉션 데이터의 확장성과 보안성을 극대화하도록 관련 가이드를 수정하는 작업입니다.

## Technical Context

**Language/Version**: Markdown (GUIDELINE / DOCUMENTATION)

**Primary Dependencies**: RESTful API Guidelines, IANA JSON HAL (draft-kelly-json-hal-11)

**Storage**: N/A

**Testing**: Markdown manual verification and evaluation test case validation

**Target Platform**: AI Agent Environment (Claude, Gemini, etc.)

**Project Type**: documentation/guidelines

**Performance Goals**: N/A

**Constraints**: Compliance with draft-kelly-json-hal-11, compatibility with custom pagination metadata

**Scale/Scope**: 1 guideline skill file to update, version updates in 3 files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I (Plugin-First & Modular Skill Design)**: PASS. `restful-api` 스킬은 `plugins/guideline/skills/restful-api/SKILL.md` 내에 독립적이고 모듈식으로 잘 관리되고 있으며, 본 작업도 이 구조 내에서 수행됨.
- **Principle II (Verification-First & Test-First)**: PASS. 스킬 파일 수정 전에 `docs/evaluation/test-cases.md`에 JSON HAL 검증 관련 평가 테스트 케이스를 우선 생성하여 검증을 시작함.
- **Principle III (Git Workflow & Version Synchronization)**: PASS. 한국어 PR 컨벤션을 준수하고, 플러그인 업데이트 시 `plugins/guideline/plugin.json`, `README.md`, `.claude-plugin/marketplace.json` 세 곳의 버전을 동시에 `0.4.0`으로 업데이트하여 동기화함.

## Project Structure

### Documentation (this feature)

```text
specs/002-envelope-collection-response/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (N/A for doc feature)
├── quickstart.md        # Phase 1 output (Verification guide)
└── checklists/
    └── requirements.md  # Specification Quality Checklist
```

### Source Code (repository root)

```text
plugins/
└── guideline/
    ├── plugin.json
    └── skills/
        └── restful-api/
            └── SKILL.md

docs/
└── evaluation/
    └── test-cases.md
```

**Structure Decision**: 기존 플러그인 폴더 구조 및 docs 내부의 evaluation 폴더 구조를 그대로 유지함.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*(No violations detected. Standard TDD for skills and version synchronization will be followed.)*

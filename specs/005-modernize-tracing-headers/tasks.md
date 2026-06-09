# Tasks: feat: modernize distributed tracing headers to W3C traceparent

**Input**: Design documents from `/specs/005-modernize-tracing-headers/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: 헌법(Constitution)의 Verification-First (TDD) 원칙에 따라, 가이드라인 및 규칙 수정 전 `docs/evaluation/test-cases.md`에 평가 테스트 케이스를 선제적으로 작성하여 검증을 수행합니다.

**Organization**: 모든 태스크는 사용자 스토리(User Story)별로 그룹화되어 독립적인 구현과 테스트가 가능하도록 구성되어 있습니다.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 병렬 실행 가능 (서로 다른 파일 수정, 상호 의존성 없음)
- **[Story]**: 해당 태스크가 속한 사용자 스토리 식별자 (예: US1)
- 모든 태스크는 상세 파일 경로를 명시합니다.

## Path Conventions

- **Rules**: `.claude/rules/api-rules.md`
- **Guidelines**: `plugins/guideline/skills/restful-api/SKILL.md`
- **Evaluation Tests**: `docs/evaluation/test-cases.md`
- **Validation Guide**: `specs/005-modernize-tracing-headers/quickstart.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: 프로젝트 초기화 및 규칙/가이드라인 파일 뼈대 생성

- [ ] T001 Verify folders and verify target paths in specs/005-modernize-tracing-headers/spec.md
- [ ] T002 Initialize empty api-rules file at .claude/rules/api-rules.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 본격적인 규칙 설계 및 작성 전에 수행해야 하는 헌법(Constitution) 정합성 점검 및 구조 준비

- [ ] T003 Verify formatting tools and constitution constraints in .specify/memory/constitution.md

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - W3C Trace Context 도입 및 Request-Id 하위 호환성 전파 (Priority: P1) 🎯 MVP

**Goal**: W3C Trace Context 표준 전파 규격, 레거시 `Request-Id` 하위 호환성(Dual Propagation), 오류 폴백(Restart Trace + Warning Log), API Gateway 최초 발급 책임을 규칙 문서에 정의하고 TDD 검증을 통과한다.

**Independent Test**: `docs/evaluation/test-cases.md` 에 신규 트레이스 표준 케이스를 추가하고, 작성한 가이드라인 문서가 평가 테스트를 성공적으로 통과하는지 검증합니다.

### Tests for User Story 1 (TDD - Mandatory)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T004 [P] [US1] Add evaluation test cases for W3C distributed tracing and Request-Id backward compatibility to docs/evaluation/test-cases.md

### Implementation for User Story 1

- [ ] T005 [P] [US1] Implement distributed logging and tracing security rules in .claude/rules/api-rules.md
- [ ] T006 [US1] Update Headers section and tracing guidelines in plugins/guideline/skills/restful-api/SKILL.md
- [ ] T007 [US1] Run validation check on docs/evaluation/test-cases.md to pass TDD cycle

**Checkpoint**: User Story 1 should be fully functional and testable independently.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: 여러 영역에 걸친 마무리 다듬기 및 가이드라인 정밀 최종 검증

- [ ] T008 [P] Execute verification scenarios defined in specs/005-modernize-tracing-headers/quickstart.md
- [ ] T009 Verify plugin version consistency and update readme at README.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 즉시 시작 가능.
- **Foundational (Phase 2)**: Setup 완료 후 수행.
- **User Story 1 (Phase 3)**: Foundational 완료 후 수행.
- **Polish (Phase 4)**: User Story 1 완료 후 수행.

### Within Each User Story

- TDD에 따라 테스트(`T004`)를 구현(`T005`, `T006`)보다 먼저 작성하여 실패를 확인해야 합니다.
- 스킬 가이드라인(`T006`)과 에이전트 규칙(`T005`)은 상호 연동되어 검증(`T007`)이 이루어져야 합니다.

### Parallel Opportunities

- `T004`(테스트 작성)와 `T005`(규칙 초안)는 상호 다른 파일이므로 병렬로 작성을 준비할 수 있습니다.
- `T008`(최종 시나리오 검증)과 `T009`(버전 동기화)는 병렬 실행 가능합니다.

---

## Parallel Example: User Story 1

```bash
# Launch test and rules tasks in parallel:
Task: "Add evaluation test cases for W3C distributed tracing and Request-Id backward compatibility to docs/evaluation/test-cases.md"
Task: "Implement distributed logging and tracing security rules in .claude/rules/api-rules.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. **Phase 1 & 2** 완료를 통한 인프라 뼈대 확립.
2. **Phase 3 (User Story 1)** TDD 검증 완료.
3. **STOP and VALIDATE**: `quickstart.md` 시나리오를 통해 독립 테스트 및 평가 통과 확인.

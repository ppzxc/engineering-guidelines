# Tasks: specify null-clearing behavior in PATCH updateMask

**Input**: Design documents from `/specs/003-specify-patch-null-clearing/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Included as required by the project constitution (TDD for Skills).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `plugins/guideline/` at repository root
- Paths shown below assume guideline plugin structure

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the evaluation framework for the guideline plugin to support TDD check gates

- [x] T001 Create docs evaluation directory for guideline plugin at `plugins/guideline/docs/evaluation/`
- [x] T002 Initialize evaluation files at `plugins/guideline/docs/evaluation/test-cases.md`, `plugins/guideline/docs/evaluation/coverage-map.md`, and `plugins/guideline/docs/evaluation/report.md`

---

## Phase 2: User Story 1 - Specify PATCH Null-Clearing (Priority: P1) 🎯 MVP

**Goal**: Document RESTful API PATCH null-clearing standards (AIP-134, dot notation, invalid paths) in SKILL.md and verify via evaluation cases.

**Independent Test**: Run verification steps described in `quickstart.md` and check that the evaluation report marks all cases as PASS.

### Tests for User Story 1 (TDD)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T003 [P] [US1] Write failing test cases in `plugins/guideline/docs/evaluation/test-cases.md` for implicit clearing, dot notation, and invalid paths
- [x] T004 [P] [US1] Set initial status to FAILED in `plugins/guideline/docs/evaluation/coverage-map.md` and `plugins/guideline/docs/evaluation/report.md`

### Implementation for User Story 1

- [x] T005 [US1] Document explicit & implicit null-clearing rules under PATCH section in `plugins/guideline/skills/restful-api/SKILL.md`
- [x] T006 [US1] Document dot notation support for nested objects under PATCH section in `plugins/guideline/skills/restful-api/SKILL.md`
- [x] T007 [US1] Document 400 Bad Request error behavior for invalid mask paths in `plugins/guideline/skills/restful-api/SKILL.md`
- [x] T008 [US1] Update evaluation status to COVERED/PASS in `plugins/guideline/docs/evaluation/coverage-map.md` and `plugins/guideline/docs/evaluation/report.md`

**Checkpoint**: At this point, PATCH updateMask null-clearing behavior is fully documented and passes the evaluation checks.

---

## Phase 3: Polish & Cross-Cutting Concerns

**Purpose**: Metadata synchronization and final validation

- [x] T009 [P] Bump versions to 0.5.1 in `plugins/guideline/plugin.json`, `README.md`, `README.ko.md`, and `.claude-plugin/marketplace.json` to synchronize versions
- [x] T010 Run final validation per `specs/003-specify-patch-null-clearing/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **User Story 1 (Phase 2)**: Depends on Setup (Phase 1) completion
- **Polish (Phase 3)**: Depends on User Story 1 (Phase 2) completion

### Parallel Opportunities

- T003 and T004 can run in parallel (defining test cases and initializing map status)
- T009 version bumping can be prepared in parallel with other polish tasks

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: User Story 1 (including TDD failing tests first)
3. Complete Phase 3: Polish
4. Validate execution against `quickstart.md`

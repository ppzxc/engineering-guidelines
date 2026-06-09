# Tasks: feat: adopt envelope pattern for API collection responses

**Input**: Design documents from `/specs/002-envelope-collection-response/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Verify active branch is `002-envelope-collection-response` and git workspace is clean

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [x] T002 Create test case for JSON HAL collection response formatting in [docs/evaluation/test-cases.md](file:///home/ppzxc/projects/engineering-guidelines/docs/evaluation/test-cases.md)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - JSON HAL 포맷 기반 컬렉션 데이터 조회 (Priority: P1) 🎯 MVP

**Goal**: IANA 표준인 JSON HAL (`application/hal+json`) 포맷을 기반으로 하는 컬렉션 응답 가이드라인 추가 및 Array 제한 완화

**Independent Test**: `docs/evaluation/test-cases.md` 내의 평가 테스트 패스 및 가이드라인 정합성 수동 검증

### Implementation for User Story 1

- [x] T003 [US1] Update Collections & Pagination section in [plugins/guideline/skills/restful-api/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md) to relax the Top-level JSON Array constraint and establish JSON HAL as standard
- [x] T004 [US1] Define JSON HAL `_links` and `_embedded` standard response structures in [plugins/guideline/skills/restful-api/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)
- [x] T005 [US1] Document rules for extending JSON HAL collection responses with custom metadata in [plugins/guideline/skills/restful-api/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/skills/restful-api/SKILL.md)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: Version Synchronization

**Purpose**: Update plugin version and marketplace registry to `0.4.0`

- [x] T006 [P] Update version to `0.4.0` in [plugins/guideline/plugin.json](file:///home/ppzxc/projects/engineering-guidelines/plugins/guideline/plugin.json)
- [x] T007 [P] Update version of `guideline` plugin to `v0.4.0` in the root [README.md](file:///home/ppzxc/projects/engineering-guidelines/README.md)
- [x] T008 [P] Update version of `guideline` plugin to `0.4.0` and marketplace version in [.claude-plugin/marketplace.json](file:///home/ppzxc/projects/engineering-guidelines/.claude-plugin/marketplace.json)

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T009 [P] Run the agent context update script `bash .specify/extensions/agent-context/scripts/bash/update-agent-context.sh`
- [x] T010 Verify the test case in [docs/evaluation/test-cases.md](file:///home/ppzxc/projects/engineering-guidelines/docs/evaluation/test-cases.md) now passes
- [x] T011 Run validation guide in [specs/002-envelope-collection-response/quickstart.md](file:///home/ppzxc/projects/engineering-guidelines/specs/002-envelope-collection-response/quickstart.md) and verify all checks pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Stories (Phase 3)**: Depends on Foundational phase completion
- **Version Synchronization (Phase 4)**: Depends on User Stories completion
- **Polish (Phase 5)**: Depends on Version Synchronization completion

### Parallel Opportunities

- All version synchronization tasks marked [P] (T006, T007, T008) can run in parallel.
- All Polish tasks marked [P] can run in parallel once T010 is ready.

---

## Parallel Example: User Story 1

```bash
# Since the implementation changes are primarily in SKILL.md, tasks T003, T004, and T005 should be completed sequentially to avoid merge conflicts.
# However, version synchronization tasks (T006, T007, T008) can be run concurrently:
Task: "Update version in plugins/guideline/plugin.json"
Task: "Update version in README.md"
Task: "Update version in .claude-plugin/marketplace.json"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (Create test cases)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Verify test case passes and guidelines are correct
5. Complete Phase 4: Version Synchronization
6. Complete Phase 5: Polish & Verification

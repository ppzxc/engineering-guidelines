# Tasks: Peer Orchestrator Integration

**Input**: Design documents from `/specs/006-peer-orchestrator-integration/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test-driven development (TDD) for skills requires defining failing evaluation test cases in `docs/evaluation/test-cases.md` before guidelines modification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Plugins layout**: `plugins/llm/skills/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure checking

- [x] T001 Verify existing plugin directories and configuration in plugins/llm/plugin.json
- [x] T002 Configure local environment settings in .specify/feature.json

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Initialize target evaluation file structure in docs/evaluation/test-cases.md
- [x] T004 Define empty placeholder orchestrator skill directory at plugins/llm/skills/peer-orchestrator/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Multi-LLM Peer Orchestrated Review (Priority: P1) 🎯 MVP

**Goal**: Centralized multi-agent orchestration for code reviews with sandbox warm-up.

**Independent Test**: Verify that running `/llm:peer-orchestrator` spawns both Self and Peer subagents and checks version commands first.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T005 [P] [US1] Create failing test case for sandbox warm-up and subagent execution in docs/evaluation/test-cases.md

### Implementation for User Story 1

- [x] T006 [US1] Create the core orchestrator skill skeleton in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T007 [US1] Implement sandbox warm-up version checks (`timeout 3 <cli> --version`) in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T008 [US1] Dispatch Self-Review and Peer-Review coordinator subagents concurrently in plugins/llm/skills/peer-orchestrator/SKILL.md

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Sentinel Fallback Handling (Priority: P2)

**Goal**: Graceful fallback logic transition to next peer CLI on sentinel error.

**Independent Test**: Simulate a missing CLI and verify fallback transitions to the next prioritized peer CLI.

### Tests for User Story 2

- [x] T009 [P] [US2] Create failing test case for sentinel fallback logic in docs/evaluation/test-cases.md

### Implementation for User Story 2

- [x] T010 [US2] Implement sentinel parsing (`CLI_NOT_FOUND`, `CLI_TIMEOUT`, `CLI_ERROR`) in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T011 [US2] Implement fallback loop logic to transition to the next prioritized peer CLI in plugins/llm/skills/peer-orchestrator/SKILL.md

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Severity-Gated Hybrid Findings Merge (Priority: P2)

**Goal**: Severity-gated Union/Intersection merge logic.

**Independent Test**: Input mock findings and verify High is unioned, Medium/Low is intersected.

### Tests for User Story 3

- [x] T012 [P] [US3] Create failing test case for severity-gated merging in docs/evaluation/test-cases.md

### Implementation for User Story 3

- [x] T013 [US3] Implement findings parser and classification by severity in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T014 [US3] Implement Union logic for High/Critical findings in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T015 [US3] Implement Intersection logic for Medium/Low findings in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T016 [US3] Implement markdown report generator in plugins/llm/skills/peer-orchestrator/SKILL.md

**Checkpoint**: All user stories 1, 2, and 3 should now be independently functional

---

## Phase 6: User Story 4 - Legacy llm:auto Delegation & Local Exclusion (Priority: P3)

**Goal**: Exclude active host CLI and delegate `llm:auto` to `peer-orchestrator`.

**Independent Test**: Run `/llm:auto` and verify host CLI is excluded and orchestrator completes review.

### Tests for User Story 4

- [x] T017 [P] [US4] Create failing test case for host exclusion and auto delegation in docs/evaluation/test-cases.md

### Implementation for User Story 4

- [x] T018 [US4] Implement dynamic host CLI (LOCAL) detection and exclusion in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T019 [US4] Refactor plugins/llm/skills/auto/SKILL.md to remove local orchestration and delegate all work to llm:peer-orchestrator

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T020 [P] Implement subagent polling timeout protection (maximum 5 minutes) in plugins/llm/skills/peer-orchestrator/SKILL.md
- [x] T021 [P] Update documentation in README.md and plugins/llm/README.md
- [x] T022 Run quickstart.md validation scenarios end-to-end to verify everything works

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 (Phase 3) skeleton and subagent execution structure
- **User Story 3 (P3)**: Depends on US2 (Phase 4) fallback parser
- **User Story 4 (P4)**: Depends on US3 (Phase 5) merge logic completion

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- All test tasks marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members once the foundational structure is set

---

## Parallel Example: User Story 1

```bash
# Launch all test setups for User Story 1 together:
Task: "Create failing test case for sandbox warm-up and subagent execution in docs/evaluation/test-cases.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

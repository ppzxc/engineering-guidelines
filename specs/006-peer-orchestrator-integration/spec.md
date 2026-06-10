# Feature Specification: Peer Orchestrator Integration

**Feature Branch**: `006-peer-orchestrator-integration`

**Created**: 2026-06-10

**Status**: Draft

**Input**: User description: "Create peer orchestrator and refactor llm auto skill (Issues #131, #132, #133, #134)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-LLM Peer Orchestrated Review (Priority: P1)

Users can perform a comprehensive code review by running a single command, which orchestrates multiple LLM reviewers in parallel, performs fallback error handling, and combines the results.

**Why this priority**: Core value of the feature, providing unified multi-agent orchestration for code reviews.

**Independent Test**: Can be tested by executing the orchestrator command and verifying that both Self and Peer subagents are triggered and their reports are generated and merged.

**Acceptance Scenarios**:

1. **Given** the repository has sandbox approvals configured, **When** `/llm:peer-orchestrator` is executed, **Then** Self-Review and Peer-Review subagents are spawned concurrently.
2. **Given** subagents are executing, **When** the orchestrator starts, **Then** it verifies peer CLIs via version checks to proactively warm up sandbox approvals and prevent locks.

---

### User Story 2 - Sentinel Fallback Handling (Priority: P2)

When a specific LLM CLI fails due to being missing, timing out, or throwing an error, the system automatically falls back to the next designated CLI in the fallback chain to complete the review.

**Why this priority**: High resilience and service continuity under dependency failure conditions.

**Independent Test**: Can be tested by simulating a missing CLI (returning `CLI_NOT_FOUND`) and verifying the fallback chain transitions to the next prioritized peer CLI.

**Acceptance Scenarios**:

1. **Given** the primary peer CLI returns a `CLI_NOT_FOUND` sentinel signal, **When** the orchestrator parses the output, **Then** it seamlessly executes the next peer CLI in the fallback priority queue.

---

### User Story 3 - Severity-Gated Hybrid Findings Merge (Priority: P2)

The system merges findings from Self and Peer reviewers using a hybrid strategy: High/Critical findings are merged using a Union logic (show all), while Medium/Low findings are merged using an Intersection logic (show only duplicate findings) to reduce review noise.

**Why this priority**: Optimizes developer experience by highlighting critical defects while filtering out minor, low-confidence noise.

**Independent Test**: Can be tested by feeding mock findings with different severities and verifying that only matching Medium/Low findings and all High/Critical findings are present in the final output.

**Acceptance Scenarios**:

1. **Given** Self finding A (High) and B (Low), and Peer finding C (High) and B (Low), **When** findings are merged, **Then** the merged findings contain A (High), C (High), and B (Low).

---

### Edge Cases

- **All Peers Fail**: If every peer CLI in the fallback chain fails or is missing, the system must abort gracefully, showing a clear error message instead of hanging or crashing.
- **Subagent Deadlocks**: If one subagent gets stuck, the polling loop must eventually time out after 5 minutes to avoid infinite CPU consumption or process hangs.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The peer orchestrator skill MUST be defined under `plugins/llm/skills/peer-orchestrator/SKILL.md`.
- **FR-002**: The orchestrator MUST run `timeout 3 <cli> --version` on all peer CLIs in the fallback chain during startup to warm up sandbox execution approvals.
- **FR-003**: The orchestrator MUST dispatch Self-Review and Peer-Review coordinator subagents concurrently using the `invoke_subagent` tool.
- **FR-004**: The orchestrator MUST run a 30-second schedule-based polling loop, checking subagent statuses using `manage_subagents list` to avoid deadlocks.
- **FR-005**: The system MUST support a priority-ordered fallback chain with the default sequence: `claude` ➡️ `agy` ➡️ `openai`.
- **FR-006**: The system MUST parse sentinel outputs (`CLI_NOT_FOUND`, `CLI_TIMEOUT`, `CLI_ERROR`) to trigger transition to the next peer CLI.
- **FR-007**: The findings merge engine MUST apply Union logic for High and Critical severity findings.
- **FR-008**: The findings merge engine MUST apply Intersection logic for Medium and Low severity findings.
- **FR-009**: The orchestrator polling loop MUST terminate after a maximum timeout of 5 minutes (300 seconds).
- **FR-010**: `plugins/llm/skills/auto/SKILL.md` MUST be refactored to delegate all work to the new `llm:peer-orchestrator` skill, removing local orchestration logic.
- **FR-011**: The system MUST detect the currently running host CLI (LOCAL) and automatically exclude it from the fallback chain list to avoid duplicate or redundant reviews.

### Key Entities

- **Finding**: A discrete review comment containing file path, line number, severity (Critical, High, Medium, Low), and description.
- **Sentinel**: A signal representing CLI failure states (`CLI_NOT_FOUND`, `CLI_TIMEOUT`, `CLI_ERROR`).
- **FallbackChain**: An ordered queue of Peer LLM CLIs utilized for recovery.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The orchestrator successfully warm-ups and completes parallel execution within 3 minutes under normal network and LLM response times.
- **SC-002**: 100% of simulated CLI failures (missing, timeout, error) trigger fallback behavior to the next peer CLI without raising unhandled shell exceptions.
- **SC-003**: Merging findings filters out 100% of non-overlapping Medium/Low noise findings while preserving 100% of all High/Critical findings.
- **SC-004**: Refactoring `llm:auto` results in zero functional regressions when calling `/llm:auto`.

## Assumptions

- **A-001**: The environment has `gh` and Git configured correctly, and the terminal sandbox allows interactive command executions.
- **A-002**: The `manage_subagents list` command correctly returns the state of background-invoked subagents.
- **A-003**: If a subagent completes, its output artifacts (findings) are written to a designated temp/artifacts folder.

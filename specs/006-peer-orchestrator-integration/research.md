# Research Notes: Peer Orchestrator Design Decisions

This document captures the research and architectural design decisions made during the planning phase of the Multi-LLM Peer Orchestrator.

---

## Decision 1: Sandbox Approval Warm-Up Method

* **Decision**: Prior to launching subagents, the main process runs `timeout 3 <cli> --version` synchronously for all peer CLIs in the fallback chain.
* **Rationale**: Background subagents spawned via `invoke_subagent` run asynchronously. If they trigger a CLI command that hasn't been approved yet, the terminal sandbox will display a permission prompt and freeze the background execution indefinitely. Warming up the sandbox approvals in the foreground main thread resolves this lock.
* **Alternatives Considered**:
  - *No Warm-up*: Let subagents trigger approval prompts (Rejected: leads to silent background deadlocks).
  - *Auto-granting permissions*: Bypass sandbox (Rejected: breaks sandbox security rules).

---

## Decision 2: Subagents Done-Polling Loop

* **Decision**: Implement a 30-second schedule-based polling loop utilizing `manage_subagents list` with a maximum overall timeout of 5 minutes (300 seconds).
* **Rationale**: Polling every 30 seconds strikes a balance between low resource overhead and timely detection. The 5-minute timeout prevents the orchestrator from running infinitely in the event of an unhandled exception or crash inside one of the subagents.
* **Alternatives Considered**:
  - *Short Polling Interval (e.g., 5s)*: Rejected due to CPU spikes caused by rapid subprocess generation.
  - *Infinite Polling*: Rejected due to zombie process and resource leak risks if a subagent hangs.

---

## Decision 3: Local LLM Exclusion from Fallback Chain

* **Decision**: Dynamically detect the active running host CLI (LOCAL) and exclude it from the fallback chain (`claude` ➡️ `agy` ➡️ `openai`).
* **Rationale**: Prevents redundant reviews. If the orchestrator is already running on the `claude` host CLI, there is no value in dispatching another review subagent using `claude` CLI.
* **Alternatives Considered**:
  - *Static Fallback Chain*: Rejected because it leads to duplicate executions depending on which CLI initiated the orchestrator.

---

## Decision 4: Severity-Gated Findings Hybrid Merging

* **Decision**: Critical/High findings are merged via **Union** logic. Medium/Low findings are merged via **Intersection** logic.
* **Rationale**:
  - Critical/High issues (security vulnerabilities, major bugs) must not be missed under any circumstances, so we collect everything found by any reviewer.
  - Medium/Low issues (style details, minor refactoring) tend to generate a high volume of false positives. Restricting them to only items flagged by both reviewers ensures high confidence and reduces developer fatigue.
* **Alternatives Considered**:
  - *Pure Union*: Rejected due to high noise level from minor/low-confidence issues.
  - *Pure Intersection*: Rejected due to high risk of missing severe issues only flagged by one model.

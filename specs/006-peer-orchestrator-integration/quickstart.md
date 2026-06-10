# Quickstart & Verification Guide: Peer Orchestrator

This document outlines scenarios and setup commands to run end-to-end verification of the Peer Orchestrator system.

---

## 1. Prerequisites

1. Ensure the terminal sandbox configuration allows tool execution.
2. Verify `gh` and `git` are installed on the CLI search path.
3. Configure target review files (any pending changes in git diff).

---

## 2. Test Setup & Scenarios

### Scenario 1: Proactive Sandbox Warm-up Verification

* **Objective**: Confirm the orchestrator runs `--version` calls prior to background invocations.
* **Execution**:
  1. Modify a dummy file to create a git diff.
  2. Run the orchestrator skill: `/llm:peer-orchestrator`
* **Expected Output**:
  - Main thread stdout logs indicate `Warming up sandbox for [peer_cli]...`
  - Version command approvals are successfully captured.

---

### Scenario 2: Dynamic LOCAL Host Exclusion

* **Objective**: Ensure the active running CLI is bypassed in the fallback chain.
* **Execution**:
  1. Set environment variable `LOCAL_CLI=claude`.
  2. Execute `/llm:peer-orchestrator`.
* **Expected Output**:
  - Logs show `Excluding host CLI: claude`.
  - Fallback priority chain becomes `agy` ➡️ `openai`.

---

### Scenario 3: Severity-Gated Findings Hybrid Merge

* **Objective**: Confirm `Critical/High` findings are combined, while `Medium/Low` findings are intersected.
* **Mock Inputs**:
  * **Self Reviewer Findings**:
    - Finding 1: `High` severity (Issue A)
    - Finding 2: `Low` severity (Issue B)
  * **Peer Reviewer Findings**:
    - Finding 3: `High` severity (Issue C)
    - Finding 4: `Low` severity (Issue B)
* **Execution**:
  1. Run mock review pipeline.
* **Expected Output**:
  - The final report contains **Issue A (High)**, **Issue C (High)**, and **Issue B (Low)**.
  - Non-overlapping low-severity issues are filtered out.

---

## 3. Execution Command Reference

```bash
# Run local mock test of the orchestrator pipeline
./scripts/test-peer-orchestrator.sh --mock-sentinel CLI_NOT_FOUND
```

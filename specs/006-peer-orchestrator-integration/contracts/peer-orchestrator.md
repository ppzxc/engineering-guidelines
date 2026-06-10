# Interface Contract: Peer Orchestrator

This document defines the input arguments, tool-call structure, and expected output format for the `/llm:peer-orchestrator` skill.

---

## 1. Input Contract

### 1.1. Skill Invocation Arguments

The orchestrator skill accepts configuration variables passed via global prompt arguments or environment overrides:

* **Arguments Format**:
  ```text
  /llm:peer-orchestrator [options]
  ```
* **Supported Variables**:
  * `LOCAL_CLI`: Name of the host CLI execution environment (e.g., `claude` or `agy`). Used for dynamic exclusion.
  * `FALLBACK_LIST`: Commas-separated list overriding the fallback chain (e.g., `claude,agy,openai`).

---

## 2. Tool-Call Contracts

### 2.1. Sandbox Warm-Up Command

* **Format**:
  ```bash
  timeout 3 <peer_cli> --version
  ```
* **Expected Result**:
  * Exit code `0` and version string in stdout.
  * Captures permission approval from the sandbox manager.

---

### 2.2. Subagent Dispatch Call

The orchestrator calls the system subagent dispatcher.

* **Tool**: `invoke_subagent`
* **JSON Schema**:
  ```json
  {
    "Subagents": [
      {
        "TypeName": "self",
        "Role": "Self-Review Coordinator",
        "Prompt": "Perform local static analysis and self-review of current diffs."
      },
      {
        "TypeName": "research",
        "Role": "Peer-Review Coordinator",
        "Prompt": "Execute external code review using configured peer LLM CLI."
      }
    ]
  }
  ```

---

## 3. Output Contract

### 3.1. Merge Engine Output Structure

The orchestrator aggregates individual subagent JSON reports containing findings arrays:

* **Input JSON format from subagent (Self / Peer)**:
  ```json
  {
    "findings": [
      {
        "file": "src/utils.py",
        "line": 42,
        "severity": "High",
        "message": "Potential SQL injection vulnerability."
      }
    ]
  }
  ```

* **Merged Markdown Output Structure**:
  The final output is rendered as a clean, unified code review markdown report:

  ```markdown
  # Multi-LLM Code Review Findings
  
  ## Critical & High Severity Findings (Union)
  - **[High]** `src/utils.py` (Line 42): Potential SQL injection vulnerability.
  
  ## Medium & Low Severity Findings (Intersection)
  - **[Medium]** `src/helper.py` (Line 12): Unused imports.
  ```

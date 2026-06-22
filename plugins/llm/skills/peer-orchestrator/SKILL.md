---
name: llm:peer-orchestrator
description: Centralized multi-LLM review/cross-check orchestration

---

# llm:peer-orchestrator

This skill orchestrates multiple LLM subagents to perform parallel code reviews, implements resilient fallback recovery using sentinel signals, and merges results using a severity-gated hybrid engine.

## Warm-up & Pre-flight Checklist

To prevent sandbox permission prompts from locking background subagents during execution, the main thread MUST run version queries synchronously for all CLIs in the fallback chain:

```bash
timeout 3 <cli> --version
```

- Target CLIs: `claude`, `agy`, `openai`.
- If a command fails or times out, it is treated as a sentinel error.

## Host Exclusion Rule

Before executing any review, the orchestrator MUST detect the active running host CLI (referred to as `LOCAL_CLI` or dynamically queried) and exclude it from the fallback chain.
- Priority-ordered fallback chain: `claude` ➡️ `agy` ➡️ `openai`.
- Example: If `LOCAL_CLI` is `claude`, the remaining fallback chain sequence becomes `agy` ➡️ `openai`.

## Parallel Subagent Invocations

The orchestrator MUST dispatch both **Self-Review** and **Peer-Review** coordinator subagents concurrently using the `invoke_subagent` tool:

- **Self-Review subagent**:
  - `TypeName`: `self`
  - `Role`: `Self-Review Coordinator`
  - `Prompt`: "Perform local static analysis and self-review of current diffs."
- **Peer-Review subagent**:
  - `TypeName`: `research`
  - `Role`: `Peer-Review Coordinator`
  - `Prompt`: "Execute external code review using configured peer LLM CLI."

### Done-Polling Loop

Once subagents are invoked, the orchestrator MUST run a 30-second schedule-based polling loop to check their status:
- Tool to use: `manage_subagents list`
- Exit loop when both subagents are `Done`.

## Sentinel Fallback Engine

When executing peer CLIs, the system MUST parse the following sentinel states:
- `CLI_NOT_FOUND`: The binary is missing from the system path.
- `CLI_TIMEOUT`: CLI execution times out (e.g., version check takes >3 seconds).
- `CLI_ERROR`: Non-zero exit code during execution.

If any sentinel state is detected, the orchestrator MUST transition immediately to the next available peer CLI in the fallback queue. If all peers fail, abort gracefully.

## Severity-Gated Hybrid Merge Engine

Findings from the Self and Peer reviewers are merged based on severity:
- **Critical & High Severity Findings**: Apply **Union** logic (collect all findings flagged by either reviewer).
- **Medium & Low Severity Findings**: Apply **Intersection** logic (collect only findings that are flagged by BOTH reviewers to reduce noise).

The merged findings are outputted as a clean markdown report.

